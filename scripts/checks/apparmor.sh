#!/bin/bash

REPORT_FILE="reports/apparmor_audit_report.json"

mkdir -p "$(dirname "$REPORT_FILE")"

check_apparmor_installed() {
    local status="passed"
    local recommendation="None"

    if ! dpkg-query -W -f='${Status}' apparmor 2>/dev/null | grep -q "installed"; then
        status="failed"
        recommendation="Install AppArmor using 'sudo apt install apparmor'."
    fi

    echo "      {\"check\": \"AppArmor Installed\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" },"
}

check_apparmor_enabled() {
    local status="passed"
    local recommendation="None"

    if ! grep -q "apparmor=1 security=apparmor" /etc/default/grub; then
        status="failed"
        recommendation="Add 'apparmor=1 security=apparmor' to GRUB_CMDLINE_LINUX in /etc/default/grub and run 'sudo update-grub'."
    fi

    echo "      {\"check\": \"AppArmor Enabled in Bootloader\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" },"
}

check_apparmor_profiles() {
    local status="passed"
    local recommendation="None"

    if sudo aa-status | grep -q "0 processes are in enforce mode"; then
        status="failed"
        recommendation="Enable AppArmor profiles using 'sudo aa-enforce /etc/apparmor.d/*'."
    fi

    echo "      {\"check\": \"AppArmor Profiles Enforcing\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" }"
}

init_report() {
    echo "{" > "$REPORT_FILE"
    echo "  \"generated_on\": \"$(date)\"," >> "$REPORT_FILE"
    echo "  \"audit_results\": {" >> "$REPORT_FILE"
    echo "    \"mandatory_access_control\": [" >> "$REPORT_FILE"
}

finalize_report() {
    echo "    ]" >> "$REPORT_FILE"
    echo "  }" >> "$REPORT_FILE"
    echo "}" >> "$REPORT_FILE"
    echo "Audit complete. Report saved to $REPORT_FILE"
}

run_audit() {
    init_report
    check_apparmor_installed >> "$REPORT_FILE"
    check_apparmor_enabled >> "$REPORT_FILE"
    check_apparmor_profiles >> "$REPORT_FILE"
    finalize_report
}

run_audit
