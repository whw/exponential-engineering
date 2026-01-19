# Plan: Add /workflows:compound to /lfg Workflow

## Overview

Add `/workflows:compound` as the final step before completion in the `/lfg` autonomous engineering workflow, so learnings are automatically captured at the end of each feature.

## Problem Statement

Currently, `/lfg` completes without capturing learnings. The `/workflows:compound` command exists to capture learnings, but it's not invoked automatically. This means valuable knowledge from each feature development session is lost unless manually captured.

## Proposed Solution

Add `/workflows:compound` as step 9 in the `/lfg` command, shifting the `<promise>DONE</promise>` output to step 10.

## Technical Approach

### Changes Required

- [ ] **`commands/lfg.md`** - Add step 9: `/workflows:compound` and renumber DONE to step 10

### Before

```markdown
1. `/ralph-loop:ralph-loop "finish all slash commands" --completion-promise "DONE"`
2. `/workflows:plan $ARGUMENTS`
3. `/exponential-engineering:deepen-plan`
4. `/workflows:work`
5. `/workflows:review`
6. `/exponential-engineering:resolve_parallel`
7. `/exponential-engineering:test-browser`
8. `/exponential-engineering:feature-video`
9. Output `<promise>DONE</promise>` when video is in PR
```

### After

```markdown
1. `/ralph-loop:ralph-loop "finish all slash commands" --completion-promise "DONE"`
2. `/workflows:plan $ARGUMENTS`
3. `/exponential-engineering:deepen-plan`
4. `/workflows:work`
5. `/workflows:review`
6. `/exponential-engineering:resolve_parallel`
7. `/exponential-engineering:test-browser`
8. `/exponential-engineering:feature-video`
9. `/workflows:compound`
10. Output `<promise>DONE</promise>` when all steps complete
```

## Acceptance Criteria

- [ ] `/workflows:compound` is step 9 in `/lfg`
- [ ] DONE output is step 10
- [ ] Version bumped to 2.26.5+fork.7
- [ ] CHANGELOG updated

## References

- `commands/lfg.md` - Target file
- `commands/workflows/compound.md` - Command being added
