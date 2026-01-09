---
name: sync-compound-engineering-plugin
description: Sync whw fork with upstream Every compound-engineering-plugin repo
argument-hint: "[optional: --dry-run to preview only]"
---

Sync the whw-compound-engineering-plugin fork with the upstream Every repository.

## Prerequisites

This command only works when run from within the `whw-compound-engineering-plugin` directory.

## Steps

1. **Verify directory**: Check that the current working directory is `whw-compound-engineering-plugin`. If not, abort with a helpful message telling the user to cd into that directory.

2. **Verify upstream remote**: Run `git remote -v` and confirm an `upstream` remote exists pointing to `EveryInc/compound-engineering-plugin`. If missing, show how to add it:
   ```
   git remote add upstream https://github.com/EveryInc/compound-engineering-plugin.git
   ```

3. **Fetch upstream**: Run `git fetch upstream`

4. **Show pending changes**: Run `git log HEAD..upstream/main --oneline` to show commits that would be merged. Also show a summary with `git diff --stat HEAD..upstream/main`.

5. **Handle dry-run**: If the user passed `--dry-run`, stop here and report the pending changes without merging.

6. **Merge upstream**: Run `git merge upstream/main`

7. **Report results**:
   - If merge succeeded cleanly, report success
   - If there are conflicts, list the conflicting files and provide guidance on resolving them

## Example Output

For a clean merge:
```
Fetched from upstream.
3 new commits from upstream/main:
  abc1234 Add new agent for performance review
  def5678 Update skill documentation
  ghi9012 Fix command argument parsing

Merged upstream/main into main.
```

For dry-run:
```
Fetched from upstream.
3 new commits would be merged from upstream/main:
  abc1234 Add new agent for performance review
  def5678 Update skill documentation
  ghi9012 Fix command argument parsing

Run without --dry-run to merge these changes.
```
