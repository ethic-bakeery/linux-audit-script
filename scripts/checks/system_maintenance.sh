#!/bin/bash

# Define the report file
REPORT_FILE="reports/system_maintenance_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check file permissions
check_permissions() {
    local file_path="$1"
    local expected_perm="$2"
    local description="$3"
    local status="passed"
    local recommendation=""

    if [[ ! -e "$file_path" ]]; then
        status="failed"
        recommendation="File $file_path does not exist. Investigate missing system files."
    elif [[ "$(stat -c "%a" "$file_path")" -gt "$expected_perm" ]]; then
        status="failed"
        recommendation="Set correct permissions using: chmod $expected_perm $file_path"
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if files are owned by root
check_ownership() {
    local file_path="$1"
    local description="$2"
    local status="passed"
    local recommendation=""

    if [[ ! -e "$file_path" ]]; then
        status="failed"
        recommendation="File $file_path does not exist. Investigate missing system files."
    elif [[ "$(stat -c "%U" "$file_path")" != "root" ]]; then
        status="failed"
        recommendation="Set correct ownership using: chown root:root $file_path"
    fi

    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "system_maintenance": [
    $(check_permissions "/etc/passwd" "644" "Ensure permissions on /etc/passwd are configured"),
    $(check_permissions "/etc/passwd-" "600" "Ensure permissions on /etc/passwd- are configured"),
    $(check_permissions "/etc/group" "644" "Ensure permissions on /etc/group are configured"),
    $(check_permissions "/etc/group-" "600" "Ensure permissions on /etc/group- are configured"),
    $(check_permissions "/etc/shadow" "600" "Ensure permissions on /etc/shadow are configured"),
    $(check_permissions "/etc/shadow-" "600" "Ensure permissions on /etc/shadow- are configured"),
    $(check_permissions "/etc/gshadow" "600" "Ensure permissions on /etc/gshadow are configured"),
    $(check_permissions "/etc/gshadow-" "600" "Ensure permissions on /etc/gshadow- are configured"),
    $(check_permissions "/etc/shells" "644" "Ensure permissions on /etc/shells are configured"),
    $(check_permissions "/etc/opasswd" "600" "Ensure permissions on /etc/opasswd are configured"),
    {
      "check": "Ensure world writable files and directories are secured",
      "status": "manual",
      "recommendation": "Manually review world writable files using: find / -xdev -type d -perm -0002"
    },
    {
      "check": "Ensure no unowned or ungrouped files or directories exist",
      "status": "manual",
      "recommendation": "Find and fix unowned files using: find / -xdev \( -nouser -o -nogroup \)"
    },
    {
      "check": "Ensure SUID and SGID files are reviewed",
      "status": "manual",
      "recommendation": "Review SUID/SGID files using: find / -xdev -type f \( -perm -4000 -o -perm -2000 \)"
    },
    $(check_ownership "/usr/bin" "Ensure system command files are owned by root"),
    $(check_ownership "/usr/lib" "Ensure system library directories are owned by root"),
    $(check_ownership "/usr/lib64" "Ensure system library files are owned by root"),
    $(check_permissions "/usr/bin" "755" "Ensure directories that contain system commands are 0755 or more restrictive"),
    $(check_permissions "/usr/lib" "755" "Ensure system library directories are 0755 or more restrictive"),
    $(check_permissions "/usr/lib64" "755" "Ensure system library files are 0755 or more restrictive")
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "System maintenance audit results saved to $REPORT_FILE"
