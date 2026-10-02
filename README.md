# git-sync

Recursively scans directories for git repos and pulls those that are clean and on `main`/`master`. Runs pulls in parallel (up to 8 at a time).

## Installation

```bash
ln -s /path/to/git-sync/git-sync.sh /usr/local/bin/git-sync
```

### Shell completion (optional)

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
eval "$(git-sync --init)"
```

This registers tab completion for all flags and directory arguments — no separate files needed.

## Usage

```bash
git-sync [--silent|--debug] [--skip-lock] [--lock-ttl=<hours>] <dir1> [dir2 ...]
```

| Flag | Effect |
|---|---|
| _(none)_ | Show repo status and summary |
| `--debug` | Also show timestamps and per-step debug logs |
| `--silent` | No output (use exit code only) |
| `--skip-lock` | Ignore the lock file and pull regardless of last-updated time |
| `--lock-ttl=<hours>` | Override the lock TTL (default: 12h); e.g. `--lock-ttl=4` |

## Lock file

A `.git-sync-lock` file is created next to the script (gitignored). It records the last successful pull timestamp per repo (`<full-path><TAB><unix-timestamp>`). Repos updated within the last 12 hours are skipped unless `--skip-lock` is passed.

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
