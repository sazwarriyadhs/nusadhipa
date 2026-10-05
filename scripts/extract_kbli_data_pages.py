from pathlib import Path
from pypdf import PdfReader

PDF = Path(r"D:\NUSA-DHIPA-BUSINESS-OS\data\kbli\KBLI_2025.pdf")
OUT_DIR = Path(r"D:\NUSA-DHIPA-BUSINESS-OS\data\kbli\extracted")
OUT_DIR.mkdir(parents=True, exist_ok=True)

reader = PdfReader(str(PDF))

print(f"PDF       : {PDF}")
print(f"Total pages: {len(reader.pages)}")

# PDF page index is zero-based.
# KBLI category A starts around printed page 231.
start_page = 230
end_page = min(len(reader.pages), 1040)

output = OUT_DIR / "KBLI_2025_data_pages.txt"

with output.open("w", encoding="utf-8") as f:
    for idx in range(start_page, end_page):
        page_no = idx + 1

        try:
            text = reader.pages[idx].extract_text() or ""
        except Exception as exc:
            text = f"[EXTRACTION ERROR] {exc}"

        f.write(f"\n===== PDF PAGE {page_no} =====\n")
        f.write(text)
        f.write("\n")

        if (page_no - start_page) % 50 == 0:
            print(f"Extracted through PDF page {page_no}")

print("")
print("EXTRACTION COMPLETE")
print(f"Output: {output}")
print(f"Size  : {output.stat().st_size:,} bytes")
