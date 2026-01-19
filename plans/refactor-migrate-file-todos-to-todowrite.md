# Refactor: Migrate File-Todos to Claude Code's Built-in TodoWrite

## Enhancement Summary

**Deepened on:** 2026-01-19
**Sections enhanced:** 8
**Research agents used:** code-simplicity-reviewer, architecture-strategist, pattern-recognition-specialist, best-practices-researcher

### Key Improvements
1. Simplified approach: Delete instead of deprecate (YAGNI principle)
2. Added deprecation timeline and communication strategy
3. Identified anti-patterns to fix during migration
4. Added alternative for persistent tracking (GitHub Issues)

### New Considerations Discovered
- TodoWrite is already used inconsistently across commands
- Dual state storage in file-todos is an anti-pattern
- For persistent items, use GitHub Issues instead of maintaining parallel system

---

## Overview

Consolidate the plugin's task tracking to use Claude Code's built-in `TodoWrite` tool instead of the custom file-based todo system (`todos/` directory).

## Problem Statement

The plugin currently maintains **two separate task tracking systems**:

1. **File-based todos** (`todos/` directory) - Markdown files with YAML frontmatter, used for persistent tracking
2. **TodoWrite** (Claude Code built-in) - In-memory task list, already used by `/workflows:work`

This creates confusion about which system to use and when. The user wants to standardize on Claude Code's built-in TodoWrite.

### Research Insights

**Anti-Patterns Identified:**
- **Dual state storage**: Status stored in both filename AND YAML frontmatter (drift risk)
- **Implicit coupling**: Commands coupled through shared `todos/` directory convention
- **Inconsistent usage**: TodoWrite already used in `/triage`, `/workflows:work`, `/resolve_parallel` but mixed with file-todos

**Current TodoWrite Usage (already present):**
| Command | Uses TodoWrite For |
|---------|-------------------|
| `/workflows:work` | Task tracking during execution |
| `/triage` | Progress visibility during triage |
| `/resolve_parallel` | Planning before parallel execution |

---

## Proposed Approach: Simplify to TodoWrite Only

### Research Insight: Delete, Don't Deprecate

> "Deprecation is a form of complexity preservation. If you're removing file-todos, delete the skill. Don't maintain deprecated code that 'might be useful someday.'" — Code Simplicity Review

Since the user wants to use Claude Code's built-in todos, we'll:

1. **Delete the `file-todos` skill entirely** (not deprecate)
2. **Delete the `/triage` command** (no longer needed)
3. **Remove file-todo creation** from all commands
4. **Update `/resolve_todo_parallel`** to work with TodoWrite or delete if redundant

### What We Lose (Acceptable Trade-offs)

| Capability Lost | Alternative |
|-----------------|-------------|
| Cross-session persistence | Create GitHub Issues for unresolved P1/P2 items |
| Approval/triage workflow | Inline confirmation before resolution |
| Dependency ordering | Manual ordering in TodoWrite list |
| Work logs/audit trail | Git commit messages |

### What We Gain

- Single unified system
- Native Claude Code UI integration
- Simpler mental model
- No custom file management
- Eliminates dual-state anti-pattern

---

## Implementation Plan

### Phase 1: Update `/workflows:review` (Main Change)

**Current behavior:** Creates todo files in `todos/` directory for each review finding

**New behavior:** Uses TodoWrite to track findings during the session

**File:** `plugins/compound-engineering/commands/workflows/review.md`

**Changes:**
- [ ] Remove Section 7 that creates file-todos (lines 192-330)
- [ ] Add TodoWrite tracking for review findings
- [ ] Update synthesis step to use TodoWrite for actionable items
- [ ] Remove references to `/triage` command
- [ ] Add option: "Create GitHub issues for unresolved P1/P2 findings?"

### Research Insights

**Best Practice - Inline Approval:**
Instead of separate `/triage` command, present findings with severity during review and require explicit confirmation before spawning resolution agents. This preserves the approval gate inline.

**Implementation Pattern:**
```markdown
## After Synthesis

Present findings to user via AskUserQuestion:
"Found X issues (Y critical, Z important). Which should I resolve now?"

Options:
1. Resolve all - Start fixing immediately
2. Resolve critical only - Fix P1 items only
3. Create GitHub issues - Persist for later
4. Skip - Don't resolve any
```

---

### Phase 2: Delete Related Commands

#### `/triage` Command
**File:** `plugins/compound-engineering/commands/triage.md`
- [ ] Delete this file entirely
- [ ] Remove from plugin.json commands list
- [ ] Update any references in other commands

#### `/resolve_todo_parallel` Command
**File:** `plugins/compound-engineering/commands/resolve_todo_parallel.md`

**Decision needed:** Does this add value over TodoWrite's native handling?

- [ ] Option A: Delete entirely (TodoWrite + Task agents handles parallelization)
- [ ] Option B: Rename to `/resolve-findings` with TodoWrite input

