#!/bin/bash

# Define report file
REPORT_FILE="reports/host_based_firewall_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Ensure UFW is installed
check_ufw_installed() {
    local status="passed"
    local recommendation=""
    
    if ! command -v ufw &> /dev/null; then
        status="failed"
        recommendation="Install UFW using 'apt install ufw -y'."
    fi
    
    echo "{\"check\": \"Ensure UFW is installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure iptables-persistent is not installed with UFW
check_iptables_persistent() {
    local status="passed"
    local recommendation=""
    
    if dpkg -l | grep -qw iptables-persistent; then
        status="failed"
        recommendation="Remove iptables-persistent with 'apt remove iptables-persistent -y'."
    fi
    
    echo "{\"check\": \"Ensure iptables-persistent is not installed with UFW\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure UFW service is enabled
check_ufw_enabled() {
    local status="passed"
    local recommendation=""
    
    if ! systemctl is-enabled ufw &> /dev/null; then
        status="failed"
        recommendation="Enable UFW using 'systemctl enable --now ufw'."
    fi
    
    echo "{\"check\": \"Ensure UFW service is enabled\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure UFW loopback traffic is configured
check_ufw_loopback() {
    local status="passed"
    local recommendation=""
    
    if ! ufw status | grep -q "ALLOW IN 127.0.0.0/8"; then
        status="failed"
        recommendation="Allow loopback traffic using 'ufw allow in from 127.0.0.0/8'."
    fi
    
    echo "{\"check\": \"Ensure UFW loopback traffic is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure UFW default deny policy
check_ufw_default_deny() {
    local status="passed"
    local recommendation=""
    
    if ! ufw status | grep -q "Default: deny"; then
        status="failed"
        recommendation="Set default deny policy using 'ufw default deny incoming'."
    fi
    
    echo "{\"check\": \"Ensure UFW default deny firewall policy\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson ufw_installed "$(check_ufw_installed)" \
    --argjson iptables_persistent "$(check_iptables_persistent)" \
    --argjson ufw_enabled "$(check_ufw_enabled)" \
    --argjson ufw_loopback "$(check_ufw_loopback)" \
    --argjson ufw_default_deny "$(check_ufw_default_deny)" \
    '{ "host_based_firewall_audit": [$ufw_installed, $iptables_persistent, $ufw_enabled, $ufw_loopback, $ufw_default_deny] }')

echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "Host Based Firewall audit saved to $REPORT_FILE"
