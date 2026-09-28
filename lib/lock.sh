#!/usr/bin/env bash

LOCK_FILE="$SCRIPT_DIR/.git-sync-lock"
LOCK_TTL=${LOCK_TTL:-86400}  # 24h in seconds

lock_print_state() {
  [ "${LOG_LEVEL:-normal}" = "debug" ] || return 0
  if [ ! -f "$LOCK_FILE" ] || [ ! -s "$LOCK_FILE" ]; then
    debug "lock: no entries in lock file"
    return
  fi
  local now
  now=$(date +%s)
  debug "lock: current entries (TTL ${LOCK_TTL}s):"
  while IFS='	' read -r path ts status; do
    local age remaining
    age=$(( now - ts ))
    remaining=$(( LOCK_TTL - age ))
    if [ "$remaining" -gt 0 ]; then
      local expires_at expires_str
      expires_at=$(( ts + LOCK_TTL ))
      expires_str=$(date -r "$expires_at" '+%H:%M:%S' 2>/dev/null || date -d "@$expires_at" '+%H:%M:%S')
      debug "lock:   FRESH   $(basename "$path") [$status] — expires at $expires_str (in ${remaining}s)"
    else
      debug "lock:   STALE   $(basename "$path") [$status] — expired ${age}s ago"
    fi
  done < "$LOCK_FILE"
}

# Returns 0 if repo was updated within TTL and --skip-lock was not set.
# Sets LOCK_REMAINING to seconds until expiry when fresh.
# Sets LOCK_LAST_STATUS to the last recorded status when fresh.
lock_is_fresh() {
  local repo="$1"
  LOCK_REMAINING=0
  LOCK_LAST_STATUS=""

  if [ "${SKIP_LOCK:-0}" = "1" ]; then
    debug "lock: --skip-lock set, ignoring lock for $repo"
    return 1
  fi

  [ -f "$LOCK_FILE" ] || return 1

  local line
  line=$(grep -F "$repo	" "$LOCK_FILE" 2>/dev/null) || return 1

  local ts status now age
  ts=$(printf '%s' "$line" | cut -f2)
  status=$(printf '%s' "$line" | cut -f3)
  now=$(date +%s)
  age=$(( now - ts ))
  LOCK_REMAINING=$(( LOCK_TTL - age ))
  LOCK_LAST_STATUS="$status"

  debug "lock: $(basename "$repo") last updated ${age}s ago [$status] — expires in ${LOCK_REMAINING}s"

  [ "$age" -lt "$LOCK_TTL" ]
}

# Writes or updates the timestamp and status for repo in the lock file
lock_update() {
  local repo="$1"
  local status="$2"
  local now
  now=$(date +%s)

  debug "lock: recording [$status] for $(basename "$repo") ($(date -r "$now" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$now" '+%Y-%m-%d %H:%M:%S'))"

  (
    set +e
    local lockdir="$LOCK_FILE.d"
    local tries=0
    until mkdir "$lockdir" 2>/dev/null; do
      sleep 0.05
      tries=$(( tries + 1 ))
      if [ "$tries" -ge 100 ]; then
        rmdir "$lockdir" 2>/dev/null
      fi
    done
    trap 'rmdir "$lockdir" 2>/dev/null' EXIT

    if [ -f "$LOCK_FILE" ] && grep -qF "$repo	" "$LOCK_FILE" 2>/dev/null; then
      local tmp
      tmp=$(mktemp)
      grep -vF "$repo	" "$LOCK_FILE" > "$tmp" || true
      printf '%s\t%s\t%s\n' "$repo" "$now" "$status" >> "$tmp"
      mv "$tmp" "$LOCK_FILE"
    else
      printf '%s\t%s\t%s\n' "$repo" "$now" "$status" >> "$LOCK_FILE"
    fi
  )
  return 0
}
