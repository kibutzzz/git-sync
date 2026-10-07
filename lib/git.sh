#!/usr/bin/env bash

# Returns the current branch name
git_branch() {
  git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Returns 0 if working tree is dirty (unstaged or uncommitted changes)
git_is_dirty() {
  git -C "$1" diff --quiet 2>/dev/null && git -C "$1" diff --cached --quiet 2>/dev/null && return 1 || return 0
}

# Returns 0 if repo is in a merge conflict state
git_has_conflict() {
  [ -f "$1/.git/MERGE_HEAD" ]
}

# Pulls the repo. Prints output. Returns git's exit code.
git_pull() {
  git -C "$1" pull 2>&1
}

# Returns 0 if remote tracking branch exists
git_has_remote() {
  git -C "$1" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1
}

# Count commits ahead of remote
git_unpushed_count() {
  git -C "$1" rev-list --count '@{u}..HEAD' 2>/dev/null
}

# Returns the default branch name for origin (e.g. main, master, trunk).
# Falls back to checking for common names if origin/HEAD is not set.
git_default_branch() {
  local repo="$1"
  local ref
  ref=$(git -C "$repo" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  if [ -n "$ref" ]; then
    printf '%s' "${ref#refs/remotes/origin/}"
    return
  fi
  debug "$(basename "$repo") — origin/HEAD not set, probing common branch names" >&2
  # origin/HEAD not set; probe common names against remote refs
  for candidate in main master trunk develop; do
    if git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$candidate"; then
      printf '%s' "$candidate"
      return
    fi
  done
}
