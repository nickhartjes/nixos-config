# n100-nanoclaw Phase B1: bootstrap nanoclaw and settle the MCP mechanism

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Get nanoclaw running on `n100-nanoclaw` under systemd, paired to Telegram, and settle by experiment whether a group-folder `.mcp.json` is read — the question that decides how the three MCP servers get wired.

**Architecture:** A mutable git checkout at `/home/nh/nanoclaw` owned by `nh`, started by a NixOS-declared systemd unit, reading its Telegram token from an agenix `EnvironmentFile`. NixOS owns the platform; the checkout stays imperative because upstream's model is "customization = code changes".

**Tech Stack:** nanoclaw (Node 22 + pnpm host process, Bun in-container), Docker, Claude Agent SDK, agenix, systemd.

**Spec:** `docs/superpowers/specs/2026-08-24-n100-nanoclaw-design.md`
**Findings authority:** `docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md`

**Scope:** B1 only — bootstrap plus the MCP experiment. **B2** (wiring Strava/Hevy/Google-Health, the credentials volume, the vault sync wrapper, backups) is deliberately unwritten: its shape depends on Task 4's answer.

## Global Constraints

- Host `n100-nanoclaw`, `nh@10.0.60.51`, tailnet `100.101.27.10`. Repo `/home/nh/.config/nixos-config`.
- Checkout at `/home/nh/nanoclaw`, owned by `nh`. Never run nanoclaw as root.
- Telegram token is already in agenix at `/run/agenix/n100-nanoclaw/telegram-bot-token.env` (`TELEGRAM_BOT_TOKEN=`, 66 bytes, root:400).
- Hevy key at `/home/nh/.config/hevy-mcp.env` (`export HEVY_API_KEY=`, symlink into `/run/agenix.d/`).
- Obsidian deploy key at `/home/nh/.ssh/id_obsidian`, verified working against `git@github.com:nickhartjes/obsidian.git`.
- Auth to Anthropic is **Claude subscription OAuth**, not an API key. `claude login` is interactive and its credentials live in `~/.claude` on the host.
- Container facts, established and not to be re-litigated: mount paths are forced under `/workspace/extra/…`; there is **no** per-group env mechanism (per-MCP-server `env` only, capped 32); container `$HOME` is `/home/node`; a `mount-allowlist.json` is mandatory or every additional mount is rejected.
- Remote sudo on this host **requires a password** by design. Any step needing it is interactive.
- `nix` cannot see untracked files — `git add` new `.nix` files before building.

---

### Task 1: Correct the residual `.mcp.json` claim in the spec

The MCP wiring section was corrected, but the architecture diagram above it still draws `.mcp.json` as the settled mechanism. That contradiction sits at the top of the document B2 will be designed from.

**Files:**
- Modify: `docs/superpowers/specs/2026-08-24-n100-nanoclaw-design.md` (the `## Architecture` fenced diagram)

- [ ] **Step 1: Confirm the contradiction**

```bash
cd /home/nh/.config/nixos-config
command sed -n '/^## Architecture/,/^## Changes/p' docs/superpowers/specs/2026-08-24-n100-nanoclaw-design.md
```

Expected: the diagram's branch line reads `├─ .mcp.json  ──►  strava …`, asserting a mechanism the same document elsewhere marks UNRESOLVED.

- [ ] **Step 2: Replace the branch line so the diagram matches the findings**

Change the MCP branch of the diagram to name both candidate channels and mark the choice open, e.g.:

```
              agent container (Docker, per agent group)
                      │   $HOME=/home/node
                      ├─ MCP config: container.json `mcpServers`,
                      │   or a group-folder .mcp.json via the SDK's
                      │   settingSources — UNRESOLVED, see findings doc
                      │     strava (http, OAuth)
                      │     hevy (stdio, API key)
                      │     google-health (stdio, OAuth)
                      └─ mounts: forced under /workspace/extra/…
```

Keep the rest of the diagram as-is.

- [ ] **Step 3: Check no other part of the spec still asserts it**

```bash
command grep -n "\.mcp\.json" docs/superpowers/specs/2026-08-24-n100-nanoclaw-design.md
```

