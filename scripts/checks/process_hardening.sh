#!/bin/bash

# Define the report file
REPORT_FILE="./reports/process_hardening_audit.json"

# Ensure reports directory exists
mkdir -p ./reports

# Initialize JSON report
echo "{" > "$REPORT_FILE"
echo '  "audit_results": [' >> "$REPORT_FILE"

# Function to append JSON results
append_json() {
    local check_name="$1"
    local status="$2"
    local recommendation="$3"

    json_entry='{
        "check_name": "'"$check_name"'",
        "status": "'"$status"'"
    }'

    # Add recommendation if the check failed
    if [[ "$status" == "Failed" ]]; then
        json_entry=$(echo "$json_entry" | sed 's/}$/,"recommendation": "'"$recommendation"'"}/')
    fi

    # Append to report
    echo "    $json_entry," >> "$REPORT_FILE"
}

# Check if ASLR is enabled
check_aslr() {
    if [[ "$(cat /proc/sys/kernel/randomize_va_space)" -eq 2 ]]; then
        append_json "Ensure ASLR is enabled" "Passed" ""
    else
        append_json "Ensure ASLR is enabled" "Failed" "Enable ASLR by running: sysctl -w kernel.randomize_va_space=2"
    fi
}

# Check if ptrace_scope is restricted
check_ptrace_scope() {
    if [[ "$(cat /proc/sys/kernel/yama/ptrace_scope)" -ge 1 ]]; then
        append_json "Ensure ptrace_scope is restricted" "Passed" ""
    else
        append_json "Ensure ptrace_scope is restricted" "Failed" "Restrict ptrace by running: sysctl -w kernel.yama.ptrace_scope=1"
    fi
}

# Check if prelink is installed
check_prelink() {
    if ! command -v prelink &> /dev/null; then
        append_json "Ensure prelink is not installed" "Passed" ""
    else
        append_json "Ensure prelink is not installed" "Failed" "Remove prelink using: apt remove prelink or yum remove prelink"
    fi
}

# Check if maxlogins is 10 or less
check_maxlogins() {
    if grep -qE "^\*.*maxlogins=[0-9]+" /etc/security/limits.conf && awk '$2 == "maxlogins" { if ($3 <= 10) exit 0; else exit 1 }' /etc/security/limits.conf; then
        append_json "Ensure maxlogins is 10 or less" "Passed" ""
    else
        append_json "Ensure maxlogins is 10 or less" "Failed" "Set maxlogins in /etc/security/limits.conf to 10 or less"
    fi
}

# Check if automatic error reporting is disabled
check_auto_error_reporting() {
    if systemctl is-active --quiet apport || systemctl is-active --quiet abrt; then
        append_json "Ensure automatic error reporting is disabled" "Failed" "Disable error reporting using: systemctl disable apport && systemctl stop apport"
    else
        append_json "Ensure automatic error reporting is disabled" "Passed" ""
    fi
}

# Check if kdump service is disabled
check_kdump() {
    if systemctl is-enabled --quiet kdump; then
        append_json "Ensure kdump service is disabled" "Failed" "Disable kdump using: systemctl disable kdump"
    else
        append_json "Ensure kdump service is disabled" "Passed" ""
    fi
}

# Check if core dumps are restricted
check_core_dumps() {
    if grep -q "fs.suid_dumpable=0" /etc/sysctl.conf; then
        append_json "Ensure core dumps are restricted" "Passed" ""
    else
        append_json "Ensure core dumps are restricted" "Failed" "Add 'fs.suid_dumpable=0' to /etc/sysctl.conf and run: sysctl -p"
    fi
}

# Check if Ctrl-Alt-Delete is disabled
check_ctrl_alt_del() {
    if systemctl status ctrl-alt-del.target &>/dev/null; then
        append_json "Ensure Ctrl-Alt-Delete is disabled" "Failed" "Disable Ctrl-Alt-Delete using: ln -sf /dev/null /etc/systemd/system/ctrl-alt-del.target"
    else
        append_json "Ensure Ctrl-Alt-Delete is disabled" "Passed" ""
    fi
}

# Check if dmesg_restrict is enabled
check_dmesg_restrict() {
    if [[ "$(cat /proc/sys/kernel/dmesg_restrict)" -eq 1 ]]; then
        append_json "Ensure dmesg_restrict is enabled" "Passed" ""
    else
        append_json "Ensure dmesg_restrict is enabled" "Failed" "Enable dmesg restriction using: sysctl -w kernel.dmesg_restrict=1"
    fi
}

# Run all checks
check_aslr
check_ptrace_scope
check_prelink
check_maxlogins
check_auto_error_reporting
check_kdump
check_core_dumps
check_ctrl_alt_del
check_dmesg_restrict

# Remove trailing comma and close JSON array
sed -i '$ s/,$//' "$REPORT_FILE"
echo "  ]" >> "$REPORT_FILE"
echo "}" >> "$REPORT_FILE"

echo "Process Hardening Audit Completed. Results saved in $REPORT_FILE"
