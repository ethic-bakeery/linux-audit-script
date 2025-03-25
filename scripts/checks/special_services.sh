#!/bin/bash

# Report file location
REPORT_FILE="reports/special_services_audit.json"

# Ensure the reports directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# List of services to audit
SERVICES=(
    "xserver-xorg*" "avahi-daemon" "cups" "isc-dhcp-server" "slapd" "nfs-kernel-server"
    "bind9" "vsftpd" "apache2" "dovecot-core" "samba" "squid" "snmpd"
    "nis" "dnsmasq" "telnetd" "rsh-server"
)

# Function to audit a service
audit_services() {
    local service=$1
    local status="passed"
    local recommendation="None"

    if dpkg -l | grep -qw "$service" || systemctl list-units --type=service --all | grep -qw "$service"; then
        status="failed"
        recommendation="Remove with 'apt remove --purge $service -y' and disable it using 'systemctl disable $service'."  
    fi

    jq -n \
        --arg service "$service" \
        --arg status "$status" \
        --arg recommendation "$recommendation" \
        '{service: $service, status: $status, recommendation: $recommendation}'
}

# Function to check if MTA is restricted to local use
check_mta_local_only() {
    local status="passed"
    local recommendation="None"

    if ! grep -qE "^inet_interfaces\s*=\s*loopback-only" /etc/postfix/main.cf 2>/dev/null; then
        status="failed"
        recommendation="Set 'inet_interfaces = loopback-only' in '/etc/postfix/main.cf' and restart Postfix."
    fi

    jq -n \
        --arg check "Ensure mail transfer agent is configured for local-only mode" \
        --arg status "$status" \
        --arg recommendation "$recommendation" \
        '{check: $check, status: $status, recommendation: $recommendation}'
}

# Function to check if rsync is either not installed or masked
check_rsync() {
    local status="passed"
    local recommendation="None"

    if dpkg -l | grep -qw "rsync"; then
        if ! systemctl is-enabled rsync 2>/dev/null | grep -qw "masked"; then
            status="failed"
            recommendation="Mask rsync using 'systemctl mask rsync' or remove it using 'apt remove --purge rsync -y'."
        fi
    fi

    jq -n \
        --arg check "Ensure rsync is either not installed or is masked" \
        --arg status "$status" \
        --arg recommendation "$recommendation" \
        '{check: $check, status: $status, recommendation: $recommendation}'
}

# Generate JSON for audited services
SERVICE_RESULTS=()
for service in "${SERVICES[@]}"; do
    SERVICE_RESULTS+=("$(audit_services "$service")")
done

# Convert array to JSON array
SERVICE_JSON=$(printf "%s\n" "${SERVICE_RESULTS[@]}" | jq -s '.')

# Generate final JSON output
JSON_OUTPUT=$(jq -n \
    --argjson services "$SERVICE_JSON" \
    --argjson mta "$(check_mta_local_only)" \
    --argjson rsync "$(check_rsync)" \
    '{ "special_services_audit": ($services + [$mta, $rsync]) }')

# Save the JSON output to file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Special services audit results saved to $REPORT_FILE"
