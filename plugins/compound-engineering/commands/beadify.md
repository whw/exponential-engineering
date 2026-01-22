---
name: workflows:plan:beadify
description: Convert a plan markdown file into granular beads with dependencies
argument-hint: "<path-to-plan.md>"
---

# Plan to Beads Conversion

You are converting a plan markdown file into a comprehensive set of beads (tasks) with proper dependency structure.

## Your Mission

Transform the plan into granular, self-contained beads that can be worked on independently by a swarm of agents. Each bead must contain ALL context needed to implement it without referring back to the plan.

## Phase 1: Analyze the Plan

1. Read the entire plan file provided as argument
2. Identify the hierarchical structure:
   - Epics (major sections/features)
   - Tasks (implementable units)
   - Subtasks (if present)
3. Map dependencies between tasks:
   - What must be done first?
   - What can be parallelized?
   - What are the critical path items?

## Phase 2: Create Beads

**IMPORTANT**: Use `--db .beads/beads.db` to ensure beads are stored in the project-local database (not global).

For each task, create a bead using `bd create`:

```bash
bd --db .beads/beads.db create "<task-title>" \
  -d "<detailed-description>" \
  -l "<project-label>" \
  -t <type: feature|task|bug|chore> \
  -p <priority: 0-4>
```

### Bead Description Requirements

Each bead description MUST include:

1. **Context**: What this task is about and why it matters
2. **Acceptance Criteria**: Specific, testable conditions for completion
3. **Implementation Hints**: Suggested approach, relevant files, patterns to follow
4. **Dependencies**: Which beads must complete first (reference by title)
5. **Testing**: How to verify the implementation works
6. **Edge Cases**: Known gotchas or special considerations

Example description format:
```
## Context
[Why this task exists, how it fits into the larger feature]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation
- Start with [file/component]
- Follow the pattern in [existing code]
- Key considerations: [...]

## Testing
- Unit test: [what to test]
- Integration: [how to verify]

## Notes
- Watch out for [edge case]
- Related to [other task]
```

## Phase 3: Add Dependencies

After creating all beads, establish the dependency graph:

```bash
bd --db .beads/beads.db dep add <child-id> <parent-id>
```

Rules for dependencies:
- A bead cannot start until all its parents are complete
- Minimize dependency chains to enable parallelization
- Create clear critical paths for sequential work

## Phase 4: Polish (3 Rounds)

### Round 1: Self-Containment Check
For each bead, verify:
- Can an agent implement this without reading the original plan?
- Are all file paths, patterns, and context included?
- Is the scope clear and bounded?

### Round 2: Quality Enhancement
For each bead, improve:
- Add more specific acceptance criteria
- Include code snippets or pseudo-code where helpful
- Reference existing patterns in the codebase
- Add testing strategies

### Round 3: Dependency Verification
Review the dependency graph:
- Are there any cycles? (fix them)
- Are there unnecessary dependencies blocking parallelization?
- Is the critical path clear?

## Phase 5: Output Summary

After all beads are created, output:

1. **Bead count by type**: features, tasks, bugs, chores
2. **Dependency tree**: Visual representation
3. **Critical path**: Longest dependency chain
4. **Parallel opportunities**: Beads that can be worked simultaneously
5. **Next command**: Suggest `/workflows:work:swarm --workers N`

## Tools Available

All commands use `--db .beads/beads.db` to target project-local beads:

- `bd --db .beads/beads.db create "<title>" -d "<desc>" -l <label> -t <type> -p <priority>` - Create bead
- `bd --db .beads/beads.db dep add <child> <parent>` - Add dependency
- `bd --db .beads/beads.db list` - List all beads
- `bd --db .beads/beads.db show <id>` - Show bead details
- `bv --db .beads/beads.db --robot-triage` - Analyze bead graph

## Important Notes

- Use ultrathink for complex dependency analysis
- Each bead should take 30min - 2hrs for a skilled developer
- If a task is larger, break it into subtasks
- Labels help filter and organize: use project name as label
