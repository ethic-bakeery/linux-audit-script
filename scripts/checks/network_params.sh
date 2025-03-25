#!/bin/bash

# Define report file
REPORT_FILE="reports/network_kernel_parameters_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Kernel parameters to enforce
KERNEL_PARAMS=(
    "net.ipv4.ip_forward=0"
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.icmp_ignore_bogus_error_responses=1"
    "net.ipv4.icmp_echo_ignore_broadcasts=1"
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.all.secure_redirects=0"
    "net.ipv4.conf.all.rp_filter=1"
    "net.ipv4.tcp_syncookies=1"
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.all.log_martians=1"
    "net.ipv6.conf.all.accept_ra=0"
)

# Function to check and set kernel parameters
audit_kernel_param() {
    local param="$1"
    local key=$(echo "$param" | cut -d= -f1)
    local expected_value=$(echo "$param" | cut -d= -f2)
    local current_value=$(sysctl -n "$key" 2>/dev/null)
    local status="passed"
    local recommendation=""

    if [[ "$current_value" != "$expected_value" ]]; then
        status="failed"
        recommendation="Set '$key=$expected_value' in /etc/sysctl.conf and reload using 'sysctl -p'."
    fi

    echo "{\"check\": \"$key\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Collect JSON output
JSON_OUTPUT="{\"network_kernel_parameters_audit\": ["
first=true

for param in "${KERNEL_PARAMS[@]}"; do
    result=$(audit_kernel_param "$param")
    if [ "$first" = true ]; then
        JSON_OUTPUT+="$result"
        first=false
    else
        JSON_OUTPUT+=",$result"
    fi
done

JSON_OUTPUT+="]}"

# Save output to file (without printing it)
echo "$JSON_OUTPUT" | jq '.' > "$REPORT_FILE"

echo "Network Kernel Parameters audit saved to $REPORT_FILE"
