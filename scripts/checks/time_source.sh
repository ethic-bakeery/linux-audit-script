#!/bin/bash

# Define report file location
REPORT_FILE="reports/time_sync_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Ensure system clocks sync when the time difference is greater than 1 second
check_time_drift() {
    local status="passed"
    local recommendation=""
    
    # Check the time difference with an NTP server
    drift=$(chronyc tracking | awk '/System time/ {print $4}')
    drift=${drift%.*}  # Convert to integer

    if (( drift > 1 )); then
        status="failed"
        recommendation="Force synchronization using 'chronyc makestep' or 'ntpdate -q <timeserver>'."
    fi

    echo "{\"check\": \"Ensure system clocks sync when time difference is greater than 1s\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure system clocks sync with the designated time server
check_time_server() {
    local status="passed"
    local recommendation=""
    
    # Check if the system is using an authorized NTP server
    if ! grep -qE "server\s+.*" /etc/ntp.conf /etc/chrony.conf 2>/dev/null; then
        status="failed"
        recommendation="Specify an authorized time server in '/etc/ntp.conf' or '/etc/chrony.conf'."
    fi

    echo "{\"check\": \"Ensure system clocks sync with designated time server\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure system timezone is set to UTC/GMT
check_timezone() {
    local status="passed"
    local recommendation=""
    
    timezone=$(timedatectl show --property=Timezone --value)

    if [[ "$timezone" != "UTC" && "$timezone" != "GMT" ]]; then
        status="failed"
        recommendation="Set timezone to UTC using 'timedatectl set-timezone UTC'."
    fi

    echo "{\"check\": \"Ensure system timezone is set to UTC/GMT\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson time_drift "$(check_time_drift)" \
    --argjson time_server "$(check_time_server)" \
    --argjson timezone "$(check_timezone)" \
    '{ "time_sync_audit": [$time_drift, $time_server, $timezone] }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "Time synchronization audit results saved to $REPORT_FILE"
