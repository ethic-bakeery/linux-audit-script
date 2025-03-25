#!/bin/bash

# Define report file location
REPORT_FILE="reports/cli_warning_banners_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to escape JSON strings
escape_json() {
    echo "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\//\\\//g' -e 's/\n/\\n/g'
}

# Check if the message of the day (MOTD) is configured properly
check_motd_config() {
    local status="passed"
    local recommendation=""

    if [ ! -s /etc/motd ]; then
        status="failed"
        recommendation="Configure /etc/motd with an appropriate message using 'echo \"Your Warning Message\" | sudo tee /etc/motd'."
    fi

    echo "{\"check\": \"Ensure message of the day is configured properly\", \"status\": \"$status\", \"recommendation\": \"$(escape_json "$recommendation")\"}"
}

# Check if the local login warning banner is configured properly
check_local_login_banner() {
    local status="passed"
    local recommendation=""

    if [ ! -s /etc/issue ]; then
        status="failed"
        recommendation="Set a local login banner using 'echo \"Authorized access only.\" | sudo tee /etc/issue'."
    fi

    echo "{\"check\": \"Ensure local login warning banner is configured properly\", \"status\": \"$status\", \"recommendation\": \"$(escape_json "$recommendation")\"}"
}

# Check if the remote login warning banner is configured properly
check_remote_login_banner() {
    local status="passed"
    local recommendation=""

    if [ ! -s /etc/issue.net ]; then
        status="failed"
        recommendation="Set a remote login banner using 'echo \"Remote access is monitored.\" | sudo tee /etc/issue.net'."
    fi

    echo "{\"check\": \"Ensure remote login warning banner is configured properly\", \"status\": \"$status\", \"recommendation\": \"$(escape_json "$recommendation")\"}"
}

# Check permissions on /etc/motd
check_motd_permissions() {
    local status="passed"
    local recommendation=""

    if [ -f /etc/motd ]; then
        local perms=$(stat -c "%a" /etc/motd)
        if [[ "$perms" -gt 644 ]]; then
            status="failed"
            recommendation="Set permissions using 'sudo chmod 644 /etc/motd'."
        fi
    else
        status="failed"
        recommendation="/etc/motd file not found."
    fi

    echo "{\"check\": \"Ensure permissions on /etc/motd are configured\", \"status\": \"$status\", \"recommendation\": \"$(escape_json "$recommendation")\"}"
}

# Check permissions on /etc/issue
check_issue_permissions() {
    local status="passed"
    local recommendation=""

    if [ -f /etc/issue ]; then
        local perms=$(stat -c "%a" /etc/issue)
        if [[ "$perms" -gt 644 ]]; then
            status="failed"
            recommendation="Set permissions using 'sudo chmod 644 /etc/issue'."
        fi
    else
        status="failed"
        recommendation="/etc/issue file not found."
    fi

    echo "{\"check\": \"Ensure permissions on /etc/issue are configured\", \"status\": \"$status\", \"recommendation\": \"$(escape_json "$recommendation")\"}"
}

# Check permissions on /etc/issue.net
check_issue_net_permissions() {
    local status="passed"
    local recommendation=""

    if [ -f /etc/issue.net ]; then
        local perms=$(stat -c "%a" /etc/issue.net)
        if [[ "$perms" -gt 644 ]]; then
            status="failed"
            recommendation="Set permissions using 'sudo chmod 644 /etc/issue.net'."
        fi
    else
        status="failed"
        recommendation="/etc/issue.net file not found."
    fi

    echo "{\"check\": \"Ensure permissions on /etc/issue.net are configured\", \"status\": \"$status\", \"recommendation\": \"$(escape_json "$recommendation")\"}"
}

# Generate JSON data for CLI warning banners
JSON_OUTPUT=$(jq -n \
    --argjson motd "$(check_motd_config)" \
    --argjson local_login "$(check_local_login_banner)" \
    --argjson remote_login "$(check_remote_login_banner)" \
    --argjson motd_perms "$(check_motd_permissions)" \
    --argjson issue_perms "$(check_issue_permissions)" \
    --argjson issue_net_perms "$(check_issue_net_permissions)" \
    '{ "cli_warning_banners": [$motd, $local_login, $remote_login, $motd_perms, $issue_perms, $issue_net_perms] }')

# Append results to existing report or create a new one
if [ -f "$REPORT_FILE" ]; then
    jq ".audit_results += $JSON_OUTPUT" "$REPORT_FILE" > tmp.json && mv tmp.json "$REPORT_FILE"
else
    jq -n --argjson audit_results "$JSON_OUTPUT" '{ "generated_on": now | todate, "audit_results": $audit_results }' > "$REPORT_FILE"
fi

echo "CLI Warning Banners audit results saved to $REPORT_FILE"