Every hit must either be marked UNRESOLVED or be describing the vault's own file. Fix any that assert it works.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-08-24-n100-nanoclaw-design.md
git commit -m "docs(n100-nanoclaw): stop the architecture diagram asserting .mcp.json"
```

---

### Task 2: Fork upstream and clone to the host

Upstream's model is that you fork and edit your fork; channels are not in trunk and arrive by copying from a `channels` branch. A fork is therefore a prerequisite, not a preference.

**Files:** none in this repo. Creates `/home/nh/nanoclaw` on the host.

**Interfaces:**
- Produces: a working checkout at `/home/nh/nanoclaw` with dependencies installed, and the exact upstream commit recorded.

- [ ] **Step 1: Create the fork** (needs the human — it writes to their GitHub account)

```bash
gh repo fork nanocoai/nanoclaw --clone=false --remote=false
```

Confirm: `gh repo view nickhartjes/nanoclaw --json name,parent`

- [ ] **Step 2: Clone it on the host over SSH, using the deploy-key-free default identity**

```bash
ssh nh@10.0.60.51 'git clone https://github.com/nickhartjes/nanoclaw.git /home/nh/nanoclaw && git -C /home/nh/nanoclaw log --oneline -1'
```

HTTPS on purpose: `/home/nh/.ssh/id_obsidian` is scoped to the obsidian repo as a deploy key and must not be offered to other repos.

- [ ] **Step 3: Record the upstream commit and add the upstream remote**

```bash
ssh nh@10.0.60.51 'cd /home/nh/nanoclaw && git remote add upstream https://github.com/nanocoai/nanoclaw.git && git log --oneline -1 && git rev-parse HEAD'
```

Record that SHA in the report — the findings doc was written against `ad8837c`, and a drift means its citations need re-checking.

- [ ] **Step 4: Verify the toolchain the host already provides**

```bash
ssh nh@10.0.60.51 'node --version; pnpm --version; bun --version; docker info --format "{{.ServerVersion}}"'
```

Expected: v22.23.2, 11.21.0, 1.3.13, and a Docker version. All are already in the system closure — do NOT install anything with npm/corepack.

---

### Task 3: Bootstrap nanoclaw (interactive)

`bash nanoclaw.sh` walks from a fresh machine to a paired agent. It is interactive and this box is headless, so the human drives it. **This task discovers facts the plan cannot state in advance** — the start command, the group directory layout, and where credentials land. Record them; Task 5 and all of B2 depend on them.

**Interfaces:**
- Produces: a paired Telegram agent, an authenticated Claude subscription session, and a written record of (a) the exact command that starts the host process, (b) the group folder path, (c) the path holding Claude credentials, (d) the container image name.

- [ ] **Step 1: Authenticate Claude Code on the host**

OAuth needs a browser callback, and the box is headless. Forward the callback port from framework-13:

```bash
ssh -L 8765:localhost:8765 nh@10.0.60.51
# then, in that session:
claude login
```

Open the printed URL in the framework-13 browser. If `claude` uses a different callback port, read it from the URL and re-forward that port instead.

- [ ] **Step 2: Run the installer**

```bash
ssh -t nh@10.0.60.51 'cd /home/nh/nanoclaw && bash nanoclaw.sh'
```

Choose Telegram as the channel. When it asks for the bot token, supply it from agenix without echoing it:

```bash
sudo cat /run/agenix/n100-nanoclaw/telegram-bot-token.env
```

(That needs the console password; this host requires it by design.)

If a step fails, upstream hands control to Claude Code to resume — that is expected behaviour, not a defect.

- [ ] **Step 3: Send a message from Telegram and confirm a reply**

The end-to-end proof that the router, the container, and the Claude session all work. Record what you sent and what came back.

- [ ] **Step 4: Write down the four discovered facts**

Record in the report, with the evidence for each:
- the exact command/entrypoint that starts the host process (needed for Task 5's `ExecStart`)
- the group folder path for the agent that was created
- where Claude credentials were written (candidate: `/home/nh/.claude`)
- the agent container image name (`docker image ls`)

- [ ] **Step 5: Confirm the checkout stayed out of the Nix store**

```bash
ssh nh@10.0.60.51 'stat -c "%U:%G %a" /home/nh/nanoclaw; git -C /home/nh/nanoclaw status --short | head'
```

Expected: owned by `nh:users`. Uncommitted changes are normal — the installer edits the tree.

---

### Task 4: Settle the `.mcp.json` question by experiment

The one question the source could not answer. The SDK is invoked with `settingSources: ['project','user','local']` and `cwd=/workspace/agent` (`claude.ts:574`, `index.ts:46`), which *may* make the SDK read a project `.mcp.json` independently of the `mcpServers` object nanoclaw passes — but the deciding read logic lives in a compiled binary.

**Interfaces:**
- Produces: a definitive answer, appended to the findings doc, that determines B2's entire MCP design.

- [ ] **Step 1: Pick a server that is unambiguous when present**

Use a stdio server that needs no credentials and no network, so a positive result cannot be confused with an auth or egress failure. For example a trivial local echo/filesystem server, or `hevy` (which will fail to authenticate but whose *tools appearing at all* proves the config was read).

Prefer the credential-free option: the signal is "do the tools exist", not "do they work".

- [ ] **Step 2: Place `.mcp.json` in the group folder discovered in Task 3**

```json
{
  "mcpServers": {
    "probe": { "type": "stdio", "command": "echo", "args": ["probe"] }
  }
}
```

- [ ] **Step 3: Restart nanoclaw and ask the agent what MCP tools it has**

Over Telegram, ask it to list its available MCP servers/tools. Also check the container logs for any mention of `probe` or of loading project settings.

- [ ] **Step 4: Record the verdict with evidence**

Append to `docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md`, replacing answer (d)'s `UNRESOLVED` with the experimental result. State the observation that decided it, not an inference. If the result is ambiguous, say so and describe the next discriminating test — do not resolve it on a hunch. This document has already been wrong once by over-confidence.

- [ ] **Step 5: Remove the probe and commit the findings update**

```bash
git add docs/superpowers/specs/2026-08-24-nanoclaw-container-findings.md
git commit -m "docs(nanoclaw): settle the .mcp.json question by experiment"
```

---

### Task 5: Declare the systemd unit

Only now, with the real start command known from Task 3.

**Files:**
- Create: `hosts/n100-nanoclaw/services/nanoclaw.nix`
- Create: `hosts/n100-nanoclaw/services/default.nix`
- Modify: `hosts/n100-nanoclaw/default.nix` (add `./services` to imports)

- [ ] **Step 1: Write `services/default.nix`**

```nix
{
  imports = [
    ./nanoclaw.nix
  ];
}
```

- [ ] **Step 2: Write `services/nanoclaw.nix`**

Substitute `<START-COMMAND>` with the entrypoint recorded in Task 3 Step 4 — do not guess it.

```nix
{
  config,
  pkgs,
  lib,
  ...
}: {
  systemd.services.nanoclaw = {
    description = "nanoclaw agent router";
    after = ["docker.service" "network-online.target"];
    wants = ["network-online.target"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];

    # Sits inert rather than crash-looping if the checkout is absent.
    unitConfig.ConditionPathExists = "/home/nh/nanoclaw/package.json";

    serviceConfig = {
      Type = "simple";
      User = "nh";
      WorkingDirectory = "/home/nh/nanoclaw";
      # Docker socket access is root-equivalent; this is why the service runs
      # as nh rather than a dedicated UID (see the spec's rationale).
      SupplementaryGroups = ["docker"];
      EnvironmentFile = config.age.secrets."n100-nanoclaw/telegram-bot-token.env".path;
      Restart = "on-failure";
      RestartSec = "10s";
    };

    path = with pkgs; [nodejs_22 pnpm bun docker git];

    script = "<START-COMMAND>";
  };
}
```

- [ ] **Step 3: Import it, stage, build**

```bash
cd /home/nh/.config/nixos-config
# add ./services to hosts/n100-nanoclaw/default.nix imports
git add hosts/n100-nanoclaw
just build n100-nanoclaw
```

Expected: PASS.

- [ ] **Step 4: Deploy (interactive — remote sudo needs a password)**

```bash
just deploy n100-nanoclaw
```

- [ ] **Step 5: Verify the unit runs and survives a restart**

```bash
ssh nh@10.0.60.51 'systemctl status nanoclaw --no-pager | head -15'
ssh -t nh@10.0.60.51 'sudo systemctl restart nanoclaw' && sleep 10
ssh nh@10.0.60.51 'systemctl is-active nanoclaw; journalctl -u nanoclaw -n 20 --no-pager'
```

Then send one more Telegram message and confirm a reply — proving the unit, not just a hand-started process, serves traffic.

- [ ] **Step 6: Commit**

```bash
git add hosts/n100-nanoclaw
git commit -m "feat(n100-nanoclaw): declare the nanoclaw systemd unit"
```

---

## Out of scope (deferred to B2)

- Wiring Strava, Hevy and Google Health, including the `/workspace/extra/` mount for the hevy env file and the `mount-allowlist.json` that mounts require
- The persistent credentials volume for OAuth tokens
- The Obsidian vault sync wrapper (commit → pull --rebase --autostash → update → commit → push; conflict reports over Telegram; never force-push)
- Backups of the credentials volume and nanoclaw's SQLite state
- Baking the MCP npm packages into the agent image

## Risks

1. **Task 3 is irreducibly interactive.** OAuth via port-forward on a headless box is the fiddliest step in the whole project. If `claude login` cannot complete, everything downstream stalls, and the fallback is switching to an API key — which the spec explicitly decided against.
2. **The upstream commit may have drifted** from the `ad8837c` the findings doc was written against. Task 2 Step 3 records the SHA precisely so citations can be re-checked.
3. **The installer mutates the checkout**, so the fork will diverge from upstream immediately. That is upstream's intended model, but it means `git pull upstream main` will conflict later.
4. **A subscription seat driving an always-on agent** will hit session rate limits harder than metered API use. Accepted deliberately in the spec.