**Research Insight:**
> "The three commands (`/resolve_parallel`, `/resolve_todo_parallel`, `/resolve_pr_parallel`) are nearly identical in structure but operate on different sources. Consolidate." — Pattern Recognition Analysis

**Recommendation:** Keep only `/resolve_parallel` for code TODOs and `/resolve_pr_parallel` for PR comments. Delete `/resolve_todo_parallel`.

---

### Phase 3: Update Test Commands

#### `/test-browser` Command
**File:** `plugins/compound-engineering/commands/test-browser.md`
- [ ] Remove todo file creation (around line 248)
- [ ] Keep TodoWrite tracking for test failures
- [ ] Add option to create GitHub issues for persistent tracking

#### `/xcode-test` Command
**File:** `plugins/compound-engineering/commands/xcode-test.md`
- [ ] Remove todo file creation (around line 248)
- [ ] Keep TodoWrite tracking for test failures

---

### Phase 4: Delete `file-todos` Skill

**Directory:** `plugins/compound-engineering/skills/file-todos/`

**Research Insight - YAGNI:**
> "The plan correctly identifies redundancy and removes it. The only YAGNI violation is keeping deprecated code around. Delete cleanly, don't deprecate." — Code Simplicity Review

- [ ] Delete `skills/file-todos/SKILL.md`
- [ ] Delete `skills/file-todos/assets/todo-template.md`
- [ ] Delete `skills/file-todos/` directory
- [ ] Update plugin.json skills count

---

### Phase 5: Update Documentation

- [ ] Update README.md to reflect TodoWrite usage
- [ ] Update CHANGELOG.md with migration notes
- [ ] Remove references to `todos/` directory workflow
- [ ] Update skill count in plugin.json description

---

## Files to Modify/Delete

| File | Action | Description |
|------|--------|-------------|
| `commands/workflows/review.md` | **Edit** | Remove file-todo creation, add inline approval |
| `commands/triage.md` | **Delete** | No longer needed |
| `commands/resolve_todo_parallel.md` | **Delete** | Consolidate into /resolve_parallel |
| `commands/test-browser.md` | **Edit** | Remove todo file creation |
| `commands/xcode-test.md` | **Edit** | Remove todo file creation |
| `skills/file-todos/` | **Delete** | Entire directory |
| `README.md` | **Edit** | Remove file-todos workflow references |
| `CHANGELOG.md` | **Edit** | Document breaking change |
| `.claude-plugin/plugin.json` | **Edit** | Update counts |

---

## Acceptance Criteria

- [ ] No commands create files in `todos/` directory
- [ ] All in-session task tracking uses TodoWrite
- [ ] `/triage` command deleted
- [ ] `/resolve_todo_parallel` command deleted
- [ ] `file-todos` skill deleted
- [ ] Documentation updated to reflect new workflow
- [ ] GitHub Issues offered as persistence alternative

---

## Migration Notes for Existing Users

### Breaking Changes

This is a **breaking change** for users who rely on the `todos/` directory.

**What's removed:**
- `file-todos` skill
- `/triage` command
- `/resolve_todo_parallel` command
- Automatic todo file creation in `/workflows:review`

**What to do:**
1. Complete or delete existing `todos/*.md` files before upgrading
2. Use TodoWrite for session tracking (automatic)
3. Use GitHub Issues for persistent tracking

### Communication Strategy

**In CHANGELOG.md:**
```markdown
## Breaking Changes

### File-Based Todo System Removed

The `file-todos` skill and related commands have been removed in favor of
Claude Code's built-in TodoWrite tool.

**Removed:**
- `file-todos` skill
- `/triage` command
- `/resolve_todo_parallel` command

**Migration:**
- Session tracking: Automatic via TodoWrite
- Persistent tracking: Create GitHub Issues

**Why:** TodoWrite provides native UI integration and eliminates the dual
tracking system that caused confusion.
```

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users have existing todos | Medium | Low | Document migration path |
| Users need persistence | Low | Medium | GitHub Issues as alternative |
| Breaking existing scripts | Low | Low | Clean break, no gradual deprecation |

### Research Insight - Clean Breaks

> "For a plugin (not critical infrastructure), a clean break is acceptable. The compounding engineering philosophy favors simplicity over completeness." — Architecture Strategy Review

---

## References

### Internal Files
- `plugins/compound-engineering/skills/file-todos/SKILL.md` - Current skill definition (to be deleted)
- `plugins/compound-engineering/commands/workflows/review.md:192-330` - Todo creation in review
- `plugins/compound-engineering/commands/triage.md` - Triage workflow (to be deleted)

### External Documentation
- [Claude Code TodoWrite Tool](https://platform.claude.com/docs/en/agent-sdk/todo-tracking)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [npm Deprecation Practices](https://docs.npmjs.com/deprecating-and-undeprecating-packages-or-package-versions/)

### Research Sources
- Code Simplicity Review: YAGNI analysis
- Architecture Strategy Review: Hybrid vs clean migration analysis
- Pattern Recognition Analysis: Anti-patterns in current system
- Best Practices Research: Deprecation communication strategies
