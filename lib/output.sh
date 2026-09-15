#!/usr/bin/env bash

if [ -t 1 ]; then
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[0;33m'
  RED=$'\033[0;31m'
  BOLD=$'\033[1m'
  GRAY=$'\033[0;90m'
  RESET=$'\033[0m'
else
  GREEN="" YELLOW="" RED="" BOLD="" GRAY="" RESET=""
fi

_ts() { date +%H:%M:%S; }

ok()    { if [ "${LOG_LEVEL:-normal}" != "silent" ]; then printf "${GREEN}OK${RESET}    %s\n" "$*"; fi; }
warn()  { if [ "${LOG_LEVEL:-normal}" != "silent" ]; then printf "${YELLOW}WARN${RESET}  %s\n" "$*"; fi; }
error() { if [ "${LOG_LEVEL:-normal}" != "silent" ]; then printf "${RED}ERROR${RESET} %s\n" "$*"; fi; }
header(){ if [ "${LOG_LEVEL:-normal}" != "silent" ]; then printf "\n${BOLD}%s${RESET}\n" "$*"; fi; }
debug() { if [ "${LOG_LEVEL:-normal}" = "debug" ];   then printf "${GRAY}[%s] %s${RESET}\n" "$(_ts)" "$*"; fi; }
