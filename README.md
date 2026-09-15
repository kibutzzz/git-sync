# git-sync

Recursively scans directories for git repos and pulls those that are clean and on `main`/`master`. Runs pulls in parallel (up to 8 at a time).

## Installation

```bash
ln -s /path/to/git-sync/git-sync.sh /usr/local/bin/git-sync
```

## Usage

```bash
git-sync [--silent|--debug] <dir1> [dir2 ...]
```

| Flag | Effect |
|---|---|
| _(none)_ | Show repo status and summary |
| `--debug` | Also show timestamps and per-step debug logs |
| `--silent` | No output (use exit code only) |

## Behavior per repo

| State | Action |
|---|---|
| Clean, on main/master | Pull |
| Dirty (uncommitted/unstaged changes) | Skip with warning |
| Not on main/master | Skip with warning — manual action needed |
| Merge conflict | Skip with warning — manual action needed |
| No remote tracking branch | Skip with warning |
| Pull fails | Report error |

Skips `node_modules`, `target`, and `dist` when scanning.

## Exit code

`0` if all repos updated (or already up to date) with no warnings or errors, `1` otherwise.

## Example

```
Syncing 28 repos
OK    usa-tax-service — updated
OK    usa-benefit-service — already up to date
WARN  usa-commons — on branch 'feat/my-feature', manual action required
WARN  usa-garnishment-service — uncommitted changes, skipping

Summary
  Updated
    - usa-tax-service
  Already up to date
    - usa-benefit-service
  Skipped — wrong branch
    - usa-commons [feat/my-feature]
  Skipped — dirty
    - usa-garnishment-service

2 updated, 2 skipped, 0 errors
```
