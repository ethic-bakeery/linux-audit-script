#!/bin/bash

# Define report file
REPORT_FILE="reports/partition_audit_report.json"
mkdir -p "$(dirname "$REPORT_FILE")"

# List of partitions to check
PARTITIONS=(
    "/tmp"
    "/dev/shm"
    "/home"
    "/var"
    "/var/tmp"
    "/var/log"
    "/var/log/audit"
)

# Function to check if a partition exists
check_partition_exists() {
    local partition=$1
    local status="failed"
    local recommendation="Update /etc/fstab to mount $partition on a separate partition."

    if mount | grep -q "on $partition "; then
        status="passed"
        recommendation=""
    fi

    echo "{\"check\": \"Ensure $partition is on a separate partition\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if a partition has a specific mount option
check_mount_option() {
    local partition=$1
    local option=$2
    local status="failed"
    local recommendation="Add '$option' to the mount options in /etc/fstab for $partition."

    if mount | grep "on $partition " | grep -q "$option"; then
        status="passed"
        recommendation=""
    fi

    echo "{\"check\": \"Ensure $option option is set on $partition\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Collect audit results
JSON_OUTPUT="{\"partition_audit\": ["
first=true

for partition in "${PARTITIONS[@]}"; do
    # Check if partition exists
    result=$(check_partition_exists "$partition")
    if [ "$first" = true ]; then
        JSON_OUTPUT+="$result"
        first=false
    else
        JSON_OUTPUT+=",$result"
    fi

    # Check mount options based on partition type
    case "$partition" in
        "/tmp" | "/dev/shm" | "/var/tmp" | "/var/log" | "/var/log/audit")
            for option in "nodev" "nosuid" "noexec"; do
                result=$(check_mount_option "$partition" "$option")
                JSON_OUTPUT+=",$result"
            done
            ;;
        "/home" | "/var")
            for option in "nodev" "nosuid"; do
                result=$(check_mount_option "$partition" "$option")
                JSON_OUTPUT+=",$result"
            done
            ;;
    esac
done

JSON_OUTPUT+="]}"

# Save the JSON output to the file (without printing it)
echo "$JSON_OUTPUT" | jq '.' > "$REPORT_FILE"

echo "Partition Audit Complete. Results saved in $REPORT_FILE"
