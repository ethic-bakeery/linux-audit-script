#!/bin/bash

# Define the report file
REPORT_FILE="reports/local_user_group_audit.json"

# Ensure the report directory exists
mkdir -p "$(dirname "$REPORT_FILE")"

# Function to check if accounts use shadowed passwords
check_shadowed_passwords() {
    local status="passed"
    local recommendation=""
    
    if awk -F: '($2 != "x") {print $1}' /etc/passwd | grep -q .; then
        status="failed"
        recommendation="Move all passwords to /etc/shadow using: pwconv"
    fi

    echo "{\"check\": \"Ensure accounts in /etc/passwd use shadowed passwords\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if shadow password fields are empty
check_shadow_empty_passwords() {
    local status="passed"
    local recommendation=""

    if awk -F: '($2 == "") {print $1}' /etc/shadow | grep -q .; then
        status="failed"
        recommendation="Lock empty password accounts using: passwd -l <username>"
    fi

    echo "{\"check\": \"Ensure /etc/shadow password fields are not empty\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if all groups exist
check_groups_exist() {
    local status="passed"
    local recommendation=""

    if awk -F: '{print $4}' /etc/passwd | while read gid; do grep -q "^[^:]*:[^:]*:$gid:" /etc/group || echo "missing"; done | grep -q "missing"; then
        status="failed"
        recommendation="Ensure all groups in /etc/passwd exist in /etc/group"
    fi

    echo "{\"check\": \"Ensure all groups in /etc/passwd exist in /etc/group\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if shadow group is empty
check_shadow_group_empty() {
    local status="passed"
    local recommendation=""

    if grep -q "^shadow:[^:]*:[^:]*:[^:]+$" /etc/group; then
        status="failed"
        recommendation="Remove users from shadow group using: gpasswd -d <username> shadow"
    fi

    echo "{\"check\": \"Ensure shadow group is empty\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check for duplicate UIDs
check_duplicate_uids() {
    local status="passed"
    local recommendation=""

    if cut -d: -f3 /etc/passwd | sort | uniq -d | grep -q .; then
        status="failed"
        recommendation="Remove or modify duplicate UIDs using: usermod -u <newUID> <username>"
    fi

    echo "{\"check\": \"Ensure no duplicate UIDs exist\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check for duplicate GIDs
check_duplicate_gids() {
    local status="passed"
    local recommendation=""

    if cut -d: -f3 /etc/group | sort | uniq -d | grep -q .; then
        status="failed"
        recommendation="Remove or modify duplicate GIDs using: groupmod -g <newGID> <groupname>"
    fi

    echo "{\"check\": \"Ensure no duplicate GIDs exist\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check for duplicate usernames
check_duplicate_usernames() {
    local status="passed"
    local recommendation=""

    if cut -d: -f1 /etc/passwd | sort | uniq -d | grep -q .; then
        status="failed"
        recommendation="Rename duplicate users using: usermod -l <newname> <oldname>"
    fi

    echo "{\"check\": \"Ensure no duplicate user names exist\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check for duplicate group names
check_duplicate_groupnames() {
    local status="passed"
    local recommendation=""

    if cut -d: -f1 /etc/group | sort | uniq -d | grep -q .; then
        status="failed"
        recommendation="Rename duplicate groups using: groupmod -n <newname> <oldname>"
    fi

    echo "{\"check\": \"Ensure no duplicate group names exist\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check root PATH integrity
check_root_path_integrity() {
    local status="passed"
    local recommendation=""

    if echo "$PATH" | grep -q "::\|:$"; then
        status="failed"
        recommendation="Clean up root PATH variable in /etc/profile or ~/.bashrc"
    fi

    echo "{\"check\": \"Ensure root PATH Integrity\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check if root is the only UID 0 account
check_only_root_uid_0() {
    local status="passed"
    local recommendation=""

    if awk -F: '($3 == 0 && $1 != "root") {print $1}' /etc/passwd | grep -q .; then
        status="failed"
        recommendation="Investigate and remove non-root UID 0 accounts using: userdel <username>"
    fi

    echo "{\"check\": \"Ensure root is the only UID 0 account\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check home directory configurations
check_home_dirs_configured() {
    local status="passed"
    local recommendation=""

    if awk -F: '($3 >= 1000 && $7 != "/sbin/nologin" && !($6 ~ /home/)) {print $1}' /etc/passwd | grep -q .; then
        status="failed"
        recommendation="Ensure users have valid home directories using: usermod -d /home/<username> <username>"
    fi

    echo "{\"check\": \"Ensure local interactive user home directories are configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Function to check dot file access
check_dot_file_access() {
    local status="passed"
    local recommendation=""

    if find /home -type f -name ".*" -perm -0002 | grep -q .; then
        status="failed"
        recommendation="Fix permissions using: chmod go-w /home/<user>/.<file>"
    fi

    echo "{\"check\": \"Ensure local interactive user dot files access is configured\", \"status\": \"$status\", \"recommendation\": \"$recommendation\"}"
}

# Generate JSON report
JSON_OUTPUT=$(cat <<EOF
{
  "local_user_group_settings": [
    $(check_shadowed_passwords),
    $(check_shadow_empty_passwords),
    $(check_groups_exist),
    $(check_shadow_group_empty),
    $(check_duplicate_uids),
    $(check_duplicate_gids),
    $(check_duplicate_usernames),
    $(check_duplicate_groupnames),
    $(check_root_path_integrity),
    $(check_only_root_uid_0),
    $(check_home_dirs_configured),
    $(check_dot_file_access)
  ]
}
EOF
)

# Save results to the report file
echo "$JSON_OUTPUT" > "$REPORT_FILE"

echo "Local user and group settings audit results saved to $REPORT_FILE"
