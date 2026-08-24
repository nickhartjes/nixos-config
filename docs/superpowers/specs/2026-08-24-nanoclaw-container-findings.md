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

**Partially supported, and not at the granularity the brief assumed.** There
is **no** generic, container-wide, operator-settable "additional env" key on
`ContainerConfig` (`src/container-config.ts:239-255` — the only fields are
`mcpServers`, `packages`, `imageTag`, `additionalMounts`, `skills`, `provider`,
`groupName`, `assistantName`, `agentGroupId`, `maxMessagesPerPrompt`, `model`,
`effort`, `timezone`, `runtimeTier`). Grepping upstream for any
`additionalEnv`/`extraEnv`/`envVars`/"config set-env"-style key turns up
nothing (checked `src/` and `container/agent-runner/src/`).

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

**Not read.** No such runtime mechanism exists. Two unrelated things carry
similar names, and conflating them was the likely source of the brief's
"inferred, not verified" assumption:

1. **`mcp.json` (no leading dot) is read, but only from a *plugin* directory
   at template-stamp time**, not from the group folder at container spawn
   time. `readPluginMcp()` (`src/templates/mcp.ts:48-97`) explicitly checks
   for a legacy `.mcp.json` (with the dot) and — rather than reading it —
   **ignores it and reports it as a lint warning**: `".mcp.json: ignored
   (legacy name); rename it to mcp.json"` (`src/templates/mcp.ts:52-54`,
   confirmed by the test at `src/templates/parse.test.ts:361-368`). This
   machinery belongs to the "Agent Plugins" template/stamping system
   (plugin authors ship an `mcp.json` that gets folded into the DB
   `mcp_servers` column once, when a template is applied via
   `ncl groups create --template`) — it has nothing to do with what the
   running agent reads on every spawn.
2. **The actual runtime source of truth is `groups/<folder>/container.json`**
   (materialized from the DB by `materializeContainerJson()`,
   `src/container-config.ts:358-373`), bind-mounted **read-only** into the
   container at `/workspace/agent/container.json`
   (`src/container-runner.ts:503-516`). Inside the container,
   `container/agent-runner/src/config.ts:12,33-49` reads exactly that path
   and exposes its `mcpServers` field. That field is then passed **directly**
   into the Claude Agent SDK's own `mcpServers` option in-process
   (`container/agent-runner/src/providers/claude.ts:482,491-492,575`) — the
   SDK never reads a `.mcp.json` project file off disk for this; nanoclaw
   hands it the parsed object.

**Bottom line: there is no `.mcp.json` (dotted or not) in the group folder
that the in-container agent reads for its three MCP servers.** The three
servers belong in `container.json`'s `mcpServers` map, populated via
`ncl groups config add-mcp-server` (see (b) above) or via the plugin-stamping
path in (d.1) if they should ship as part of a reusable template.

---

## Summary table

| Question | Answer | Key citation |
|---|---|---|
| (a) bind mounts | `additionalMounts` array on `ContainerConfig`; **container path always forced under `/workspace/extra/`**, host path must pre-exist and match an allowlist root | `src/modules/mount-security/index.ts:276-438`, `src/cli/resources/groups.ts:555-606` |
| (b) env vars | No generic per-group env key; only `mcpServers.<name>.env`, scoped to that one server, capped at 32 entries | `src/container-config.ts:28-33,239-255`, `src/cli/resources/groups.ts:423-458`, `src/modules/self-mod/request.ts:79` |
| (c) `$HOME` | `/home/node` — image default (`USER node` in `node:22-slim`) and explicit override on uid-mapped runs | `container/Dockerfile:13,128,134`, `src/container-runner.ts:686-700` |
| (d) `.mcp.json` in group folder | Not read by the runtime agent at all. Runtime source is `container.json`'s `mcpServers`, mounted at `/workspace/agent/container.json`. A dotted `.mcp.json` is explicitly ignored, and only in an unrelated plugin-template directory, not the group folder | `src/templates/mcp.ts:48-97`, `src/container-config.ts:358-373`, `src/container-runner.ts:503-516`, `container/agent-runner/src/config.ts:12,33-49` |

**Net effect on Phase B:** (b) and (d) as originally assumed are wrong and
must be redesigned — there is no per-group `.mcp.json` file, and env
injection is per-MCP-server, not per-group. (a) is real but does not support
mounting at an arbitrary absolute container path (it always lands under
`/workspace/extra/`), which matters if the design insists on the literal path
`~/.config/hevy-mcp.env`. None of the four answers required patching the
fork's container-spawn code to *learn* the facts — but (a)'s path-prefixing
and (b)'s per-server-only scoping mean Phase B's original plan (a bind-mounted
env file at a literal home-relative path, plus three MCP servers via a
`.mcp.json`) cannot be realized unmodified through upstream's supported
surface, and should either target the supported shapes above (relative
`/workspace/extra/...` mount, per-server `env`, `container.json`'s
`mcpServers`) or fall back to patching the fork's container-spawn code as the
brief anticipated.
