#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

source "$SCRIPT_DIR/lib/output.sh"
source "$SCRIPT_DIR/lib/git.sh"
source "$SCRIPT_DIR/lib/lock.sh"
source "$SCRIPT_DIR/lib/summary.sh"
source "$SCRIPT_DIR/lib/orchestrator.sh"

LOG_LEVEL=normal
SKIP_LOCK=0

for arg in "$@"; do
  case "$arg" in
    --silent)    LOG_LEVEL=silent; shift ;;
    --debug)     LOG_LEVEL=debug;  shift ;;
    --skip-lock) SKIP_LOCK=1;      shift ;;
  esac
done

if [ $# -eq 0 ]; then
  printf "usage: %s [--silent|--debug] <dir1> [dir2 ...]\n" "$(basename "$0")" >&2
  exit 1
fi

run_sync "$@"

summary_has_issues && exit 1 || exit 0
