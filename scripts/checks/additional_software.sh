#!/bin/bash

# Define report file location
REPORT_FILE="reports/additional_software_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if vlock is installed
check_vlock_installed() {
    local status="passed"
    local recommendation=""

    if ! dpkg -l | grep -q "^ii  vlock"; then
        status="failed"
        recommendation="Install vlock using 'sudo apt install vlock'."
    fi

    echo "{\"check\": \"Ensure vlock is installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check if Endpoint Security for Linux Threat Prevention is installed
check_endpoint_security_installed() {
    local status="passed"
    local recommendation=""

    if ! dpkg -l | grep -q "mcafee-endpoint-security"; then
        status="failed"
        recommendation="Install Endpoint Threat Prevention from McAfee/Trellix."
    fi

    echo "{\"check\": \"Ensure its installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson vlock "$(check_vlock_installed)" \
    --argjson endpoint_security "$(check_endpoint_security_installed)" \
    '{ "additional_software_audit": [$vlock, $endpoint_security] }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "Additional software audit results saved to $REPORT_FILE"
