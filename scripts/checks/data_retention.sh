#!/bin/bash

# Define report file location
REPORT_FILE="reports/data_retention_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check audit log storage size configuration
check_audit_log_storage_size() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^max_log_file =" /etc/audit/auditd.conf; then
        status="failed"
        recommendation="Edit /etc/audit/auditd.conf and set 'max_log_file = 100' (or another appropriate size), then restart auditd."
    fi

    echo "{\"check\": \"Ensure audit log storage size is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check audit logs are not automatically deleted
check_audit_log_deletion() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^max_log_file_action = keep_logs" /etc/audit/auditd.conf; then
        status="failed"
        recommendation="Edit /etc/audit/auditd.conf and set 'max_log_file_action = keep_logs', then restart auditd."
    fi

    echo "{\"check\": \"Ensure audit logs are not automatically deleted\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check system shutdown when audit logs are full
check_audit_shutdown_on_full() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^space_left_action = email" /etc/audit/auditd.conf || ! grep -q "^admin_space_left_action = halt" /etc/audit/auditd.conf; then
        status="failed"
        recommendation="Edit /etc/audit/auditd.conf and set 'space_left_action = email' and 'admin_space_left_action = halt', then restart auditd."
    fi

    echo "{\"check\": \"Ensure system is disabled when audit logs are full\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check shutdown upon audit failure
check_shutdown_on_audit_failure() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^disk_full_action = halt" /etc/audit/auditd.conf; then
        status="failed"
        recommendation="Edit /etc/audit/auditd.conf and set 'disk_full_action = halt', then restart auditd."
    fi

    echo "{\"check\": \"Ensure shut down by default upon audit failure\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check audit event multiplexor configuration
check_audit_event_multiplexor() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^dispatcher =" /etc/audit/auditd.conf; then
        status="failed"
        recommendation="Edit /etc/audit/auditd.conf and set 'dispatcher = /sbin/audispd', then restart auditd."
    fi

    echo "{\"check\": \"Ensure audit event multiplexor is configured to off-load audit logs\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "data_retention_audit": [
    $(check_audit_log_storage_size),
    $(check_audit_log_deletion),
    $(check_audit_shutdown_on_full),
    $(check_shutdown_on_audit_failure),
    $(check_audit_event_multiplexor)
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Data retention audit results saved to $REPORT_FILE"
