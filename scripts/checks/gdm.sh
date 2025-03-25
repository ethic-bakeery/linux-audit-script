#!/bin/bash

# Define report file location
REPORT_FILE="reports/gdm_security_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to run security checks
run_checks() {
    local checks=()

    # Check if GNOME Display Manager is removed
    check_gdm_removed() {
        local status="passed"
        local recommendation=""

        if dpkg -l | grep -q "gdm3"; then
            status="failed"
            recommendation="Remove GDM using 'sudo apt purge gdm3 -y'."
        fi

        checks+=("{\"check\": \"Ensure GNOME Display Manager is removed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}")
    }

    # Ensure GDM login banner is configured
    check_gdm_login_banner() {
        local status="passed"
        local recommendation=""

        if ! grep -q 'banner-message-enable=true' /etc/gdm3/custom.conf 2>/dev/null; then
            status="failed"
            recommendation="Set 'banner-message-enable=true' in /etc/gdm3/custom.conf."
        fi

        checks+=("{\"check\": \"Ensure GDM login banner is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}")
    }

    # Ensure GDM disable-user-list option is enabled
    check_gdm_disable_user_list() {
        local status="passed"
        local recommendation=""

        if ! grep -q 'disable-user-list=true' /etc/gdm3/custom.conf 2>/dev/null; then
            status="failed"
            recommendation="Set 'disable-user-list=true' in /etc/gdm3/custom.conf."
        fi

        checks+=("{\"check\": \"Ensure GDM disable-user-list option is enabled\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}")
    }

    # Run all checks
    check_gdm_removed
    check_gdm_login_banner
    check_gdm_disable_user_list

    # Save output as JSON array
    echo -e "{\n  \"gdm_security_audit\": [\n    $(IFS=,; echo "${checks[*]}")\n  ]\n}" > "$REPORT_FILE"
}

# Execute the function
run_checks

echo "Security audit completed. Report saved to $REPORT_FILE."
