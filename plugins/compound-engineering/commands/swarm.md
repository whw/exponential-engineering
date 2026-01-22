---
name: workflows:work:swarm
description: Launch a swarm of Claude Code workers in Docker/tmux to work through beads
argument-hint: "[--workers N] [--attach]"
---

# Swarm Work Execution

Launch a swarm of Claude Code workers to implement beads collaboratively.

## Prerequisites Check

Before running the script, verify:

1. **Beads exist**: `bd --db .beads/beads.db list`
2. **Docker available**: `docker --version`
3. **Image exists**: `docker images work-host-image`

If prerequisites fail:
- No beads: "Run `/workflows:plan:beadify <plan-file>` first"
- No Docker: "Install Docker Desktop"
- No image: "Run `docker build -t work-host-image -f docker/Dockerfile.work-host .`"

## Execute

Run the swarm script from the plugin:

```bash
~/.claude/plugins/cache/*/exponential-engineering/*/commands/swarm.sh --workers 3
```

Or if installed locally, the script path will be in your plugin cache.

Arguments:
- `--workers N`: Number of workers (default: 3, max: 10)
- `--attach`: Attach to tmux session after starting

## What the Script Does

1. Starts/reuses container `work-host-<repo>`
2. Creates tmux session `swarm` with monitor window
3. Spawns N worker windows, each running `claude --dangerously-skip-permissions`
4. Sends initialization prompt to each worker
5. Outputs attach instructions

## Worker Behavior

Each worker autonomously:
1. Reads CLAUDE.md for project context
2. Registers with agent mail (MCP server for coordination)
3. Lists beads and picks one with no unfinished dependencies
4. Claims the bead, implements it, commits, closes it
5. Repeats until no beads remain

## Communication Protocol

Workers coordinate via agent mail MCP server:

- **Broadcast**: Announce claiming/completing beads
- **Direct message**: Coordinate on related work
- **File reservation**: Prevent conflicts on same files

## Swarm Architecture

```
/workflows:plan  →  /workflows:plan:beadify  →  /workflows:work:swarm
     ↓                      ↓                         ↓
  plan.md               .beads/                 work-host-<repo>
                    (tasks + deps)              Docker + tmux
                                               N worker agents
```

## After Launch

To interact with the swarm:

```bash
# Attach to tmux session
docker exec -it work-host-<repo> tmux attach -t swarm

# Switch windows (when attached)
Ctrl-b 0  → Bead monitor (bv TUI)
Ctrl-b 1  → Worker Alpha
Ctrl-b 2  → Worker Beta
Ctrl-b 3  → Worker Gamma
...

# Detach (leave running)
Ctrl-b d

# Stop swarm
docker stop work-host-<repo>

# View agent mail web UI
open http://localhost:8765/mail
```

## Safety Rules for Workers

Workers follow these rules:
1. No destructive commands
2. Commit frequently
3. Test before completing
4. Stay in scope - don't refactor unrelated code
5. Document edge cases

## When Workers Get Stuck

If a worker is blocked:
1. Check if dependencies are actually complete
2. Ask another worker via agent mail
3. Add a comment to the bead
4. Move to a different bead
5. Come back when unblocked

Workers do NOT ask the user for help - they figure it out or move on.
