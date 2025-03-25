#!/bin/bash

REPORT_DIR="reports"
REPORT_FILE="$REPORT_DIR/filesystem_audit_report.json"

# Ensure the reports directory exists
mkdir -p "$REPORT_DIR"

KERNEL_MODULES=(
    "cramfs"
    "freevxfs"
    "hfs"
    "hfsplus"
    "jffs2"
    "overlayfs"
    "squashfs"
    "udf"
    "usb-storage"
)

# Start JSON output
echo "{" > "$REPORT_FILE"
echo "  \"filesystem_audit\": [" >> "$REPORT_FILE"

# Function to check if a kernel module is not available
check_kernel_module() {
    local module=$1
    local status="failed"
    local recommendation="Ensure the $module kernel module is not loaded."

    if ! lsmod | grep -q "$module"; then
        status="passed"
        recommendation=""
    fi

    echo "    { \"check\": \"Ensure $module kernel module is not loaded\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" }," >> "$REPORT_FILE"
}

# Function to check if the sticky bit is set on all world-writable directories
check_sticky_bit() {
    local status="failed"
    local recommendation="Set the sticky bit on all world-writable directories using: find / -type d -perm -0002 -exec chmod +t {} +"

    if ! df --local -P | awk 'NR!=1 {print $6}' | xargs -I '{}' find '{}' -xdev -type d \( -perm -0002 -a ! -perm -1000 \) 2>/dev/null | grep -q .; then
        status="passed"
        recommendation=""
    fi

    echo "    { \"check\": \"Ensure sticky bit is set on all world-writable directories\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" }," >> "$REPORT_FILE"
}

# Run kernel module checks
for module in "${KERNEL_MODULES[@]}"; do
    check_kernel_module "$module"
done

# Run sticky bit check
check_sticky_bit

# Remove last comma and close JSON
sed -i '$ s/,$//' "$REPORT_FILE"
echo "  ]" >> "$REPORT_FILE"
echo "}" >> "$REPORT_FILE"

echo "Filesystem Kernel Modules and Sticky Bit checks saved to $REPORT_FILE"
