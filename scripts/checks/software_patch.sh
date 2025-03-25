#!/bin/bash

# Report file location
REPORT_FILE="reports/software_patch_audit_report.json"

# Ensure the reports directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if APT requires verification before installation
check_apt_signature_verification() {
    local status="failed"
    local recommendation="Run 'echo Acquire::AllowUnauthenticated \"false\"; > /etc/apt/apt.conf.d/00secure' to enforce signature verification."
    
    if grep -q '^Acquire::AllowUnauthenticated "false";' /etc/apt/apt.conf.d/* 2>/dev/null; then
        status="passed"
        recommendation="None"
    fi
    
    jq -n \
        --arg check "Ensure APT requires a recognized digital signature before installation" \
        --arg status "$status" \
        --arg recommendation "$recommendation" \
        '{check: $check, status: $status, recommendation: $recommendation}'
}

# Function to check if APT removes outdated software components
check_apt_autoremove() {
    local status="failed"
    local recommendation="Run 'echo APT::Periodic::Autoremove \"1\"; > /etc/apt/apt.conf.d/10periodic' to enable automatic removal."
    
    if grep -q '^APT::Periodic::Autoremove "1";' /etc/apt/apt.conf.d/* 2>/dev/null; then
        status="passed"
        recommendation="None"
    fi
    
    jq -n \
        --arg check "Ensure APT removes outdated software components" \
        --arg status "$status" \
        --arg recommendation "$recommendation" \
        '{check: $check, status: $status, recommendation: $recommendation}'
}

# Generate JSON output without generated_on
JSON_OUTPUT=$(jq -n \
    --argjson apt_verification "$(check_apt_signature_verification)" \
    --argjson apt_autoremove "$(check_apt_autoremove)" \
    '{ "software_patch": [$apt_verification, $apt_autoremove] }')

# Save report (overwrite instead of appending)
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Software patch audit results saved in $REPORT_FILE"
