#!/bin/bash

# Define the report file
REPORT_FILE="reports/auditd_file_access.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check file permissions
check_permissions() {
    local file_path="$1"
    local expected_mode="$2"
    local description="$3"
    local status="passed"
    local recommendation=""

    if [[ ! -e "$file_path" ]]; then
        status="failed"
        recommendation="File $file_path does not exist. Ensure auditd is installed and configured."
    else
        actual_mode=$(stat -c "%a" "$file_path")
        if (( actual_mode > expected_mode )); then
            status="failed"
            recommendation="Set permissions using: chmod $expected_mode $file_path"
        fi
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check ownership
check_ownership() {
    local file_path="$1"
    local expected_owner="$2"
    local description="$3"
    local status="passed"
    local recommendation=""

    if [[ ! -e "$file_path" ]]; then
        status="failed"
        recommendation="File $file_path does not exist. Ensure auditd is installed and configured."
    else
        actual_owner=$(stat -c "%U" "$file_path")
        if [[ "$actual_owner" != "$expected_owner" ]]; then
            status="failed"
            recommendation="Change owner using: chown $expected_owner $file_path"
        fi
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check group ownership
check_group_ownership() {
    local file_path="$1"
    local expected_group="$2"
    local description="$3"
    local status="passed"
    local recommendation=""

    if [[ ! -e "$file_path" ]]; then
        status="failed"
        recommendation="File $file_path does not exist. Ensure auditd is installed and configured."
    else
        actual_group=$(stat -c "%G" "$file_path")
        if [[ "$actual_group" != "$expected_group" ]]; then
            status="failed"
            recommendation="Change group using: chgrp $expected_group $file_path"
        fi
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "auditd_file_access": [
    $(check_permissions "/var/log/audit" 750 "Ensure audit log directory is 0750 or more restrictive"),
    $(check_permissions "/var/log/audit/audit.log" 640 "Ensure audit log files are mode 0640 or more restrictive"),
    $(check_permissions "/var/log/audit/audit.log" 600 "Ensure audit log files are mode 0600 or more restrictive"),
    $(check_ownership "/var/log/audit/audit.log" "root" "Ensure only authorized users own audit log files"),
    $(check_group_ownership "/var/log/audit/audit.log" "root" "Ensure only authorized groups own audit log files"),
    $(check_permissions "/etc/audit/auditd.conf" 640 "Ensure audit configuration files are 640 or more restrictive"),
    $(check_ownership "/etc/audit/auditd.conf" "root" "Ensure only authorized users own audit configuration files"),
    $(check_group_ownership "/etc/audit/auditd.conf" "root" "Ensure only authorized groups own audit configuration files"),
    $(check_permissions "/sbin/auditctl" 755 "Ensure audit tools are 755 or more restrictive"),
    $(check_ownership "/sbin/auditctl" "root" "Ensure only authorized users own audit tools"),
    $(check_group_ownership "/sbin/auditctl" "root" "Ensure only authorized groups own audit tools")
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Auditd file access audit results saved to $REPORT_FILE"
