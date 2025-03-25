import json
import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle

# Define the directory containing JSON files
JSON_DIR = "."

# Define the output PDF file
OUTPUT_PDF = "final_audit_report.pdf"

# Function to load JSON data from a file
def load_json(file_path):
    with open(file_path, "r") as file:
        try:
            # Try to load as a single JSON object
            return json.load(file)
        except json.JSONDecodeError:
            # If it fails, try to load as multiple JSON objects
            file.seek(0)  # Reset file pointer
            data = []
            for line in file:
                line = line.strip()
                if line:
                    data.append(json.loads(line))
            return data

# Function to create a PDF report
def create_pdf_report(json_files):
    # Create a PDF document
    pdf = SimpleDocTemplate(OUTPUT_PDF, pagesize=letter)
    styles = getSampleStyleSheet()
    story = []

    # Add a title to the report
    title = Paragraph("Final Audit Report", styles["Title"])
    story.append(title)
    story.append(Spacer(1, 12))

    # Process each JSON file
    for json_file in json_files:
        file_path = os.path.join(JSON_DIR, json_file)
        data = load_json(file_path)

        # Extract the section title from the file name (without .json)
        section_title = json_file.replace(".json", "").replace("_", " ").title()

        # Add a section header for the JSON file
        section_header = Paragraph(f"Audit Results: {section_title}", styles["Heading2"])
        story.append(section_header)
        story.append(Spacer(1, 12))

        # Extract the audit results
        audit_results = []
        if isinstance(data, dict):
            for key, value in data.items():
                if isinstance(value, list):
                    audit_results.extend(value)
                else:
                    audit_results.append(value)
        elif isinstance(data, list):
            audit_results.extend(data)

        # Create a table for the audit results
        table_data = [["Check", "Status", "Recommendation"]]
        for result in audit_results:
            if isinstance(result, dict):
                check = result.get("check", "N/A")
                status = result.get("status", "N/A")
                recommendation = result.get("recommendation", "N/A")
                table_data.append([check, status, recommendation])

        # Define column widths (adjust as needed)
        col_widths = [200, 80, 250]

        # Add the table to the PDF
        table = Table(table_data, colWidths=col_widths)
        table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.grey),  # Header row background
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),  # Header row text color
            ("ALIGN", (0, 0), (-1, -1), "CENTER"),  # Center-align all text
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),  # Header row font
            ("BOTTOMPADDING", (0, 0), (-1, 0), 12),  # Header row padding
            ("BACKGROUND", (0, 1), (-1, -1), colors.beige),  # Data row background
            ("GRID", (0, 0), (-1, -1), 1, colors.black),  # Grid lines
            ("WORDWRAP", (0, 0), (-1, -1), True),  # Enable word wrap
        ]))
        story.append(table)
        story.append(Spacer(1, 12))

    # Build the PDF
    pdf.build(story)
    print(f"PDF report generated: {OUTPUT_PDF}")

# List of JSON files to include in the report
json_files = [
    "additional_software_audit.json",
    "aide_integrity_check.json",
    "apparmor_audit_report.json",
    "auditd_rules.json",
    "chrony_audit.json",
    "cli_warning_banners_audit.json",
    "data_retention_audit.json",
    "filesystem_audit_report.json",
    "fips_audit.json",
    "gdm_security_audit.json",
    "host_based_firewall_audit.json",
    "iptables_audit.json",
    "local_user_group_audit.json",
    "log_file_access_audit.json",
    "logging_audit.json",
    "network_devices_audit.json",
    "network_kernel_modules_audit.json",
    "network_kernel_parameters_audit.json",
    "nftables_audit.json",
    "pam_pkcs11_audit.json",
    "pam_pwquality_audit.json",
    "partition_audit_report.json",
    "password_policy_audit.json",
    "privilege_escalation_audit.json",
    "rsyslog_audit.json",
    "secure_boot_audit_report.json",
    "service_clients_audit.json",
    "software_patch_audit_report.json",
    "special_services_audit.json",
    "ssh_server_audit.json",
    "timesyncd_audit.json",
    "time_sync_audit.json",
    "user_accounts_audit.json",
]

# Generate the PDF report
create_pdf_report(json_files)
