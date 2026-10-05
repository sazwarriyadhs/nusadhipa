from pathlib import Path

PDF = Path("data/kbli/KBLI_2025.pdf")
OUT = Path("data/kbli/extracted/KBLI_2025_sample.txt")

if not PDF.exists():
    print(f"ERROR: PDF not found: {PDF}")
else:
    try:
        import fitz

        print("Parser: PyMuPDF")

        doc = fitz.open(PDF)

        print(f"Total pages: {len(doc)}")

        chunks = []

        for i in range(min(20, len(doc))):
            text = doc[i].get_text("text") or ""

            chunks.append(
                f"\n===== PAGE {i + 1} =====\n{text}"
            )

        OUT.write_text(
            "\n".join(chunks),
            encoding="utf-8"
        )

        print(f"Extracted pages: {min(20, len(doc))}")

    except ImportError:

        try:
            from pypdf import PdfReader

            print("Parser: pypdf")

            reader = PdfReader(str(PDF))

            print(f"Total pages: {len(reader.pages)}")

            chunks = []

            for i, page in enumerate(reader.pages[:20]):
                text = page.extract_text() or ""

                chunks.append(
                    f"\n===== PAGE {i + 1} =====\n{text}"
                )

            OUT.write_text(
                "\n".join(chunks),
                encoding="utf-8"
            )

            print(f"Extracted pages: {min(20, len(reader.pages))}")

        except ImportError:
            print("ERROR: No PDF parser available.")
