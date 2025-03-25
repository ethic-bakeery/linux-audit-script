#!/bin/bash

# Define report file
REPORT_FILE="reports/network_devices_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Identify IPv6 status (Manual)
ipv6_status=$(sysctl -n net.ipv6.conf.all.disable_ipv6)
ipv6_check="Manual"
ipv6_recommendation="Review and disable IPv6 if not required using 'sysctl -w net.ipv6.conf.all.disable_ipv6=1' and update /etc/sysctl.conf."

# Disable wireless interfaces (Automated)
disable_wireless() {
    local status="passed"
    local recommendation=""
    
    if ip link show | grep -q "wlan"; then
        status="failed"
        recommendation="Disable wireless interfaces with 'nmcli radio wifi off' or disable drivers in modprobe."
    fi

    echo "{\"check\": \"Ensure wireless interfaces are disabled\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure Bluetooth services are not in use (Automated)
check_bluetooth() {
    local status="passed"
    local recommendation=""

    if systemctl is-active --quiet bluetooth; then
        status="failed"
        recommendation="Disable Bluetooth using 'systemctl disable --now bluetooth'."
    fi

    echo "{\"check\": \"Ensure Bluetooth services are not in use\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --arg ipv6_status "$ipv6_status" \
    --arg ipv6_check "$ipv6_check" \
    --arg ipv6_recommendation "$ipv6_recommendation" \
    --argjson wireless "$(disable_wireless)" \
    --argjson bluetooth "$(check_bluetooth)" \
    '{ "network_devices_audit": [
        { "check": "Ensure IPv6 status is identified", "status": $ipv6_check, "recommendation": $ipv6_recommendation },
        $wireless,
        $bluetooth
    ] }')

echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "Network Devices audit saved to $REPORT_FILE"
