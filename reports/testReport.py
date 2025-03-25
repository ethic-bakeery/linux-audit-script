import json
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

def generate_pdf_report(json_file, output_pdf):
    with open(json_file, "r") as f:
        data = json.load(f)
    
    audit_title = "Service Clients Audit Report"
    services = data.get("service_clients_audit", [])
    
    c = canvas.Canvas(output_pdf, pagesize=A4)
    width, height = A4
    

    c.setFont("Helvetica-Bold", 16)
    c.drawCentredString(width / 2, height - 50, audit_title)
    
    c.setFont("Helvetica-Bold", 12)
    x_offset, y_offset = 50, height - 100
    c.drawString(x_offset, y_offset, "Service")
    c.drawString(x_offset + 150, y_offset, "Status")
    c.drawString(x_offset + 250, y_offset, "Recommendation")
    
    c.setFont("Helvetica", 10)
    y_offset -= 20
    
    for service in services:
        service_name = service.get("service", service.get("check", "Unknown"))
        status = service.get("status", "N/A")
        recommendation = service.get("recommendation", "None")
        
        c.drawString(x_offset, y_offset, service_name)
        c.drawString(x_offset + 150, y_offset, status)
        c.drawString(x_offset + 250, y_offset, recommendation[:50] + ("..." if len(recommendation) > 50 else ""))
        
        y_offset -= 20
        
        if y_offset < 50:
            c.showPage()
            c.setFont("Helvetica", 10)
            y_offset = height - 50
    
    c.save()
    print(f"PDF report generated: {output_pdf}")

generate_pdf_report("service_clients_audit.json", "audit_report.pdf")

