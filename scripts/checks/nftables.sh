#!/bin/bash

# Define report file
REPORT_FILE="reports/nftables_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Ensure nftables is installed
check_nftables_installed() {
    local status="passed"
    local recommendation=""
    
    if ! command -v nft &> /dev/null; then
        status="failed"
        recommendation="Install nftables using 'apt install nftables -y'."
    fi
    
    echo "{\"check\": \"Ensure nftables is installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

check_ufw_disabled() {
    local status="passed"
    local recommendation=""
    
    if systemctl is-active --quiet ufw; then
        status="failed"
        recommendation="Disable UFW using 'systemctl stop ufw && systemctl disable ufw'."
    fi
    
    echo "{\"check\": \"Ensure UFW is uninstalled or disabled with nftables\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

check_nftables_chains() {
    local status="passed"
    local recommendation=""
    
    if ! nft list tables | grep -q 'filter'; then
        status="failed"
        recommendation="Create a base chain using 'nft add table inet filter'."
    fi
    
    echo "{\"check\": \"Ensure nftables base chains exist\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

check_nftables_enabled() {
    local status="passed"
    local recommendation=""
    
    if ! systemctl is-enabled nftables &> /dev/null; then
        status="failed"
        recommendation="Enable nftables using 'systemctl enable --now nftables'."
    fi
    
    echo "{\"check\": \"Ensure nftables service is enabled\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

JSON_OUTPUT=$(jq -n \
    --argjson nftables_installed "$(check_nftables_installed)" \
    --argjson ufw_disabled "$(check_ufw_disabled)" \
    --argjson nftables_chains "$(check_nftables_chains)" \
    --argjson nftables_enabled "$(check_nftables_enabled)" \
    '{ "nftables_audit": [$nftables_installed, $ufw_disabled, $nftables_chains, $nftables_enabled] }')

echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "nftables audit saved to $REPORT_FILE"
