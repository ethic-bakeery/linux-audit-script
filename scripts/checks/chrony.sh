#!/bin/bash

# Define report file location
REPORT_FILE="reports/chrony_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if Chrony is enabled and running
check_chrony_status() {
    local status="passed"
    local recommendation=""

    if ! systemctl is-enabled --quiet chronyd; then
        status="failed"
        recommendation="Enable Chrony using 'systemctl enable --now chronyd'."
    elif ! systemctl is-active --quiet chronyd; then
        status="failed"
        recommendation="Start Chrony using 'systemctl start chronyd'."
    fi

    echo "{\"check\": \"Ensure Chrony is enabled and running\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check if Chrony is running as user _chrony
check_chrony_user() {
    local status="passed"
    local recommendation=""
    local user=$(ps -o user= -C chronyd 2>/dev/null | awk '{print $1}' | head -n 1)

    if [[ "$user" != "_chrony" ]]; then
        status="failed"
        recommendation="Ensure Chrony runs as '_chrony' by checking '/etc/systemd/system/chronyd.service'."
    fi

    echo "{\"check\": \"Ensure Chrony is running as user _chrony\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check if Chrony is configured with an authorized timeserver (Manual Check)
check_chrony_timeserver() {
    local status="manual"
    local recommendation="Verify that Chrony uses authorized time servers by checking '/etc/chrony/chrony.conf'. Ensure it contains valid 'server' or 'pool' entries."

    echo "{\"check\": \"Ensure Chrony is configured with authorized timeserver\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson chrony_status "$(check_chrony_status)" \
    --argjson chrony_user "$(check_chrony_user)" \
    --argjson chrony_timeserver "$(check_chrony_timeserver)" \
    '{ "chrony_audit": [$chrony_status, $chrony_user, $chrony_timeserver] }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "Chrony audit results saved to $REPORT_FILE"
