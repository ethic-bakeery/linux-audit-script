#!/bin/bash

REPORT_FILE="reports/iptables_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

check_iptables_installed() {
    local status="passed"
    local recommendation=""
    
    if ! command -v iptables &> /dev/null; then
        status="failed"
        recommendation="Install iptables using 'apt install iptables -y'."
    fi
    
    echo "{\"check\": \"Ensure iptables packages are installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

check_nftables_not_installed() {
    local status="passed"
    local recommendation=""
    
    if command -v nft &> /dev/null; then
        status="failed"
        recommendation="Remove nftables using 'apt remove nftables -y'."
    fi
    
    echo "{\"check\": \"Ensure nftables is not installed with iptables\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

check_iptables_default_deny() {
    local status="passed"
    local recommendation=""
    
    if ! iptables -L | grep -q "DROP"; then
        status="failed"
        recommendation="Set default policy to deny using 'iptables -P INPUT DROP'."
    fi
    
    echo "{\"check\": \"Ensure iptables default deny firewall policy\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure iptables loopback traffic is configured
check_iptables_loopback() {
    local status="passed"
    local recommendation=""
    
    if ! iptables -L | grep -q "ACCEPT" | grep -q "lo"; then
        status="failed"
        recommendation="Allow loopback using 'iptables -A INPUT -i lo -j ACCEPT'."
    fi
    
    echo "{\"check\": \"Ensure iptables loopback traffic is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

JSON_OUTPUT=$(jq -n \
    --argjson iptables_installed "$(check_iptables_installed)" \
    --argjson nftables_not_installed "$(check_nftables_not_installed)" \
    --argjson iptables_default_deny "$(check_iptables_default_deny)" \
    --argjson iptables_loopback "$(check_iptables_loopback)" \
    '{ "iptables_audit": [$iptables_installed, $nftables_not_installed, $iptables_default_deny, $iptables_loopback] }')

echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "iptables audit saved to $REPORT_FILE"
