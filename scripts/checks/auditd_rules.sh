# #!/bin/bash

# # Define auditd paths
# AUDITD_BIN="/sbin/auditctl"
# AUDIT_RULES_FILE="/etc/audit/rules.d/audit.rules"
# REPORT_FILE="reports/auditd_rules.json"

# # Check if auditd is installed
# if ! command -v auditctl &> /dev/null; then
#     echo "Error: auditd is not installed. Please install it using: sudo apt install auditd -y"
#     exit 1
# fi

# # Ensure the report directory exists
# mkdir -p "$(dirname "$REPORT_FILE")"

# # Check if audit rules file exists
# if [[ ! -f "$AUDIT_RULES_FILE" ]]; then
#     echo "Audit rules file missing! Auditd may not be configured."
#     echo "{\"error\": \"Auditd is installed but not configured.\"}" > "$REPORT_FILE"
#     exit 1
# fi

# # Function to check if a rule exists in the audit rules file
# check_audit_rule() {
#     local rule="$1"
#     local description="$2"
#     local status="passed"
#     local recommendation=""

#     if ! grep -qF -- "$rule" "$AUDIT_RULES_FILE"; then
#         status="failed"
#         recommendation="Add '$rule' to $AUDIT_RULES_FILE and restart auditd."
#     fi

#     echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
# }

# # Generate JSON report
# JSON_OUTPUT=$(cat <<EOF
# {
#   "auditd_rules": [
#     $(check_audit_rule "-w /etc/sudoers -p wa -k scope" "Ensure changes to /etc/sudoers are tracked."),
#     $(check_audit_rule "-w /var/log/sudo.log -p wa -k sudo_log" "Ensure sudo log changes are collected"),
#     $(check_audit_rule "-w /etc/localtime -p wa -k time-change" "Ensure time change events are collected"),
#     $(check_audit_rule "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm_mod" "Ensure permission modification events are collected"),
#     $(check_audit_rule "-a always,exit -F arch=b64 -S open -S openat -F exit=-EACCES -F auid>=1000 -k access" "Ensure unsuccessful file access attempts are collected"),
#     $(check_audit_rule "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete" "Ensure file deletion events are collected"),
#     $(check_audit_rule "-e 2" "Ensure audit configuration is immutable")
#   ]
# }
# EOF
# )

# # Save results to the report file
# echo "$JSON_OUTPUT" > "$REPORT_FILE"

# echo "Auditd rules audit results saved to $REPORT_FILE"

# # Restart auditd if it's installed
# if systemctl list-unit-files | grep -q "^auditd.service"; then
#     echo "Restarting auditd..."
#     systemctl restart auditd
#     echo "Auditd restarted."
# else
#     echo "Warning: auditd service is not available. Configuration changes may not take effect."
# fi

#!/bin/bash

# Define auditd paths
AUDITD_BIN="/sbin/auditctl"
AUDIT_RULES_FILE="/etc/audit/rules.d/audit.rules"
REPORT_FILE="reports/auditd_rules.json"

# Check if auditd is installed
if ! command -v auditctl &> /dev/null; then
    echo "Error: auditd is not installed. Please install it using: sudo apt install auditd -y"
    exit 1
fi

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Check if audit rules file exists
if [[ ! -f "$AUDIT_RULES_FILE" ]]; then
    echo "Audit rules file missing! Auditd may not be configured."
    echo '{"error": "Auditd is installed but not configured."}' > "$REPORT_FILE"
    exit 1
fi

# Function to check if a rule exists in the audit rules file
check_audit_rule() {
    local rule="$1"
    local description="$2"
    local status="passed"
    local recommendation=""

    if ! grep -qF -- "$rule" "$AUDIT_RULES_FILE"; then
        status="failed"
        recommendation="Add '$rule' to $AUDIT_RULES_FILE and restart auditd."
    fi

    # Ensure proper JSON formatting
    echo "{\"check\": \"$description\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report properly formatted
JSON_OUTPUT=$(jq -n --compact-output \
    --argjson rules "[$( 
        check_audit_rule "-w /etc/sudoers -p wa -k scope" "Ensure changes to /etc/sudoers are tracked.",
        check_audit_rule "-w /var/log/sudo.log -p wa -k sudo_log" "Ensure sudo log changes are collected",
        check_audit_rule "-w /etc/localtime -p wa -k time-change" "Ensure time change events are collected",
        check_audit_rule "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm_mod" "Ensure permission modification events are collected",
        check_audit_rule "-a always,exit -F arch=b64 -S open -S openat -F exit=-EACCES -F auid>=1000 -k access" "Ensure unsuccessful file access attempts are collected",
        check_audit_rule "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete" "Ensure file deletion events are collected",
        check_audit_rule "-e 2" "Ensure audit configuration is immutable"
    )]" '$rules | { "auditd_rules": $rules }')

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Auditd rules audit results saved to $REPORT_FILE"

# Restart auditd if it's installed
if systemctl list-unit-files | grep -q "^auditd.service"; then
    echo "Restarting auditd..."
    systemctl restart auditd
    echo "Auditd restarted."
else
    echo "Warning: auditd service is not available. Configuration changes may not take effect."
fi
