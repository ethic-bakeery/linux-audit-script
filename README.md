# Linux Audit Script

## Overview
This project provides a comprehensive audit script for **Ubuntu 20.04 LTS** based on the [CIS (Centre for Internet Security) Benchmark](https://downloads.cisecurity.org/#/)The script checks various security configurations, system settings, and compliance requirements.

## Project Structure
```
linux-audit-script/
│── docs/                          # Documentation and CIS Benchmark references
│── reports/                       # Generated audit reports (JSON, CSV, TXT)
│── scripts/                        # Bash scripts for auditing different components
│   ├── audit.sh                    # Main script to execute all checks
│   ├── checks/                      # Directory for individual audit checks
│   │   ├── filesystem.sh                   # Filesystem checks
│   │   ├── partitions.sh                   # Configure filesystem partitions
│   │   ├── software_patch.sh               # Software and patch management
│   │   ├── boot_settings.sh                # Secure boot settings
│   │   ├── process_hardening.sh            # Additional process hardening
│   │   ├── apparmor.sh                     # Configure AppArmor
│   │   ├── warning_banners.sh              # Command line warning banners
│   │   ├── gdm.sh                          # GNOME Display Manager checks
│   │   ├── additional_software.sh          # Additional software checks
│   │   ├── fips.sh                         # FIPS cryptographic module
│   │   ├── time_sync.sh                    # Configure time synchronization
│   │   ├── chrony.sh                       # Configure chrony
│   │   ├── systemd_timesyncd.sh            # Configure systemd-timesyncd
│   │   ├── ntp.sh                          # Configure ntp
│   │   ├── time_source.sh                  # Synchronization with time source
│   │   ├── special_services.sh             # Special purpose services
│   │   ├── service_clients.sh              # Service clients
│   │   ├── network_devices.sh              # Configure network devices
│   │   ├── network_modules.sh              # Configure network kernel modules
│   │   ├── network_params.sh               # Configure network kernel parameters
│   │   ├── firewall.sh                     # Configure host-based firewall
│   │   ├── nftables.sh                     # Configure nftables
│   │   ├── iptables.sh                     # Configure iptables
│   │   ├── job_schedulers.sh               # Configure job schedulers
│   │   ├── ssh_server.sh                   # Configure SSH server
│   │   ├── privilege_escalation.sh         # Configure privilege escalation
│   │   ├── pam.sh                          # Configure Pluggable Authentication Modules (PAM)
│   │   ├── pam_pwhistory.sh                # Configure pam_pwhistory module
│   │   ├── pam_faillock.sh                 # Configure pam_faillock module
│   │   ├── pam_unix.sh                     # Configure pam_unix module
│   │   ├── system_security_services.sh     # Configure system security services
│   │   ├── pam_pkcs11.sh                   # Configure pam_pkcs11 module
│   │   ├── pam_faildelay.sh                # Configure pam_faildelay
│   │   ├── user_accounts.sh                # User accounts and environment
│   │   ├── logging_auditing.sh             # Logging and auditing
│   │   ├── rsyslog.sh                      # Configure rsyslog
│   │   ├── log_file_access.sh              # Configure log file access
│   │   ├── system_accounting.sh            # Configure system accounting
│   │   ├── data_retention.sh               # Configure data retention
│   │   ├── auditd_rules.sh                 # Configure auditd rules
│   │   ├── auditd_file_access.sh           # Configure auditd file access
│   │   ├── integrity_check.sh              # Filesystem integrity checking
│   │   ├── system_maintenance.sh           # System maintenance
│   │   ├── local_users_groups.sh           # Local user and group settings
│── output/                         # Stores temporary scan results
│── config/                         # Configuration files and CIS benchmark references
│   ├── cis_benchmark.cfg           # Custom config for enabling/disabling checks
│── utils/                          # Utility scripts
│   ├── logger.sh                    # Logging functions for consistent output
│   ├── report_generator.sh          # Generates audit reports in multiple formats
│── README.md                       # Project documentation
│── LICENSE                         # Open-source license file
```

## Features
- Audits key security configurations based on **CIS Benchmark for Ubuntu 20.04 LTS**
- Generates compliance reports in JSON, CSV, and TXT formats
- Customizable configuration via `cis_benchmark.cfg`
- Modular script structure for easy maintenance and updates
- Support for logging and automated report generation

## Prerequisites
- Ubuntu 20.04 LTS
- Bash shell
- Root privileges (some checks require elevated permissions)

## Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/linux-audit-script.git
   cd linux-audit-script
   ```
2. Give execution permission to the main script:
   ```bash
   chmod +x scripts/audit.sh
   ```
3. Run the script:
   ```bash
   sudo ./scripts/audit.sh
   ```
4. Review the generated audit reports in the `reports/` directory.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Contribution
Feel free to contribute by submitting issues or pull requests.


