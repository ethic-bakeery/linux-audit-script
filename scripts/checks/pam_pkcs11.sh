#!/bin/bash

# Define report file location
REPORT_FILE="reports/pam_pkcs11_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if a package is installed
check_package_installed() {
    dpkg -l | grep -q "$1" && echo "installed" || echo "not installed"
}

# Function to check if pam_pkcs11.conf exists
check_pam_pkcs11_config() {
    local status="passed"
    local recommendation=""

    if [ ! -f /etc/pam_pkcs11/pam_pkcs11.conf ]; then
        status="failed"
        recommendation="Configuration file missing. If using smart card authentication, ensure /etc/pam_pkcs11/pam_pkcs11.conf is configured."
    fi

    echo "{\"check\": \"Ensure pam_pkcs11 configuration file exists\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check PKCS#11 related configurations
check_pkcs11_mappings() {
    local status="passed"
    local recommendation=""

    if [ -f /etc/pam_pkcs11/pam_pkcs11.conf ]; then
        grep -q "use_mappers" /etc/pam_pkcs11/pam_pkcs11.conf || {
            status="failed"
            recommendation="Ensure authenticated identity is mapped to a user/group in /etc/pam_pkcs11/pam_pkcs11.conf."
        }
    else
        status="skipped"
        recommendation="Configuration file missing."
    fi

    echo "{\"check\": \"Ensure PKCS#11 user/group mappings are configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Run checks and store results
JSON_OUTPUT=$(cat <<EOF
{
  "pam_pkcs11_audit": [
    { "check": "Ensure libpam-pkcs11 package is installed", "status": "$(check_package_installed libpam-pkcs11)" },
    { "check": "Ensure opensc-pkcs11 package is installed", "status": "$(check_package_installed opensc)" },
    $(check_pam_pkcs11_config),
    $(check_pkcs11_mappings)
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "PAM PKCS#11 audit results saved to $REPORT_FILE"
