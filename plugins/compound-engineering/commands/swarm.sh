#!/bin/bash
set -e

# Swarm launcher script - starts Docker container with tmux and Claude Code workers
#
# FULL WORKER PROMPT (sent to each worker on initialization):
# ============================================================
#
# You are a swarm worker - one of multiple Claude Code agents working
# collaboratively to implement beads (tasks) in this project.
#
# ## Your Identity
# - You are Worker-[NAME]
# - You work autonomously but coordinate with other workers
# - You do NOT ask questions - all context is in beads and CLAUDE.md
# - You have full permissions (--dangerously-skip-permissions)
#
# ## First Steps (Do These Now)
# 1. Read CLAUDE.md: `cat CLAUDE.md` - understand project context
# 2. Register with agentmail:
#    agentmail register --name "Worker-[NAME]" --project "$(pwd)"
# 3. Check for messages: agentmail inbox
# 4. Find work: bv --robot-next (returns top priority bead as JSON)
#
# ## Work Loop (Repeat Until No Beads Remain)
#
# ### Step 1: Find Next Bead
# Run: bv --robot-next
# This returns the top priority bead with proper dependency analysis.
# The output includes the bead ID and a claim command.
#
# ### Step 2: Claim the Bead
#   br --db .beads/beads.db update <bead-id> --status in_progress
#   agentmail broadcast "Claiming bead <bead-id>: <title>"
#
# ### Step 3: Reserve Files
# Before editing any file, reserve it:
#   agentmail reserve "<file-path>" --exclusive
# If reservation fails (another worker has it), either:
# - Wait and retry
# - Choose a different bead
# - Message the other worker to coordinate
#
# ### Step 4: Implement
# - Read the bead description carefully: br --db .beads/beads.db show <bead-id>
# - Follow all acceptance criteria
# - Use existing patterns in the codebase
# - Write tests as you go
# - Keep changes focused on the bead scope
#
# ### Step 5: Fresh Eyes Review
# After implementing, review your own work:
#   Review the code I just wrote with fresh eyes. Look for:
#   - Obvious bugs or logic errors
#   - Missing edge cases
#   - Inconsistent patterns
#   - Security issues
#   - Performance problems
#   Fix anything you find before proceeding.
#
# ### Step 6: Complete the Bead
#   # Run any relevant tests
#   # Commit the changes
#   git add -A && git commit -m "Complete bead <id>: <title>
#
#   <brief description of changes>
#
#   Acceptance criteria met:
#   - [x] Criterion 1
#   - [x] Criterion 2"
#
#   # Mark bead complete
#   br --db .beads/beads.db close <bead-id> --reason "Implemented and tested"
#
#   # Release file reservations
#   agentmail release-all
#
#   # Notify other workers
#   agentmail broadcast "Completed bead <bead-id>: <title>"
#
# ### Step 7: Check Messages and Continue
#   agentmail inbox  # Respond to any messages
#   # Find next bead and repeat
#
# ## Communication Protocol
#
# ### Broadcast Messages (to all workers)
#   agentmail broadcast "<message>"
# Use for: Claiming beads, Completing beads, Major discoveries, Requesting help
#
# ### Direct Messages (to specific worker)
#   agentmail send "Worker-Beta" "<message>"
# Use for: Coordinating on related beads, Handing off context, Asking about reserved files
#
# ## File Reservation Rules
# 1. Always reserve before editing - no exceptions
# 2. Exclusive reservations for files you're actively changing
# 3. Release promptly - don't hold files longer than needed
# 4. Check conflicts - if reservation fails, coordinate with the holder
#
# ## After Context Compaction
# If Claude compacts your context:
# 1. Re-read CLAUDE.md: cat CLAUDE.md
# 2. Check your current bead: br --db .beads/beads.db list --status in_progress
# 3. Check agentmail: agentmail inbox
# 4. Continue where you left off
#
# ## Safety Rules
# 1. No destructive commands - dcg will block dangerous operations
# 2. Commit frequently - don't accumulate large uncommitted changes
# 3. Test before completing - verify your work meets acceptance criteria
# 4. Stay in scope - don't refactor unrelated code
# 5. Document edge cases - add comments for non-obvious decisions
#
# ## When Stuck
# If blocked on a bead:
# 1. Check if dependencies are actually complete
# 2. Ask another worker via agentmail
# 3. Mark the bead with a comment: br --db .beads/beads.db comment <id> "Blocked on X"
# 4. Move to a different bead
# 5. Come back when unblocked
#
# DO NOT ask the user for help. Figure it out or move on.
#
# ============================================================
#
# SWARM ARCHITECTURE:
# ============================================================
#
# ╔══════════════════════════════════════════════════════════════════╗
# ║                    SWARM STARTED SUCCESSFULLY                     ║
# ╠══════════════════════════════════════════════════════════════════╣
# ║  Container: work-host-${REPO}                                    ║
# ║  Workers:   ${N}                                                 ║
# ║  Session:   swarm                                                ║
# ╠══════════════════════════════════════════════════════════════════╣
# ║  COMMANDS:                                                       ║
# ║                                                                  ║
# ║  Attach to session:                                              ║
# ║    docker exec -it work-host-${REPO} tmux attach -t swarm        ║
# ║                                                                  ║
# ║  Switch windows (when attached):                                 ║
# ║    Ctrl-b 0  → Agent mail monitor                                ║
# ║    Ctrl-b 1  → Worker Alpha                                      ║
# ║    Ctrl-b 2  → Worker Beta                                       ║
# ║    Ctrl-b 3  → Worker Gamma                                      ║
# ║    ...                                                           ║
# ║                                                                  ║
# ║  Detach (leave running):                                         ║
# ║    Ctrl-b d                                                      ║
# ║                                                                  ║
# ║  Stop swarm:                                                     ║
# ║    docker stop work-host-${REPO}                                 ║
# ║                                                                  ║
# ║  View logs:                                                      ║
# ║    docker logs work-host-${REPO}                                 ║
# ╚══════════════════════════════════════════════════════════════════╝
#
# WORKFLOW OVERVIEW:
#
#   /workflows:plan  →  /workflows:plan:beadify  →  /workflows:work:swarm
#        ↓                      ↓                         ↓
#     plan.md               .beads/                 work-host-<repo>
#                       (tasks + deps)              Docker + tmux
#                                                   N worker agents
#
# ============================================================

