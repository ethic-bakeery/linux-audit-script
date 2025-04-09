#!/bin/bash

CHECKS_DIR="./scripts/checks"
LOG_FILE="./output/audit.log"
REPORT_FILE="./output/audit_report.json"

mkdir -p ./output

# Initialize log file
echo "Linux Security Audit - $(date)" > "$LOG_FILE"
echo "{" > "$REPORT_FILE"
echo '  "audit_results": [' >> "$REPORT_FILE"

log_message() {
    local message="$1"
    local status="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message - $status" | tee -a "$LOG_FILE"

    echo '    {' >> "$REPORT_FILE"
    echo '      "check": "'"$message"'",' >> "$REPORT_FILE"
    echo '      "status": "'"$status"'"' >> "$REPORT_FILE"
    echo '    },' >> "$REPORT_FILE"
}

run_check() {
    local script="$1"
    local script_name=$(basename "$script")

    echo "Running $script_name..." | tee -a "$LOG_FILE"
    
    # Run the script and capture output
    output=$(bash "$script" 2>&1)
    exit_status=$?

    if [ $exit_status -eq 0 ]; then
        log_message "$script_name" "PASSED"
    else
        log_message "$script_name" "FAILED - $output"
    fi
}

# Run all audit check scripts
for script in "$CHECKS_DIR"/*.sh; do
    if [ -x "$script" ]; then
        run_check "$script"
    else
        log_message "$(basename "$script")" "SKIPPED - Not executable"
    fi
done

# Remove trailing comma in JSON and close the JSON object
sed -i '$ s/,$//' "$REPORT_FILE"
echo '  ]' >> "$REPORT_FILE"
echo '}' >> "$REPORT_FILE"

echo "Audit Completed. Results saved in $LOG_FILE and $REPORT_FILE"

