# nanoclaw container-config findings (verified against upstream source)

**Purpose:** Phase B's MCP design assumed (a) per-group bind mounts, (b) per-group
env var injection, (c) a known `$HOME` inside the agent container, and (d) a
per-group `.mcp.json` file read by the in-container agent, are all supported by
upstream nanoclaw. This document verifies each claim against the actual
upstream source, with file/line citations. No host changes were made; this is
a read-only investigation.

**Upstream commit investigated:** `ad8837c835527ffbc22878a4d1a897b66b199028`
(https://github.com/nanocoai/nanoclaw), committed **2026-08-24T01:01:56+03:00**.
Cloned shallow (`--depth 1`) to a scratch directory outside this repo; nothing
from the clone is committed here. Re-run the greps below against a fresh clone
before relying on this document if upstream has moved since that date.

---

## (a) Per-group bind mounts: supported config key

**Evidence basis: enforced by code.** The forced `/workspace/extra/` prefix
is not a convention that a differently-configured mount could route around —
`isValidContainerPath()` rejects any absolute or `..`-containing path before
the mount is ever composed, and `validateAdditionalMounts()` is the only
place `additionalMounts` entries reach the driver, so this is a hard
constraint, not something merely unexercised in the code I read.

**Supported.** The config key is `additionalMounts` (an array of
`{ hostPath: string; containerPath: string; readonly?: boolean }`), stored in
the DB `container_configs.additional_mounts` column (JSON) and materialized
into `groups/<folder>/container.json` by `materializeContainerJson()`
(`src/container-config.ts:358-373`, field defined at `src/container-config.ts:232-236,243`).

Operator-facing CLI:

```
ncl groups config add-mount --id <group-id> --host <host-path> --container <container-path> [--ro]
ncl groups config remove-mount --id <group-id> --host <host-path> --container <container-path>
```

(`src/cli/resources/groups.ts:555-606`). Both are `hostOnly: true` (cannot be
invoked from inside a container) and require `ncl groups restart` to take
effect.

**Two load-bearing constraints, easy to miss:**

1. **The container path is never honored literally.** `additionalMounts`
   entries are re-validated at every container spawn by
   `validateAdditionalMounts()` (`src/modules/mount-security/index.ts:396-438`),
   which calls `validateMount()`. That function requires `containerPath` to be
   **relative** (`isValidContainerPath`, `src/modules/mount-security/index.ts:276-298`
   — rejects a leading `/`, `..`, or `:`), and the accepted mount is always
   rewritten to land at `` `/workspace/extra/${resolvedContainerPath}` ``
   (`src/modules/mount-security/index.ts:416`). **There is no way to bind-mount
   an `additionalMounts` entry at an arbitrary absolute container path such as
   `/home/node/.config/hevy-mcp.env` — it will always be forced under
   `/workspace/extra/...`.** If Phase B needs the file at that literal path
   inside the container, upstream's `additionalMounts` mechanism does not
   deliver it as-is; either point the consuming tool at
   `/workspace/extra/hevy-mcp.env` instead, or patch container-spawn code.
2. **The host source must already exist**, and un-allowlisted or
   nonexistent paths are silently dropped (logged, not thrown) by
   `validateAdditionalMounts` before ever reaching the driver
   (`src/modules/mount-security/index.ts:427-434`); if **no** allowlist file
   exists at `~/.config/nanoclaw/mount-allowlist.json` at all, **every**
   additional mount is rejected (`src/modules/mount-security/index.ts:316-321`).
   The host path must also sit under an `allowedRoots` entry in that allowlist
   file, and RW is only granted if both the request and the allowed root's
   `allowReadWrite` agree (`src/modules/mount-security/index.ts:365-380`).
   Separately, the low-level Docker driver also asserts mount sources exist at
   spawn time (`assertMountSourcesExist`, `src/drivers/docker-driver.ts:693-700`),
   but by the time a mount reaches the driver it has already passed the
   allowlist check above.

Note: this is orthogonal to the always-present, non-configurable group-state
mount `groups/<folder>/` → `/workspace/agent` (RW, no allowlist involved,
`src/container-runner.ts:494-501`). A persistent, restart-surviving directory
that does **not** need to satisfy the `/workspace/extra/` prefix or the
allowlist can simply be a subdirectory the host creates under
`groups/<folder>/` — it rides the mount every group already gets for free.

## (b) Per-group env vars: supported config key

**Evidence basis: mixed.** The absence of a generic per-group env key is
**enforced by code** for the piece that matters most: `ContainerConfig` is a
TypeScript interface with an exhaustive, explicitly-named field list
(`src/container-config.ts:239-255` — `mcpServers`, `packages`, `imageTag`,
`additionalMounts`, `skills`, `provider`, `groupName`, `assistantName`,
`agentGroupId`, `maxMessagesPerPrompt`, `model`, `effort`, `timezone`,
`runtimeTier`); anything not in that list cannot survive
`configFromDb()`/`materializeContainerJson()` round-tripping, so this is not
just "I didn't find one," it's "the type does not have room for one." The
per-server `env` field's existence and its 32-entry cap are likewise
enforced-by-code reads (`src/container-config.ts:28-33`,
`src/modules/self-mod/request.ts:79,174-175`).

The one thing this section does **not** rule out (evidence basis:
not-settled-from-source, same gap as (d)): whether the SDK's `settingSources`
mechanism gives the agent process a *second*, SDK-level way to pick up
project-scoped environment values (e.g. via a `.claude/settings.json` at
`/workspace/agent` under `settingSources: ['project']`) independent of
anything `ContainerConfig` models. I did not find evidence of this for env
specifically (unlike `.mcp.json`, no string literal in the SDK bundle names
an env-from-settings-file mechanism), but the search that produced "no
generic env key" was scoped to nanoclaw's own repository plus a targeted grep
of the SDK bundle for MCP-adjacent strings — it was not an exhaustive read of
the SDK/CLI's settings-file schema, so a project-level env mechanism there
cannot be fully ruled out on this evidence.

Confirming the negative claim above: grepping upstream nanoclaw for any
`additionalEnv`/`extraEnv`/`envVars`/"config set-env"-style key turns up
nothing (checked `src/` and `container/agent-runner/src/`) — this covers
nanoclaw's own code, not the vendored SDK/CLI.

The only per-group, operator-configurable env-injection surface is **scoped to
one MCP server's own process**: `McpStdioServerConfig.env?: Record<string,
string>` (`src/container-config.ts:28-33`), settable via:

```
ncl groups config add-mcp-server --id <group-id> --name <server-name> \
  --command <cmd> [--args <json-array>] [--env <json-object>]
```

(`src/cli/resources/groups.ts:423-458`). This env is capped at 32 entries per
server (`MAX_MCP_ENV_VARS = 32`, `src/modules/self-mod/request.ts:79,174-175`
— that cap is enforced on the in-container self-mod `add_mcp_server` tool path;
the host CLI path above does not re-check it, per the code read).
`composeSessionSpec()` separately builds a container-wide `env` object
(`TZ`, mailbox environment) and a `contributedEnv` lane (provider/gateway
contributions, `src/container-runner.ts:672-713`), but neither is an
operator-facing per-group config key — both are computed by nanoclaw itself.

**Implication for Phase B:** an API key like `HEVY_API_KEY` can be delivered
directly as `--env '{"HEVY_API_KEY":"..."}'` on `config add-mcp-server`,
landing in `container.json`'s `mcpServers.hevy.env` and then in that one
server subprocess's environment — with no bind-mounted env file needed at
all. If the design intentionally wants the key off of the DB/`container.json`
(which is world-readable-ish inside the group folder) and in a file instead,
that still routes through the `additionalMounts` `/workspace/extra/` prefix
described in (a), not a literal `~/.config/hevy-mcp.env` path.

## (c) Agent container's `$HOME`

**Evidence basis: enforced by code**, on two independent, corroborating
paths — one baked into the image build (not reachable from JS config at
all), one explicit in the composer:

**Resolves to `/home/node`,** by two independent, corroborating mechanisms:

1. **Image default.** `container/Dockerfile` is `FROM node:22-slim` (line 13),
   runs `chmod 777 /home/node` (line 128) and ends with `USER node` (line 134).
   The official `node` Docker images' built-in `node` user has `/home/node` as
   its passwd home directory, so any container that runs as that baked-in user
   gets `$HOME=/home/node` from `/etc/passwd` with no explicit override needed.
2. **Explicit override on host-uid mapping.** `composeSessionSpec()` computes
   `runAs` from the host's own uid/gid (`hostUid = process.getuid?.()`,
   `src/container-runner.ts:686`) and, whenever a non-null, non-zero host uid
   is used to run the container (`runAs` set, `src/container-runner.ts:699`),
   explicitly sets `env.HOME = '/home/node'` (`src/container-runner.ts:700`).
   The surrounding comment explains why: an arbitrary mapped uid has no
   passwd entry inside the container, so `$HOME` would otherwise resolve to
   `/` and break `~/.claude`-relative paths the provider SDK writes to.

Both paths converge on the same value, so `/home/node` is safe to treat as
the agent container's `$HOME` regardless of which code path is active.

## (d) `.mcp.json` in the group folder, read by the in-container agent

**UNRESOLVED.** The first draft of this document claimed "not read, period."
That claim was wrong to state without a hedge: it was reached by searching
only nanoclaw's own repository, and it overlooked a second, independent
loading path inside the vendored Claude Agent SDK that nanoclaw itself wires
up and does not disable. Corrected below, split into what nanoclaw's own code
does (settled) and what the SDK/CLI does with what nanoclaw hands it
(not settled from source available to this task).

**Settled — nanoclaw's own explicit wiring (evidence basis: enforced by code,
read directly):**

`groups/<folder>/container.json` is nanoclaw's own materialized config
(`materializeContainerJson()`, `src/container-config.ts:358-373`), mounted
read-only at `/workspace/agent/container.json`
(`src/container-runner.ts:503-516`). `container/agent-runner/src/config.ts:12,33-49`
reads exactly that path and exposes its `mcpServers` field, which
`container/agent-runner/src/providers/claude.ts:482,491-492` passes into the
SDK's own `mcpServers` query option. This channel is real and does not
involve any file named `.mcp.json`.

**Not settled — a second, independent channel the SDK call also opens
(evidence basis: real but not fully investigated; found in the SDK's
published source, not nanoclaw's repo, and not run):**

The same `query()` call also passes `settingSources: ['project', 'user',
'local']` and `cwd: input.cwd` to the SDK
(`container/agent-runner/src/providers/claude.ts:574` for `settingSources`,
`:559` for `cwd`), and `input.cwd` is always `/workspace/agent`
(`CWD = '/workspace/agent'`, `container/agent-runner/src/index.ts:46,125`) —
the same directory `groups/<folder>/` is mounted to. `settingSources` and
`mcpServers` are two separate options on the same call; nothing in
nanoclaw's code disables or overrides `settingSources`, and nothing here
proves it is inert.

To find out what `settingSources` actually does, I downloaded the real
published package — `npm view` shows nanoclaw pins
`@anthropic-ai/claude-agent-sdk@^0.3.238`
(`container/agent-runner/package.json:12`); I fetched the exact `0.3.238`
tarball from the npm registry and inspected its bundled `sdk.mjs` (this is
source, not documentation). That confirms:

- `settingSources` is a real, live option: the SDK translates it verbatim
  into a `--setting-sources=project,user,local`-style flag on the underlying
  CLI subprocess invocation (found in `sdk.mjs`'s option-to-argv translation).
- The bundle's own embedded schema/help strings describe `.mcp.json` and a
  per-project "approved/disabled McpJsonServers" list as a source the CLI
  treats as **independent of** the SDK's own `mcpServers` plumbing — one
  string literally reads "does not gate other MCP entry points (SDK
  setMcpServers, claude mcp add, .mcp.json)", i.e. the SDK bundle itself
  documents `.mcp.json` as a parallel, non-overlapping entry point.
- **What I could not verify:** the actual filesystem-read-and-approval logic
  for project-scoped `.mcp.json` lives in the separate compiled `claude` CLI
  binary that the SDK spawns as a subprocess (nanoclaw pins
  `pathToClaudeCodeExecutable: '/pnpm/claude'`,
  `container/agent-runner/src/providers/claude.ts:565`-adjacent options
  block) — that binary is a different package
  (`@anthropic-ai/claude-code`), was not fetched, and was not decompiled or
  run. So I cannot state whether, given nanoclaw's specific options
  (`permissionMode: 'bypassPermissions'`, `allowDangerouslySkipPermissions:
  true`, no TTY, headless container), a `.mcp.json` dropped at
  `groups/<folder>/.mcp.json` (→ `/workspace/agent/.mcp.json`) would be
  auto-approved and its servers actually surfaced to the agent, silently
  ignored pending an approval step that never fires headlessly, or something
  in between.

**Concrete experiment that would settle it** (not run as part of this
task — this is a read-only investigation): on the framework-13 nanoclaw
install, drop a minimal valid `.mcp.json` (`{"mcpServers": {"probe":
{"command": "..."}}}`) directly into an existing group's folder (host path
`groups/<folder>/.mcp.json`, which lands at `/workspace/agent/.mcp.json` in
the container — no `additionalMounts` needed, since `/workspace/agent` is
already mounted RW), restart that group's session with
`ncl groups restart --id <id>`, and check either the agent-runner startup
logs for an MCP connection attempt to `probe`, or ask the agent to list its
available tools and look for an `mcp__probe__*` entry that was never present
in that group's `container.json`. A positive result would mean Phase B can
skip `container.json`'s `mcpServers` entirely and use a plain `.mcp.json`
instead — materially simpler. A negative result (or a result gated behind an
approval prompt that never resolves headlessly) confirms the original `(d)`
conclusion holds in practice, for a different reason than first claimed.

---

## Summary table

| Question | Answer | Evidence basis | Key citation |
|---|---|---|---|
| (a) bind mounts | `additionalMounts` array on `ContainerConfig`; **container path always forced under `/workspace/extra/`**, host path must pre-exist and match an allowlist root | Enforced by code | `src/modules/mount-security/index.ts:276-438`, `src/cli/resources/groups.ts:555-606` |
| (b) env vars | No generic per-group env key on `ContainerConfig` (exhaustive type); only `mcpServers.<name>.env`, scoped to that one server, capped at 32 entries. SDK-level `settingSources` as a second env channel is not ruled out. | Enforced by code (no-generic-key claim); not-settled-from-source (whether SDK `settingSources` offers a parallel env path) | `src/container-config.ts:28-33,239-255`, `src/cli/resources/groups.ts:423-458`, `src/modules/self-mod/request.ts:79` |
| (c) `$HOME` | `/home/node` — image default (`USER node` in `node:22-slim`) and explicit override on uid-mapped runs | Enforced by code | `container/Dockerfile:13,128,134`, `src/container-runner.ts:686-700` |
| (d) `.mcp.json` in group folder | **UNRESOLVED.** Nanoclaw's own explicit channel is `container.json`'s `mcpServers`, not `.mcp.json` (enforced by code). But the same SDK call also sets `settingSources: ['project','user','local']` with `cwd=/workspace/agent`, a second, independent channel the published SDK source confirms is real and forwarded to the underlying CLI — whether it actually loads/auto-approves a `.mcp.json` dropped at `/workspace/agent/.mcp.json` in nanoclaw's headless, bypass-permissions configuration is not settled from source available to this task (the file-reading logic lives in a separate, uninspected compiled CLI binary) | Not-settled-from-source | `container/agent-runner/src/providers/claude.ts:559,574`, `container/agent-runner/src/index.ts:46,125`, `container/agent-runner/src/config.ts:12,33-49`, `src/container-config.ts:358-373`, `src/container-runner.ts:503-516`, npm-published `@anthropic-ai/claude-agent-sdk@0.3.238` `sdk.mjs` |

**Net effect on Phase B:** (a) and (b)'s no-generic-env-key finding stand as
hard constraints — bind mounts always land under `/workspace/extra/`, and
`ContainerConfig` has no room for an arbitrary per-group env var. (c) is
settled: `$HOME=/home/node`. (d) is the one open question that actually
matters most for Phase B's design, since it decides whether the three MCP
servers can ship as a plain `.mcp.json` (materially simpler) or must go
through `container.json`'s `mcpServers` (via `ncl groups config
add-mcp-server`, confirmed supported). Phase B should either run the
concrete experiment described in (d) before committing to a design, or
default to the confirmed-working `container.json` path and treat a working
`.mcp.json` as a possible future simplification rather than a load-bearing
assumption. Separately, for the Hevy API key specifically, the per-server
`mcpServers.<name>.env` field (see (b)) already solves that need directly —
no bind-mounted env file is required at all, regardless of how (d) resolves.

---

## Answer (d) — SETTLED BY EXPERIMENT, 2026-08-24

**A group-folder `.mcp.json` is NOT read.** Recorded after running the
drop-and-restart test this document previously specified.

Method: wrote `groups/ping_test/.mcp.json` declaring one stdio server named
`probeserver`, removed the existing session container, ran `ncl groups restart`,
then messaged the agent through the CLI channel and asked it to list its MCP
servers.

Result: the agent listed only `nanoclaw` (an internally injected server —
note `container.json`'s `mcpServers` is `{}`, so that one is not configured
there either). `probeserver` appeared **nowhere**: zero mentions in
`docker logs`, zero in any session transcript under
`data/v2-sessions/*/.claude-shared/projects/`.

Why this is a real negative rather than a mount problem: the whole group folder
is bind-mounted (`groups/ping_test -> /workspace/agent`), and the file was
confirmed present inside the container at `/workspace/agent/.mcp.json`,
103 bytes, before the answering container spawned. Had the SDK read it and
failed to start the server, the failure would have named it.

Residual uncertainty, stated rather than hidden: a single probe cannot
distinguish "never read" from "read, then silently discarded as invalid".
That distinction does not change the design, because the supported path is
known to work.

**Consequence for Phase B2:** configure MCP servers with
`ncl groups config add-mcp-server --id <group> --name <n>` plus either
`--command <cmd> [--args <json>] [--env <json>]` or
`--url <url> [--headers <json>]`. Do not plan around `.mcp.json`.

**Credentials for MCP servers** should use the mount-by-reference pattern
proven for the Anthropic token, not `--env` — an `--env` value lands in
`container.json`, which is tracked in the fork's git history. Mount the agenix
file and have the server's command source it. Note the mount contract learned
the hard way: `--container` takes a **relative** path, which nanoclaw prefixes
with `/workspace/extra/`; an absolute path is rejected with "must be relative,
non-empty, and not contain '..'".
