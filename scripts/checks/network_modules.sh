#!/bin/bash

# Define report file
REPORT_FILE="reports/network_kernel_modules_audit.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# List of unwanted network kernel modules
KERNEL_MODULES=("dccp" "sctp" "rds" "tipc")

# Function to check if a kernel module is loaded and disable it
audit_kernel_module() {
    local module=$1
    local status="passed"
    local recommendation=""

    if lsmod | grep -qw "$module"; then
        status="failed"
        recommendation="Disable $module by adding 'install $module /bin/true' in /etc/modprobe.d/$module.conf and running 'modprobe -r $module'."
    fi

    echo "{\"check\": \"Ensure $module kernel module is not loaded\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Collect JSON output
JSON_OUTPUT="{\"network_kernel_modules_audit\": ["
first=true

for module in "${KERNEL_MODULES[@]}"; do
    result=$(audit_kernel_module "$module")
    if [ "$first" = true ]; then
        JSON_OUTPUT+="$result"
        first=false
    else
        JSON_OUTPUT+=",$result"
    fi
done

JSON_OUTPUT+="]}"

# Save output to file (without printing it)
echo "$JSON_OUTPUT" | jq '.' > "$REPORT_FILE"

echo "Network Kernel Modules audit saved to $REPORT_FILE"
