#!/bin/bash

# Define report file location
REPORT_FILE="reports/service_clients_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# List of unwanted service clients
SERVICE_CLIENTS=(
    "nis" "rsh-client" "talk" "telnet" "ldap-utils" "rpcbind"
)

# Check and remove each service client
audit_service_client() {
    local service=$1
    local status="passed"
    local recommendation=""

    if dpkg -l | grep -qw "$service"; then
        status="failed"
        recommendation="Remove with 'apt remove --purge $service -y' and disable it using 'systemctl disable $service'."
    fi

    echo "{ \"service\": \"$service\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" }"
}

# Ensure nonessential services are removed or masked (Manual)
check_nonessential_services() {
    local status="manual"
    local recommendation="Review all running services using 'systemctl list-units --type=service' and mask any unnecessary services using 'systemctl mask <service>'."

    echo "{ \"check\": \"Ensure nonessential services are removed or masked\", \"status\": \"$status\", \"recommendation\": \"$recommendation\" }"
}

# Generate JSON for service clients
SERVICE_RESULTS=()
for service in "${SERVICE_CLIENTS[@]}"; do
    SERVICE_RESULTS+=("$(audit_service_client "$service")")
done

# Convert array to JSON array
SERVICE_JSON=$(printf "%s\n" "${SERVICE_RESULTS[@]}" | jq -s '.')

# Generate final JSON output
JSON_OUTPUT=$(jq -n \
    --argjson services "$SERVICE_JSON" \
    --argjson nonessential "$(check_nonessential_services)" \
    '{ "service_clients_audit": ($services + [$nonessential]) }')

# Save the JSON output to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

# Print completion message
echo "Service clients audit results saved to $REPORT_FILE"
