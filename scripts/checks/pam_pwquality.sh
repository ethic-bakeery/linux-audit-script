#!/bin/bash

# Define report file
REPORT_FILE="reports/pam_pwquality_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check PAM settings
check_pam_setting() {
    local setting=$1
    local description=$2
    local status="failed"
    local recommendation="Configure '$setting' in /etc/security/pwquality.conf."

    if grep -q "^$setting" /etc/security/pwquality.conf 2>/dev/null; then
        status="passed"
        recommendation=""
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output
JSON_OUTPUT=$(jq -n \
    --argjson pwquality "$(check_pam_setting "minlen" "Ensure password is at least 15 characters")" \
    --argjson upper "$(check_pam_setting "ucredit=-1" "Ensure password includes at least one upper-case character")" \
    --argjson lower "$(check_pam_setting "lcredit=-1" "Ensure password includes at least one lower-case character")" \
    --argjson number "$(check_pam_setting "dcredit=-1" "Ensure password includes at least one numeric character")" \
    --argjson special "$(check_pam_setting "ocredit=-1" "Ensure password includes at least one special character")" \
    --argjson changed_chars "$(check_pam_setting "difok=8" "Ensure change of at least 8 characters when passwords are changed")" \
    --argjson consecutive_chars "$(check_pam_setting "maxrepeat=3" "Ensure maximum number of same consecutive characters in a password is configured")" \
    --argjson dictionary_words "$(check_pam_setting "dictcheck=1" "Ensure preventing the use of dictionary words for passwords is configured")" \
    '{ "pam_pwquality_audit": [
        $pwquality,
        $upper,
        $lower,
        $number,
        $special,
        $changed_chars,
        $consecutive_chars,
        $dictionary_words
    ] }')

echo "$JSON_OUTPUT" > "$REPORT_FILE"
echo "PAM pwquality audit saved to $REPORT_FILE"
