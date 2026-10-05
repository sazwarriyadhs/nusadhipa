from pathlib import Path
from pypdf import PdfReader

PDF = Path(r"D:\NUSA-DHIPA-BUSINESS-OS\data\kbli\KBLI_2025.pdf")
OUT = Path(r"D:\NUSA-DHIPA-BUSINESS-OS\data\kbli\extracted\KBLI_2025_master_section.txt")

reader = PdfReader(str(PDF))

# Based on the TOC:
# Printed page 231 = approximately PDF page 247
# Printed page 1021 = approximately PDF page 1037
start_pdf_page = 247
end_pdf_page = min(1040, 1040)

print(f"Total PDF pages : {len(reader.pages)}")
print(f"Master section  : PDF {start_pdf_page} - {end_pdf_page}")

with OUT.open("w", encoding="utf-8") as f:
    for pdf_page in range(start_pdf_page, end_pdf_page + 1):
        text = reader.pages[pdf_page - 1].extract_text() or ""

        f.write(f"\n===== PDF PAGE {pdf_page} =====\n")
        f.write(text)
        f.write("\n")

print("")
print("MASTER EXTRACTION COMPLETE")
print(f"Output: {OUT}")
print(f"Size  : {OUT.stat().st_size:,} bytes")
