#!/bin/bash

# Define report file
REPORT_FILE="reports/ssh_server_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if SSH is installed and active
check_ssh_installed() {
    if systemctl is-active --quiet sshd; then
        echo '{"check": "Ensure SSH is installed and active", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure SSH is installed and active", "status": "failed", "recommendation": "Install and enable SSH using apt, yum, or dnf."}'
    fi
}

# Function to check permissions on sshd_config
check_sshd_config_permissions() {
    if stat -c "%a" /etc/ssh/sshd_config | grep -qE "^6[0-4][0-4]$|^7[0-5][0-5]$"; then
        echo '{"check": "Ensure permissions on /etc/ssh/sshd_config are configured", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure permissions on /etc/ssh/sshd_config are configured", "status": "failed", "recommendation": "Set permissions using chmod 600 /etc/ssh/sshd_config."}'
    fi
}

# Function to check SSH root login is disabled
check_ssh_root_login() {
    if grep -q "^PermitRootLogin no" /etc/ssh/sshd_config; then
        echo '{"check": "Ensure SSH root login is disabled", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure SSH root login is disabled", "status": "failed", "recommendation": "Set PermitRootLogin no in /etc/ssh/sshd_config."}'
    fi
}

# Function to check SSH PAM is enabled
check_ssh_pam_enabled() {
    if grep -q "^UsePAM yes" /etc/ssh/sshd_config; then
        echo '{"check": "Ensure SSH PAM is enabled", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure SSH PAM is enabled", "status": "failed", "recommendation": "Set UsePAM yes in /etc/ssh/sshd_config."}'
    fi
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson ssh_installed "$(check_ssh_installed)" \
    --argjson sshd_config "$(check_sshd_config_permissions)" \
    --argjson ssh_root_login "$(check_ssh_root_login)" \
    --argjson ssh_pam "$(check_ssh_pam_enabled)" \
    '{ "ssh_server_audit": [
        $ssh_installed,
        $sshd_config,
        $ssh_root_login,
        $ssh_pam
    ] }')

# Save report
echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "SSH Server audit saved to $REPORT_FILE"
