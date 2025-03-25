#!/bin/bash

# Define report file
REPORT_FILE="reports/privilege_escalation_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if sudo is installed
check_sudo_installed() {
    if command -v sudo >/dev/null 2>&1; then
        echo '{"check": "Ensure sudo is installed", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure sudo is installed", "status": "failed", "recommendation": "Install sudo using apt, yum, or dnf."}'
    fi
}

# Function to check if sudo commands use a PTY
check_sudo_pty() {
    if grep -q "^Defaults.*requiretty" /etc/sudoers; then
        echo '{"check": "Ensure sudo commands use pty", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure sudo commands use pty", "status": "failed", "recommendation": "Add Defaults requiretty to /etc/sudoers."}'
    fi
}

# Function to check if sudo log file exists
check_sudo_log() {
    if grep -q "^Defaults.*logfile=" /etc/sudoers; then
        echo '{"check": "Ensure sudo log file exists", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure sudo log file exists", "status": "failed", "recommendation": "Configure sudo logging in /etc/sudoers with Defaults logfile=/var/log/sudo.log."}'
    fi
}

# Function to check if password is required for sudo
check_sudo_password_required() {
    if ! grep -q "NOPASSWD" /etc/sudoers /etc/sudoers.d/* 2>/dev/null; then
        echo '{"check": "Ensure users must provide password for privilege escalation", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure users must provide password for privilege escalation", "status": "failed", "recommendation": "Remove NOPASSWD from /etc/sudoers and /etc/sudoers.d/*."}'
    fi
}

# Function to check sudo authentication timeout
check_sudo_timeout() {
    if grep -q "^Defaults.*timestamp_timeout=[0-9]" /etc/sudoers; then
        echo '{"check": "Ensure sudo authentication timeout is configured correctly", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure sudo authentication timeout is configured correctly", "status": "failed", "recommendation": "Set Defaults timestamp_timeout=<value> in /etc/sudoers."}'
    fi
}

# Function to check if su command is restricted
check_su_restricted() {
    if [ -f /etc/pam.d/su ] && grep -q "auth required pam_wheel.so" /etc/pam.d/su; then
        echo '{"check": "Ensure access to the su command is restricted", "status": "passed", "recommendation": ""}'
    else
        echo '{"check": "Ensure access to the su command is restricted", "status": "failed", "recommendation": "Ensure su access is restricted to wheel group using pam_wheel.so."}'
    fi
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson sudo_installed "$(check_sudo_installed)" \
    --argjson sudo_pty "$(check_sudo_pty)" \
    --argjson sudo_log "$(check_sudo_log)" \
    --argjson sudo_password "$(check_sudo_password_required)" \
    --argjson sudo_timeout "$(check_sudo_timeout)" \
    --argjson su_restricted "$(check_su_restricted)" \
    '{ "privilege_escalation_audit": [
        $sudo_installed,
        $sudo_pty,
        $sudo_log,
        $sudo_password,
        $sudo_timeout,
        $su_restricted
    ] }')

echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "Privilege Escalation audit saved to $REPORT_FILE"
