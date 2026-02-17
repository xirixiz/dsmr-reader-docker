#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

mode="${CONTAINER_RUN_MODE:-standalone}"

case "${mode}" in
  standalone|server_remote_datalogger)
    # Web UI present: use HTTP health endpoint
    curl -fsSL --connect-timeout 3 --max-time 4 http://127.0.0.1/healthcheck -o /dev/null
    ;;

  remote_datalogger)
    # No Web UI: verify remote datalogger client is running (started as user "app")
    pgrep -u app -af "/app/dsmr_datalogger/scripts/dsmr_datalogger_api_client.py" >/dev/null 2>&1
    ;;

  *)
    exit 1
    ;;
esac
