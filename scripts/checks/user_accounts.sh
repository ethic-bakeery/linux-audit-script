#!/bin/bash

# Define report file location
REPORT_FILE="reports/user_accounts_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check password policy settings in /etc/login.defs
check_login_def() {
    local setting="$1"
    local expected="$2"
    local status="passed"
    local recommendation=""

    local value
    value=$(grep -E "^\s*$setting\s+" /etc/login.defs | awk '{print $2}')

    if [[ -z "$value" || "$value" -gt "$expected" ]]; then
        status="failed"
        recommendation="Set $setting to $expected or lower in /etc/login.defs."
    fi

    echo "{\"check\": \"Ensure $setting is $expected or less\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if root account is locked
check_root_locked() {
    local status="passed"
    local recommendation=""

    if ! passwd -S root | grep -q "L"; then
        status="failed"
        recommendation="Lock the root account using: passwd -l root"
    fi

    echo "{\"check\": \"Ensure root account is locked\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if SHA512 is used for password hashing
check_password_hashing() {
    local status="passed"
    local recommendation=""

    if ! grep -qE "^ENCRYPT_METHOD\s+SHA512" /etc/login.defs; then
        status="failed"
        recommendation="Set ENCRYPT_METHOD to SHA512 in /etc/login.defs."
    fi

    echo "{\"check\": \"Ensure ENCRYPT_METHOD is SHA512\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check user umask settings
check_umask() {
    local setting="$1"
    local expected="$2"
    local status="passed"
    local recommendation=""

    local value
    value=$(grep -E "^\s*$setting\s+" /etc/profile /etc/bash.bashrc 2>/dev/null | awk '{print $2}' | tail -1)

    if [[ -z "$value" || "$value" -gt "$expected" ]]; then
        status="failed"
        recommendation="Set $setting to $expected or lower in /etc/profile and /etc/bash.bashrc."
    fi

    echo "{\"check\": \"Ensure $setting is $expected or more restrictive\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if default shell timeout is configured
check_shell_timeout() {
    local status="passed"
    local recommendation=""

    if ! grep -qE "^\s*TMOUT\s*=\s*[0-9]+" /etc/profile /etc/bash.bashrc; then
        status="failed"
        recommendation="Set TMOUT to 600 seconds or less in /etc/profile or /etc/bash.bashrc."
    fi

    echo "{\"check\": \"Ensure default user shell timeout is 600 seconds or less\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if /etc/shells contains nologin
check_nologin_in_shells() {
    local status="passed"
    local recommendation=""

    if grep -q "/nologin" /etc/shells; then
        status="failed"
        recommendation="Remove nologin from /etc/shells to ensure proper login behavior."
    fi

    echo "{\"check\": \"Ensure nologin is not listed in /etc/shells\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check system accounts
check_system_accounts() {
    local status="passed"
    local recommendation=""

    if awk -F: '$3 < 1000 { print $1 }' /etc/passwd | grep -vE '^(root|sync|shutdown|halt)$' &>/dev/null; then
        status="failed"
        recommendation="Disable unnecessary system accounts."
    fi

    echo "{\"check\": \"Ensure system accounts are secured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if root's default group is GID 0
check_root_gid() {
    local status="passed"
    local recommendation=""

    if [[ "$(id -g root)" != "0" ]]; then
        status="failed"
        recommendation="Ensure root's default group is GID 0 using: usermod -g 0 root."
    fi

    echo "{\"check\": \"Ensure default group for the root account is GID 0\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "user_accounts_audit": [
    $(check_login_def PASS_MIN_DAYS 1),
    $(check_login_def PASS_MAX_DAYS 60),
    $(check_login_def PASS_WARN_AGE 7),
    $(check_login_def INACTIVE 30),
    $(check_password_hashing),
    $(check_root_locked),
    $(check_system_accounts),
    $(check_root_gid),
    $(check_umask UMASK 027),
    $(check_umask UMASK 077),
    $(check_shell_timeout),
    $(check_nologin_in_shells),
    { "check": "Ensure temporary accounts expiration time of 72 hours or less", "status": "manual", "recommendation": "Verify temporary accounts expire in 72 hours or less." },
    { "check": "Ensure emergency accounts are removed or disabled after 72 hours", "status": "manual", "recommendation": "Manually ensure emergency accounts do not exist beyond 72 hours." },
    { "check": "Ensure immediate change to a permanent password", "status": "manual", "recommendation": "Ensure temporary passwords are changed immediately to a permanent one." },
    { "check": "Ensure /etc/ssl/certs only contains authorized certificates", "status": "manual", "recommendation": "Verify /etc/ssl/certs contains only DoD PKI-authorized certificates." }
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "User accounts and environment audit results saved to $REPORT_FILE"
