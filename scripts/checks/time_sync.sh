#!/bin/bash

# Define report file location
REPORT_FILE="reports/time_sync_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if time synchronization is in use
check_time_sync() {
    local status="passed"
    local recommendation=""
    
    if ! timedatectl show | grep -q "NTP=yes"; then
        status="failed"
        recommendation="Enable NTP with 'timedatectl set-ntp on'."
    fi

    echo "{\"check\": \"Ensure time synchronization is in use\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check if only a single time synchronization daemon is running
check_single_time_daemon() {
    local status="passed"
    local recommendation=""
    local ntp_services=("chronyd" "ntpd" "systemd-timesyncd")
    local active_services=()

    # Check which time services are active
    for service in "${ntp_services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            active_services+=("$service")
        fi
    done

    # Ensure only one time sync service is running
    if [[ "${#active_services[@]}" -eq 0 ]]; then
        status="failed"
        recommendation="Start a time synchronization service (e.g., 'systemctl enable --now systemd-timesyncd')."
    elif [[ "${#active_services[@]}" -gt 1 ]]; then
        status="failed"
        recommendation="Multiple time synchronization services detected: ${active_services[*]}. Disable unnecessary ones using 'systemctl disable --now <service>'."
    fi

    echo "{\"check\": \"Ensure a single time synchronization daemon is in use\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson time_sync "$(check_time_sync)" \
    --argjson single_daemon "$(check_single_time_daemon)" \
    '{ "time_sync_audit": [$time_sync, $single_daemon] }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "Time synchronization audit results saved to $REPORT_FILE"
