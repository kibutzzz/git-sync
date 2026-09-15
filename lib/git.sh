#!/usr/bin/env bash

# Returns the current branch name
git_branch() {
  git -C "$1" rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Returns 0 if working tree is dirty (unstaged or uncommitted changes)
git_is_dirty() {
  ! git -C "$1" diff --quiet 2>/dev/null || \
  ! git -C "$1" diff --cached --quiet 2>/dev/null
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
