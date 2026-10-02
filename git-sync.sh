#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

source "$SCRIPT_DIR/lib/output.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/lock.sh"
source "$SCRIPT_DIR/lib/summary.sh"
source "$SCRIPT_DIR/lib/orchestrator.sh"

if [ "${1:-}" = "--init" ]; then
  cat <<'INIT'
# git-sync shell completion
if [ -n "$ZSH_VERSION" ]; then
  _git_sync_complete() {
    _arguments \
      '--silent[no output]' \
      '--debug[verbose output]' \
      '--skip-lock[ignore lock file]' \
      '--lock-ttl=[override lock TTL in hours]:hours:(1 2 4 6 12 24)' \
      '*:directory:_directories'
  }
  compdef _git_sync_complete git-sync
elif [ -n "$BASH_VERSION" ]; then
  _git_sync_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local opts="--silent --debug --skip-lock --lock-ttl="
    if [[ "$cur" == --* ]]; then
      COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    else
      COMPREPLY=( $(compgen -d -- "$cur") )
    fi
  }
  complete -F _git_sync_complete git-sync
fi
INIT
  exit 0
fi

LOG_LEVEL=normal
SKIP_LOCK=0
DIRS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --silent)     LOG_LEVEL=silent; shift ;;
    --debug)      LOG_LEVEL=debug;  shift ;;
    --skip-lock)  SKIP_LOCK=1;      shift ;;
    --lock-ttl=*) LOCK_TTL=$(( ${1#--lock-ttl=} * 3600 )); shift ;;
    --*)          printf "unknown option: %s\n" "$1" >&2; exit 1 ;;
    *)            DIRS+=("$1"); shift ;;
  esac
done

if [ ${#DIRS[@]} -eq 0 ]; then
  printf "usage: %s [--silent|--debug] [--skip-lock] [--lock-ttl=<hours>] <dir1> [dir2 ...]\n" "$(basename "$0")" >&2
  exit 1
fi

run_sync "${DIRS[@]}"

summary_has_issues && exit 1 || exit 0
