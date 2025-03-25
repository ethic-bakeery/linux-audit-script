#!/bin/bash

# Define report file location
REPORT_FILE="reports/logging_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if a package is installed
check_package_installed() {
    dpkg -l | grep -q "$1" && echo "installed" || echo "not installed"
}

# Function to check if a service is enabled
check_service_enabled() {
    systemctl is-enabled "$1" &>/dev/null && echo "enabled" || echo "disabled"
}

# Function to check if journald is receiving logs from remote clients
check_journald_remote_receiving() {
    local status="passed"
    local recommendation=""

    if grep -qE "^\s*ForwardToSyslog\s*=\s*yes" /etc/systemd/journald.conf; then
        status="failed"
        recommendation="Disable remote log reception by setting ForwardToSyslog=no in /etc/systemd/journald.conf."
    fi

    echo "{\"check\": \"Ensure journald is not configured to receive logs from a remote client\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if journald compresses logs
check_journald_compression() {
    local status="passed"
    local recommendation=""

    if ! grep -qE "^\s*Compress\s*=\s*yes" /etc/systemd/journald.conf; then
        status="failed"
        recommendation="Enable log compression by adding 'Compress=yes' in /etc/systemd/journald.conf."
    fi

    echo "{\"check\": \"Ensure journald is configured to compress large log files\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if journald writes logs to persistent storage
check_journald_persistent_storage() {
    local status="passed"
    local recommendation=""

    if ! grep -qE "^\s*Storage\s*=\s*persistent" /etc/systemd/journald.conf; then
        status="failed"
        recommendation="Ensure journald writes logs to persistent storage by setting 'Storage=persistent' in /etc/systemd/journald.conf."
    fi

    echo "{\"check\": \"Ensure journald is configured to write logfiles to persistent disk\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "logging_audit": [
    { "check": "Ensure systemd-journal-remote is installed", "status": "$(check_package_installed systemd-journal-remote)" },
    { "check": "Ensure journald service is enabled", "status": "$(check_service_enabled systemd-journald)" },
    $(check_journald_remote_receiving),
    $(check_journald_compression),
    $(check_journald_persistent_storage),
    { "check": "Ensure systemd-journal-remote is configured", "status": "manual", "recommendation": "Verify systemd-journal-remote configuration in /etc/systemd/journal-remote.conf." },
    { "check": "Ensure systemd-journal-remote is enabled", "status": "manual", "recommendation": "Check if systemd-journal-remote is enabled using systemctl." },
    { "check": "Ensure journald is not configured to send logs to rsyslog", "status": "manual", "recommendation": "Verify ForwardToSyslog setting in /etc/systemd/journald.conf." },
    { "check": "Ensure journald log rotation is configured per site policy", "status": "manual", "recommendation": "Ensure log rotation settings in /etc/systemd/journald.conf follow site requirements." },
    { "check": "Ensure journald default file permissions are configured", "status": "manual", "recommendation": "Review /etc/systemd/journald.conf and set appropriate file permissions." }
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Logging and journald audit results saved to $REPORT_FILE"
