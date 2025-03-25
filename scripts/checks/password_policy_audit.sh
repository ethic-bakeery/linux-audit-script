#!/bin/bash

# Define report file location
REPORT_FILE="reports/password_policy_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check password reuse limit
check_password_reuse() {
    local status="passed"
    local recommendation=""

    if ! grep -q "remember=" /etc/security/pwquality.conf; then
        status="failed"
        recommendation="Set password reuse limit by adding 'remember=5' to /etc/security/pwquality.conf."
    fi

    echo "{\"check\": \"Ensure password reuse is limited\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check lockout for failed password attempts
check_failed_password_lockout() {
    local status="passed"
    local recommendation=""
    
    if [ -f /etc/security/faillock.conf ]; then
        if ! grep -q "^deny =" /etc/security/faillock.conf; then
            status="failed"
            recommendation="Set lockout for failed attempts by adding 'deny = 3' to /etc/security/faillock.conf."
        fi
    else
        status="failed"
        recommendation="The file /etc/security/faillock.conf is missing. Configure 'pam_faillock' in PAM settings."
    fi

    echo "{\"check\": \"Ensure lockout for failed password attempts is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check strong password hashing algorithm
check_password_hashing() {
    local status="passed"
    local recommendation=""

    if ! grep -q "^password.*pam_unix.so.*sha512" /etc/pam.d/common-password; then
        status="failed"
        recommendation="Ensure strong password hashing using 'password required pam_unix.so sha512' in /etc/pam.d/common-password."
    fi

    echo "{\"check\": \"Ensure strong password hashing algorithm is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure PAM modules do not include 'nullok'
check_pam_nullok() {
    local status="passed"
    local recommendation=""

    if grep -q "nullok" /etc/pam.d/common-password; then
        status="failed"
        recommendation="Remove 'nullok' from /etc/pam.d/common-password to prevent empty passwords."
    fi

    echo "{\"check\": \"Ensure pam modules do not include nullok\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Ensure PAM prohibits cached authentications after one day
check_pam_cache_expiry() {
    local status="passed"
    local recommendation=""

    if ! grep -q "cache_timeout = 86400" /etc/security/faillock.conf; then
        status="failed"
        recommendation="Ensure cached authentication expires after one day by setting 'cache_timeout = 86400' in /etc/security/faillock.conf."
    fi

    echo "{\"check\": \"Ensure PAM prohibits the use of cached authentications after one day\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Run all checks and generate JSON output
JSON_OUTPUT=$(cat <<EOF
{
  "password_policy_audit": [
    $(check_password_reuse),
    $(check_failed_password_lockout),
    $(check_password_hashing),
    $(check_pam_nullok),
    $(check_pam_cache_expiry)
  ]
}
EOF
)

# Save JSON output to file
echo "{ \"generated_on\": \"$(date -Iseconds)\", \"audit_results\": $JSON_OUTPUT }" > "$REPORT_FILE"

echo "Password Policy audit results saved to $REPORT_FILE"
