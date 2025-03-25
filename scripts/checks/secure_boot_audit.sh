#!/bin/bash

# Define report file location
REPORT_FILE="reports/secure_boot_audit_report.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if bootloader password is set
check_bootloader_password() {
    local status="passed"
    local recommendation=""

    if ! grep -q "password_pbkdf2" /boot/grub*/grub.cfg 2>/dev/null; then
        status="failed"
        recommendation="Set a GRUB password using 'grub-mkpasswd-pbkdf2' and update /etc/grub.d/00_header."
    fi

    echo "{\"check\": \"Bootloader Password\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check bootloader config permissions
check_bootloader_permissions() {
    local status="passed"
    local recommendation=""
    local BOOTLOADER_FILE=$(ls /boot/grub*/grub.cfg 2>/dev/null)

    if [[ -f "$BOOTLOADER_FILE" ]]; then
        local PERMS=$(stat -c "%a" "$BOOTLOADER_FILE")
        if [[ "$PERMS" -gt 600 ]]; then
            status="failed"
            recommendation="Run 'chmod 600 $BOOTLOADER_FILE' to secure the bootloader config."
        fi
    else
        status="failed"
        recommendation="Bootloader configuration file not found."
    fi

    echo "{\"check\": \"Bootloader Config Permissions\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Check authentication for single-user mode
check_single_user_auth() {
    local status="passed"
    local recommendation=""

    if ! grep -q 'SULOGIN=yes' /etc/default/grub 2>/dev/null; then
        status="failed"
        recommendation="Add 'SULOGIN=yes' to /etc/default/grub and update GRUB using 'sudo update-grub'."
    fi

    echo "{\"check\": \"Single-User Mode Authentication\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON output without generated_on
JSON_OUTPUT=$(jq -n \
    --argjson boot_password "$(check_bootloader_password)" \
    --argjson boot_permissions "$(check_bootloader_permissions)" \
    --argjson single_user_auth "$(check_single_user_auth)" \
    '{ "secure_boot_settings": [$boot_password, $boot_permissions, $single_user_auth] }')

# Save report (overwrite instead of appending)
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Secure boot audit results saved to $REPORT_FILE"
