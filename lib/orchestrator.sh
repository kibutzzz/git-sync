#!/usr/bin/env bash

# Writes a single result token to a temp file so the parent can aggregate.
# Format: "<category> <value>" where value may contain spaces.
_write_result() {
  printf '%s %s\n' "$1" "$2" >> "$RESULT_DIR/$(basename "$3")"
}

_process_repo() {
  local repo="$1"
  local name
  name=$(basename "$repo")

  if git_has_conflict "$repo"; then
    warn "$name — merge conflict, manual action required"
    _write_result "conflict" "$name" "$repo"
    return
  fi

  if git_is_dirty "$repo"; then
    warn "$name — uncommitted changes, skipping"
    _write_result "dirty" "$name" "$repo"
    return
  fi

  if ! git_has_remote "$repo"; then
    warn "$name — no remote tracking branch, skipping"
    _write_result "no_remote" "$name" "$repo"
    return
  fi

  local branch
  branch=$(git_branch "$repo")

  if [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
    warn "$name — on branch '$branch', manual action required"
    _write_result "branch" "$name [$branch]" "$repo"
    return
  fi

  local pull_out exit_code
  debug "$name pulling..."
  pull_out=$(git_pull "$repo") && exit_code=0 || exit_code=$?

  if [ $exit_code -ne 0 ]; then
    error "$name — pull failed"
    printf "    %s\n" "$pull_out"
    _write_result "error" "$name: pull failed" "$repo"
    return
  fi

  if printf '%s' "$pull_out" | grep -q "Already up to date"; then
    ok "$name — already up to date"
    _write_result "up_to_date" "$name" "$repo"
  else
    ok "$name — updated"
    _write_result "updated" "$name" "$repo"
  fi
}

_find_repos() {
  find "$1" \
    -name node_modules -prune -o \
    -name target -prune -o \
    -name dist -prune -o \
    -name .git -type d -prune -print \
    2>/dev/null \
  | while IFS= read -r git_dir; do
    printf '%s\n' "${git_dir%/.git}"
  done
}

_load_results() {
  for f in "$RESULT_DIR"/*; do
    [ -f "$f" ] || continue
    while IFS= read -r line; do
      local category value
      category="${line%% *}"
      value="${line#* }"
      case "$category" in
        updated)    summary_add_updated    "$value" ;;
        up_to_date) summary_add_up_to_date "$value" ;;
        dirty)      summary_add_warn_dirty "$value" ;;
        branch)     SUMMARY_WARN_BRANCH+=("$value") ;;
        conflict)   summary_add_warn_conflict "$value" ;;
        no_remote)  summary_add_warn_no_remote "$value" ;;
        error)      SUMMARY_ERROR+=("$value") ;;
      esac
    done < "$f"
  done
}

run_sync() {
  local dirs=("$@")
  RESULT_DIR=$(mktemp -d)
  # Trap only in the parent shell, not in backgrounded subshells
  trap 'rm -rf "$RESULT_DIR"' EXIT

  local all_repos=()
  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      error "directory not found: $dir"
      continue
    fi
    debug "scanning $dir for repos..."
    while IFS= read -r repo; do
      debug "found $repo"
      all_repos+=("$repo")
    done < <(_find_repos "$dir")
    debug "done scanning $dir — ${#all_repos[@]} repos so far"
  done

  if [ "${#all_repos[@]}" -eq 0 ]; then
    warn "no git repos found in any of the given directories"
    return
  fi

  header "Syncing ${#all_repos[@]} repos"

  local max_jobs=8
  for repo in "${all_repos[@]}"; do
    while [ "$(jobs -rp | wc -l)" -ge "$max_jobs" ]; do
      wait -n 2>/dev/null || wait
    done
    debug "starting $(basename $repo)"
    ( trap '' EXIT; _process_repo "$repo" ) &
  done

  debug "all jobs dispatched, waiting..."
  wait
  debug "all jobs done, loading results..."
  _load_results
  print_summary
}
