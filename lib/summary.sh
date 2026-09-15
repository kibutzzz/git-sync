#!/usr/bin/env bash

# Arrays accumulating results
SUMMARY_UPDATED=()
SUMMARY_ALREADY_UP_TO_DATE=()
SUMMARY_WARN_DIRTY=()
SUMMARY_WARN_BRANCH=()
SUMMARY_WARN_CONFLICT=()
SUMMARY_WARN_NO_REMOTE=()
SUMMARY_ERROR=()

summary_add_updated()          { SUMMARY_UPDATED+=("$1"); }
summary_add_up_to_date()       { SUMMARY_ALREADY_UP_TO_DATE+=("$1"); }
summary_add_warn_dirty()       { SUMMARY_WARN_DIRTY+=("$1"); }
summary_add_warn_branch()      { SUMMARY_WARN_BRANCH+=("$1 [$2]"); }
summary_add_warn_conflict()    { SUMMARY_WARN_CONFLICT+=("$1"); }
summary_add_warn_no_remote()   { SUMMARY_WARN_NO_REMOTE+=("$1"); }
summary_add_error()            { SUMMARY_ERROR+=("$1: $2"); }

_print_section() {
  local label="$1"; shift
  local items=("$@")
  [ "${#items[@]}" -eq 0 ] && return
  printf "  %s\n" "$label"
  for item in "${items[@]}"; do
    printf "    - %s\n" "$item"
  done
}

print_summary() {
  header "Summary"

  _print_section "${GREEN}Updated${RESET}"              "${SUMMARY_UPDATED[@]+"${SUMMARY_UPDATED[@]}"}"
  _print_section "${GREEN}Already up to date${RESET}"   "${SUMMARY_ALREADY_UP_TO_DATE[@]+"${SUMMARY_ALREADY_UP_TO_DATE[@]}"}"
  _print_section "${YELLOW}Skipped — dirty${RESET}"     "${SUMMARY_WARN_DIRTY[@]+"${SUMMARY_WARN_DIRTY[@]}"}"
  _print_section "${YELLOW}Skipped — wrong branch${RESET}" "${SUMMARY_WARN_BRANCH[@]+"${SUMMARY_WARN_BRANCH[@]}"}"
  _print_section "${YELLOW}Skipped — conflict${RESET}"  "${SUMMARY_WARN_CONFLICT[@]+"${SUMMARY_WARN_CONFLICT[@]}"}"
  _print_section "${YELLOW}Skipped — no remote${RESET}" "${SUMMARY_WARN_NO_REMOTE[@]+"${SUMMARY_WARN_NO_REMOTE[@]}"}"
  _print_section "${RED}Errors${RESET}"                 "${SUMMARY_ERROR[@]+"${SUMMARY_ERROR[@]}"}"

  local total_ok=$(( ${#SUMMARY_UPDATED[@]} + ${#SUMMARY_ALREADY_UP_TO_DATE[@]} ))
  local total_warn=$(( ${#SUMMARY_WARN_DIRTY[@]} + ${#SUMMARY_WARN_BRANCH[@]} + ${#SUMMARY_WARN_CONFLICT[@]} + ${#SUMMARY_WARN_NO_REMOTE[@]} ))
  local total_err=${#SUMMARY_ERROR[@]}

  printf "\n${BOLD}%d updated, %d skipped, %d errors${RESET}\n" \
    "$total_ok" "$total_warn" "$total_err"
}

summary_has_issues() {
  [ $(( ${#SUMMARY_WARN_DIRTY[@]} + ${#SUMMARY_WARN_BRANCH[@]} + \
        ${#SUMMARY_WARN_CONFLICT[@]} + ${#SUMMARY_WARN_NO_REMOTE[@]} + \
        ${#SUMMARY_ERROR[@]} )) -gt 0 ]
}
