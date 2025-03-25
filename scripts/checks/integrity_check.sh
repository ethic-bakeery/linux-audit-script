#!/bin/bash

# Define the report file
REPORT_FILE="reports/aide_integrity_check.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if a package is installed
check_package_installed() {
    local package_name="$1"
    local description="$2"
    local status="passed"
    local recommendation=""

    if ! dpkg -s "$package_name" &>/dev/null; then
        status="failed"
        recommendation="Install $package_name using: apt install $package_name"
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if a cron job exists
check_cron_job() {
    local job_pattern="$1"
    local description="$2"
    local status="passed"
    local recommendation=""

    if ! crontab -l 2>/dev/null | grep -q "$job_pattern"; then
        status="failed"
        recommendation="integrity check using: (echo '0 5 * * * /usr/sbin/aide --check') | crontab -"
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if aide.conf is protected by cryptographic mechanisms
check_crypto_protection() {
    local file_path="/etc/aide/aide.conf"
    local description="Use cryptography to protect tool integrity."
    local status="passed"
    local recommendation=""

    if [[ ! -e "$file_path" ]]; then
        status="failed"
        recommendation="Ensure AIDE is installed and configured properly."
    elif ! grep -q "sha256" "$file_path"; then
        status="failed"
        recommendation="Add 'sha256' to /etc/aide/aide.conf for verification."
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "filesystem_integrity_checking": [
    $(check_package_installed "aide" "Ensure AIDE is installed"),
    {
      "check": "Set the AIDE script to check file integrity as default."
      "status": "manual",
      "recommendation": "Manually verify correct AIDE check script is set as default"
    },
    $(check_cron_job "aide --check" "Ensure filesystem integrity is checked"),
    $(check_cron_job "Run 'aide --check' to notify admins of anomalies."
    $(check_crypto_protection)
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Filesystem integrity audit results saved to $REPORT_FILE"
