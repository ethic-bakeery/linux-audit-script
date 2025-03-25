#!/bin/bash

# Define report file location
REPORT_FILE="reports/rsyslog_audit.json"

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

# Function to check rsyslog file permissions
check_rsyslog_permissions() {
    local status="passed"
    local recommendation=""

    if grep -qE "^\$FileCreateMode\s+[0-7]{3}" /etc/rsyslog.conf; then
        permission=$(grep -E "^\$FileCreateMode\s+[0-7]{3}" /etc/rsyslog.conf | awk '{print $2}')
        if [[ "$permission" -gt 640 ]]; then
            status="failed"
            recommendation="Set \$FileCreateMode in /etc/rsyslog.conf to 0640 or more restrictive."
        fi
    else
        status="failed"
        recommendation="Add \$FileCreateMode 0640 to /etc/rsyslog.conf to enforce secure log file permissions."
    fi

    echo "{\"check\": \"Ensure rsyslog default file permissions are configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if rsyslog is receiving logs from remote clients
check_rsyslog_remote_receiving() {
    local status="passed"
    local recommendation=""

    if grep -qE "^\s*\$ModLoad\s+imtcp" /etc/rsyslog.conf || grep -qE "^\s*input\(type=\"imtcp\"" /etc/rsyslog.conf; then
        status="failed"
        recommendation="Disable remote log reception by removing imtcp module load lines from /etc/rsyslog.conf."
    fi

    echo "{\"check\": \"Ensure rsyslog is not configured to receive logs from a remote client\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if remote access methods are monitored
check_remote_access_monitoring() {
    local status="passed"
    local recommendation=""

    if ! grep -qE "(auth\.log|secure)" /etc/rsyslog.conf; then
        status="failed"
        recommendation="Ensure remote access logs (e.g., /var/log/auth.log) are monitored by rsyslog."
    fi

    echo "{\"check\": \"Ensure remote access methods are monitored\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "rsyslog_audit": [
    { "check": "Ensure rsyslog is installed", "status": "$(check_package_installed rsyslog)" },
    { "check": "Ensure rsyslog service is enabled", "status": "$(check_service_enabled rsyslog)" },
    $(check_rsyslog_permissions),
    $(check_rsyslog_remote_receiving),
    $(check_remote_access_monitoring),
    { "check": "Ensure journald is configured to send logs to rsyslog", "status": "manual", "recommendation": "Check /etc/systemd/journald.conf and set 'ForwardToSyslog=yes'." },
    { "check": "Ensure logging is configured", "status": "manual", "recommendation": "Review /etc/rsyslog.conf and ensure necessary logging rules are in place." },
    { "check": "Ensure rsyslog is configured to send logs to a remote log host", "status": "manual", "recommendation": "Verify if logs are forwarded to a remote syslog server via *.* @remote-host:514." }
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Rsyslog audit results saved to $REPORT_FILE"
