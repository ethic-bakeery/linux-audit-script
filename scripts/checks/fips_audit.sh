#!/bin/bash

# Define report file location
REPORT_FILE="reports/fips_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if FIPS mode is enabled
check_fips_mode() {
    local status="passed"
    local recommendation=""

    if ! cat /proc/sys/crypto/fips_enabled 2>/dev/null | grep -q "1"; then
        status="failed"
        recommendation="Enable FIPS mode using 'sudo fips-mode-setup --enable' and reboot the system."
    fi

    echo "{\"check\": \"Ensure FIPS mode is enabled\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson fips "$(check_fips_mode)" \
    '{ "fips_audit": [$fips] }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "FIPS audit results saved to $REPORT_FILE"
