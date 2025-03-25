#!/bin/bash

# Define report file location
REPORT_FILE="reports/timesyncd_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if systemd-timesyncd is enabled and running (Manual Check)
check_timesyncd_status() {
    local status="manual"
    local recommendation="Verify systemd-timesyncd is enabled and running using 'systemctl status systemd-timesyncd'. If not, enable it with 'systemctl enable --now systemd-timesyncd'."

    echo "{\"check\": \"Ensure systemd-timesyncd is enabled and running\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check if systemd-timesyncd is configured with an authorized timeserver
check_timesyncd_timeserver() {
    local status="passed"
    local recommendation=""
    local timeserver=$(grep -E '^NTP=' /etc/systemd/timesyncd.conf | awk -F= '{print $2}')

    if [[ -z "$timeserver" ]]; then
        status="failed"
        recommendation="Edit '/etc/systemd/timesyncd.conf' to specify an authorized timeserver under the 'NTP=' directive and restart the service."
    fi

    echo "{\"check\": \"Ensure systemd-timesyncd is configured with authorized timeserver\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson timesyncd_status "$(check_timesyncd_status)" \
    --argjson timesyncd_timeserver "$(check_timesyncd_timeserver)" \
    '{ "timesyncd_audit": [$timesyncd_status, $timesyncd_timeserver] }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "Systemd-timesyncd audit results saved to $REPORT_FILE"
