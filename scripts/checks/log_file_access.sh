#!/bin/bash

# Define report file location
REPORT_FILE="reports/log_file_access_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check file ownership
check_ownership() {
    local file="$1"
    local expected_owner="$2"
    local check_name="Ensure $file is owned by $expected_owner"
    local status="passed"
    local recommendation=""

    if [[ "$(stat -c %U "$file" 2>/dev/null)" != "$expected_owner" ]]; then
        status="failed"
        recommendation="Run: chown $expected_owner $file"
    fi

    echo "{\"check\": \"$check_name\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check group ownership
check_group_ownership() {
    local file="$1"
    local expected_group="$2"
    local check_name="Ensure $file is group-owned by $expected_group"
    local status="passed"
    local recommendation=""

    if [[ "$(stat -c %G "$file" 2>/dev/null)" != "$expected_group" ]]; then
        status="failed"
        recommendation="Run: chgrp $expected_group $file"
    fi

    echo "{\"check\": \"$check_name\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check file permissions
check_permissions() {
    local file="$1"
    local expected_perms="$2"
    local check_name="Ensure $file has mode $expected_perms or more restrictive"
    local status="passed"
    local recommendation=""

    local current_perms
    current_perms=$(stat -c %a "$file" 2>/dev/null)

    if [[ -z "$current_perms" || "$current_perms" -gt "$expected_perms" ]]; then
        status="failed"
        recommendation="Run: chmod $expected_perms $file"
    fi

    echo "{\"check\": \"$check_name\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check auditd installation
check_auditd_installed() {
    local status="passed"
    local recommendation=""

    if ! command -v auditctl &>/dev/null; then
        status="failed"
        recommendation="Run: apt install auditd -y (Debian/Ubuntu) or yum install audit -y (RHEL/CentOS)"
    fi

    echo "{\"check\": \"Ensure auditd is installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if auditd service is active
check_auditd_active() {
    local status="passed"
    local recommendation=""

    if ! systemctl is-active --quiet auditd; then
        status="failed"
        recommendation="Run: systemctl enable --now auditd"
    fi

    echo "{\"check\": \"Ensure auditd service is enabled and active\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if audit is enabled at boot
check_audit_at_boot() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^\s*GRUB_CMDLINE_LINUX=.*audit=1" /etc/default/grub; then
        status="failed"
        recommendation="Edit /etc/default/grub and add 'audit=1' to GRUB_CMDLINE_LINUX, then run: update-grub && reboot"
    fi

    echo "{\"check\": \"Ensure auditing for processes that start prior to auditd is enabled\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check audit backlog limit
check_audit_backlog_limit() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^\s*GRUB_CMDLINE_LINUX=.*audit_backlog_limit=" /etc/default/grub; then
        status="failed"
        recommendation="Edit /etc/default/grub and add 'audit_backlog_limit=8192' to GRUB_CMDLINE_LINUX, then run: update-grub && reboot"
    fi

    echo "{\"check\": \"Ensure audit_backlog_limit is sufficient\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "log_file_access_audit": [
    $(check_ownership /var/log root),
    $(check_group_ownership /var/log syslog),
    $(check_permissions /var/log 0755),
    $(check_ownership /var/log/syslog syslog),
    $(check_group_ownership /var/log/syslog adm),
    $(check_permissions /var/log/syslog 0640),
    $(check_auditd_installed),
    $(check_auditd_active),
    $(check_audit_at_boot),
    $(check_audit_backlog_limit)
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Log file access audit results saved to $REPORT_FILE"