WORKERS=3
ATTACH=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --workers)
            WORKERS="$2"
            shift 2
            ;;
        --attach)
            ATTACH=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate workers
if [[ $WORKERS -lt 1 || $WORKERS -gt 10 ]]; then
    echo "Error: workers must be between 1 and 10"
    exit 1
fi

# Get repo name and container name
REPO=$(basename "$(pwd)")
CONTAINER="work-host-${REPO}"

echo "Starting swarm with $WORKERS workers..."

# Start container if not running
if docker ps -q -f name="${CONTAINER}" | grep -q .; then
    echo "Container ${CONTAINER} already running"
else
    docker rm "${CONTAINER}" 2>/dev/null || true
    # Mount repo to /home/worker/repo and .claude to worker's home
    # Expose port 8765 for agent mail web UI
    docker run -d --name "${CONTAINER}" \
        -v "$(pwd):/home/worker/${REPO}" \
        -v ~/.claude:/home/worker/.claude \
        -w "/home/worker/${REPO}" \
        -p 8765:8765 \
        work-host-image:latest \
        tail -f /dev/null
    echo "Started container ${CONTAINER}"
fi

# Kill existing tmux session
docker exec "${CONTAINER}" tmux kill-session -t swarm 2>/dev/null || true

# Start agent mail HTTP server without auth (local dev only)
# Web UI at http://localhost:8765/mail
docker exec "${CONTAINER}" bash -c "cd /home/worker/mcp_agent_mail && uv run python -m mcp_agent_mail.cli serve-http --host 0.0.0.0 --port 8765 > /tmp/agentmail.log 2>&1 &"
sleep 2

# Configure agent mail as MCP server for workers (no auth needed)
docker exec "${CONTAINER}" bash -c "cat > /home/worker/${REPO}/.mcp.json << 'MCPEOF'
{
  \"mcpServers\": {
    \"agent-mail\": {
      \"type\": \"http\",
      \"url\": \"http://127.0.0.1:8765/mcp/\"
    }
  }
}
MCPEOF"

# Create new tmux session with monitor window running bv TUI
docker exec "${CONTAINER}" tmux new-session -d -s swarm -n monitor
docker exec "${CONTAINER}" tmux send-keys -t swarm:monitor 'bv' Enter

# Worker names
NAMES=("Alpha" "Beta" "Gamma" "Delta" "Epsilon" "Zeta" "Eta" "Theta" "Iota" "Kappa")

# Spawn workers with initial prompt
for i in $(seq 1 "$WORKERS"); do
    WORKER_NAME=${NAMES[$i-1]}

    # Create prompt file inside container (avoids shell quoting issues)
    docker exec "${CONTAINER}" bash -c "cat > /tmp/prompt-${WORKER_NAME}.txt << 'EOF'
You are Worker-${WORKER_NAME}, a swarm worker implementing beads autonomously.

IMPORTANT: Agent mail is an MCP server, NOT a CLI. Use MCP tools like:
- mcp__agent-mail__register_agent (to register)
- mcp__agent-mail__send_message (to communicate)
Do NOT run agentmail as a bash command.

FIRST STEPS:
1. cat CLAUDE.md - understand project
2. Call MCP tool mcp__agent-mail__register_agent with name=Worker-${WORKER_NAME}
3. bv --robot-next - get top priority bead

WORK LOOP:
1. bv --robot-next - get top priority bead ID
2. br --db .beads/beads.db update <id> --status in_progress
3. br --db .beads/beads.db show <id> - read full description
4. Implement it following acceptance criteria
5. git add -A && git commit -m 'Complete bead <id>: <title>'
6. br --db .beads/beads.db close <id> --reason 'Done'
7. Repeat from step 1

Start now. No questions.
EOF"

    # Create window and start Claude with initial prompt from file
    docker exec "${CONTAINER}" tmux new-window -t swarm -n "worker-${WORKER_NAME}"
    docker exec "${CONTAINER}" tmux send-keys -t "swarm:worker-${WORKER_NAME}" \
        'claude --dangerously-skip-permissions "$(cat /tmp/prompt-'${WORKER_NAME}'.txt)"' Enter

    echo "Created Worker-${WORKER_NAME}"
    sleep 1
done

# Balance layout
docker exec "${CONTAINER}" tmux select-layout -t swarm tiled 2>/dev/null || true

echo ""
echo "=========================================="
echo "SWARM STARTED: ${CONTAINER}"
echo "Workers: ${WORKERS}"
echo "=========================================="
echo ""
echo "Attach:     docker exec -it ${CONTAINER} tmux attach -t swarm"
echo "Detach:     Ctrl-b d"
echo "Windows:    Ctrl-b 0 (monitor/bv), Ctrl-b 1+ (workers)"
echo "Agent Mail: http://localhost:8765/mail"
echo "Stop:       docker stop ${CONTAINER}"
echo ""

# Attach if requested
if [ "$ATTACH" = true ]; then
    docker exec -it "${CONTAINER}" tmux attach -t swarm
fi
