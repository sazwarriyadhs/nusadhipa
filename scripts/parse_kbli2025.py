from pathlib import Path
import csv
import re
import json
from collections import Counter, defaultdict

ROOT = Path(r"D:\NUSA-DHIPA-BUSINESS-OS")
INPUT = ROOT / "data" / "kbli" / "extracted" / "KBLI_2025_master_section.txt"
OUTPUT = ROOT / "data" / "kbli" / "kbli_2025.csv"
REPORT = ROOT / "data" / "kbli" / "kbli_2025_parse_report.json"

if not INPUT.exists():
    raise SystemExit(f"INPUT_NOT_FOUND: {INPUT}")

text = INPUT.read_text(encoding="utf-8", errors="replace")
lines = text.splitlines()

# ------------------------------------------------------------
# Normalization
# ------------------------------------------------------------

def clean_text(value: str) -> str:
    value = value.replace("\u00a0", " ")
    value = value.replace("\u00ad", "")
    value = value.replace("–", "-").replace("—", "-")
    value = re.sub(r"\s+", " ", value)
    return value.strip()

def is_page_header(line: str) -> bool:
    s = clean_text(line)

    if not s:
        return True

    if s.startswith("https://www.bps.go.id"):
        return True

    if re.fullmatch(r"\d+\s+Klasifikasi Baku Lapangan Usaha Indonesia \(KBLI\) 2025", s):
        return True

    # Example: A PERTANIAN... 231
    if re.fullmatch(r"[A-Z]\s+.+\s+\d{1,4}", s):
        return True

    return False

# ------------------------------------------------------------
# Code detection
# ------------------------------------------------------------

category_re = re.compile(
    r"^([A-Z])\s+(.+)$"
)

group_pokok_re = re.compile(
    r"^(\d{2})\s+(.+)$"
)

group_re = re.compile(
    r"^(\d{3})\s+(.+)$"
)

subgroup_re = re.compile(
    r"^(\d{4})\s+(.+)$"
)

activity_re = re.compile(
    r"^(\d{5})\s+(.+)$"
)

# Known non-data text patterns.
ignore_prefixes = (
    "Golongan pokok ini",
    "Golongan ini",
    "Subgolongan ini",
    "Kelompok ini",
    "Kategori ini",
    "Subgolongan ini tidak",
    "Kelompok ini tidak",
    "Klasifikasi Baku",
)

# ------------------------------------------------------------
# First pass: join wrapped title lines
# ------------------------------------------------------------

raw = []

for line in lines:
    s = clean_text(line)

    if not s:
        raw.append("")
        continue

    if is_page_header(s):
        continue

    raw.append(s)

# We need to preserve hierarchy and capture descriptions separately.
#
# A code title can wrap onto the following PDF line:
#
# 01116 PERTANIAN ANEKA KACANG SELAIN KEDELAI, KACANG TANAH, DAN
# KACANG HIJAU
#
# Therefore detect code first, then absorb continuation lines until
# the next hierarchy code.

records = []

current = None

def level_for_code(code: str) -> str:
    if len(code) == 2:
        return "group_pokok"
    if len(code) == 3:
        return "group"
    if len(code) == 4:
        return "subgroup"
    if len(code) == 5:
        return "activity"
    return ""

def emit_current():
    global current
    if current is not None:
        current["title"] = clean_text(current["title"])
        current["description"] = clean_text(current["description"])
        records.append(current)
        current = None

# Track current hierarchy.
category = None
group_pokok = None
group = None
subgroup = None

for i, line in enumerate(raw):
    if not line:
        continue

    # Category
    m = category_re.match(line)
    if m and len(m.group(1)) == 1:
        # Avoid ordinary prose starting with one capital letter.
        if len(line) > 3 and not line.startswith(("Akhir", "Bukan")):
            emit_current()

            category = {
                "code": m.group(1),
                "title": clean_text(m.group(2)),
            }

            group_pokok = None
            group = None
            subgroup = None
            continue

    # Hierarchy codes
    m = re.match(r"^(\d{5})\s+(.+)$", line)
    if m:
        emit_current()

        code = m.group(1)
        title = m.group(2)

        current = {
            "code": code,
            "level": "activity",
            "title": title,
            "description": "",
            "category_code": category["code"] if category else "",
            "category_title": category["title"] if category else "",
            "group_code": group["code"] if group else "",
            "group_title": group["title"] if group else "",
            "subgroup_code": subgroup["code"] if subgroup else "",
            "subgroup_title": subgroup["title"] if subgroup else "",
            "parent_code": subgroup["code"] if subgroup else "",
        }
        continue

    m = re.match(r"^(\d{4})\s+(.+)$", line)
    if m:
        emit_current()

        code = m.group(1)
        title = m.group(2)

        subgroup = {
            "code": code,
            "title": title,
        }

        group = group
        current = {
            "code": code,
            "level": "subgroup",
            "title": title,
            "description": "",
            "category_code": category["code"] if category else "",
            "category_title": category["title"] if category else "",
            "group_code": group["code"] if group else "",
            "group_title": group["title"] if group else "",
            "subgroup_code": "",
            "subgroup_title": "",
            "parent_code": group["code"] if group else "",
        }
        continue

    m = re.match(r"^(\d{3})\s+(.+)$", line)
    if m:
        emit_current()

        code = m.group(1)
        title = m.group(2)

        group = {
            "code": code,
            "title": title,
        }

        subgroup = None

        current = {
            "code": code,
            "level": "group",
            "title": title,
            "description": "",
            "category_code": category["code"] if category else "",
            "category_title": category["title"] if category else "",
            "group_code": "",
            "group_title": "",
            "subgroup_code": "",
            "subgroup_title": "",
            "parent_code": category["code"] if category else "",
        }
        continue

    m = re.match(r"^(\d{2})\s+(.+)$", line)
    if m:
        emit_current()

        code = m.group(1)
        title = m.group(2)

        group_pokok = {
            "code": code,
            "title": title,
        }

        group = None
        subgroup = None

        current = {
            "code": code,
            "level": "group_pokok",
            "title": title,
            "description": "",
            "category_code": category["code"] if category else "",
            "category_title": category["title"] if category else "",
            "group_code": "",
            "group_title": "",
            "subgroup_code": "",
            "subgroup_title": "",
            "parent_code": category["code"] if category else "",
        }
        continue

    # --------------------------------------------------------
    # Continuation / description text
    # --------------------------------------------------------
    if current is not None:
        if not is_page_header(line):
            if current["description"]:
                current["description"] += " " + line
            else:
                current["description"] = line

emit_current()

# ------------------------------------------------------------
# Remove obvious false records
# ------------------------------------------------------------

valid_records = []

for r in records:
    code = r["code"]
    title = clean_text(r["title"])

    if not title:
        continue

    if code.isdigit() and len(code) in (2, 3, 4, 5):
        valid_records.append(r)

records = valid_records

# ------------------------------------------------------------
# Reconstruct hierarchy for activity records.
#
# Some PDF pages can repeat parent headings. The safest source of
# hierarchy is the numeric prefix itself.
# ------------------------------------------------------------

for r in records:
    code = r["code"]

    if len(code) == 5:
        r["group_code"] = code[:3]
        r["subgroup_code"] = code[:4]
        r["parent_code"] = code[:4]

    elif len(code) == 4:
        r["group_code"] = code[:3]
        r["subgroup_code"] = ""
        r["parent_code"] = code[:3]

    elif len(code) == 3:
        r["group_code"] = ""
        r["subgroup_code"] = ""
        r["parent_code"] = code[:2]

    elif len(code) == 2:
        r["group_code"] = ""
        r["subgroup_code"] = ""
        r["parent_code"] = r["category_code"]

# ------------------------------------------------------------
# Duplicate analysis
# ------------------------------------------------------------

all_codes = [r["code"] for r in records]
counts = Counter(all_codes)

duplicates = {
    code: count
    for code, count in sorted(counts.items())
    if count > 1
}

# For master CSV we only retain unique code + level.
# Prefer the record with the longest description.
dedup = {}

for r in records:
    code = r["code"]

    if code not in dedup:
        dedup[code] = r
    else:
        old = dedup[code]

        if len(r["description"]) > len(old["description"]):
            dedup[code] = r

records = list(dedup.values())

# ------------------------------------------------------------
# Sort
# ------------------------------------------------------------

level_order = {
    "group_pokok": 1,
    "group": 2,
    "subgroup": 3,
    "activity": 4,
}

records.sort(
    key=lambda r: (
        r["category_code"],
        level_order.get(r["level"], 99),
        r["code"],
    )
)

# ------------------------------------------------------------
# Validate hierarchy
# ------------------------------------------------------------

codes = {r["code"] for r in records}

orphan = []

for r in records:
    code = r["code"]

    if len(code) == 2:
        if not r["category_code"]:
            orphan.append(code)

    elif len(code) == 3:
        if code[:2] not in codes:
            orphan.append(code)

    elif len(code) == 4:
        if code[:3] not in codes:
            orphan.append(code)

    elif len(code) == 5:
        if code[:4] not in codes:
            orphan.append(code)

invalid = []

for r in records:
    if r["level"] == "activity" and len(r["code"]) != 5:
        invalid.append(r["code"])

# ------------------------------------------------------------
# Write CSV
# ------------------------------------------------------------

fields = [
    "version",
    "code",
    "title",
    "description",
    "level",
    "category_code",
    "category_title",
    "group_code",
    "group_title",
    "subgroup_code",
    "subgroup_title",
    "parent_code",
    "source",
    "source_reference",
]

with OUTPUT.open("w", encoding="utf-8-sig", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()

    for r in records:
        writer.writerow({
            "version": "2025",
            "code": r["code"],
            "title": r["title"],
            "description": r["description"],
            "level": r["level"],
            "category_code": r["category_code"],
            "category_title": r["category_title"],
            "group_code": r["group_code"],
            "group_title": r["group_title"],
            "subgroup_code": r["subgroup_code"],
            "subgroup_title": r["subgroup_title"],
            "parent_code": r["parent_code"],
            "source": "BPS",
            "source_reference": "https://www.bps.go.id/",
        })

# ------------------------------------------------------------
# Report
# ------------------------------------------------------------

level_counts = Counter(r["level"] for r in records)

report = {
    "input": str(INPUT),
    "output": str(OUTPUT),
    "total_records": len(records),
    "levels": {
        "category": len({r["category_code"] for r in records if r["category_code"]}),
        "group_pokok": level_counts.get("group_pokok", 0),
        "group": level_counts.get("group", 0),
        "subgroup": level_counts.get("subgroup", 0),
        "activity": level_counts.get("activity", 0),
    },
    "raw_code_duplicates": duplicates,
    "unique_codes": len(records),
    "orphan_codes": sorted(set(orphan)),
    "invalid_codes": sorted(set(invalid)),
    "status": "PASS" if not orphan and not invalid else "REVIEW",
}

REPORT.write_text(
    json.dumps(report, ensure_ascii=False, indent=2),
    encoding="utf-8"
)

# ------------------------------------------------------------
# Console report
# ------------------------------------------------------------

print("")
print("=" * 70)
print(" KBLI 2025 PDF PARSER")
print("=" * 70)
print(f"Input              : {INPUT}")
print(f"Output CSV         : {OUTPUT}")
print(f"Report             : {REPORT}")
print("")
print("LEVEL COUNTS")
print(f"Category           : {report['levels']['category']}")
print(f"Golongan Pokok     : {report['levels']['group_pokok']}")
print(f"Golongan           : {report['levels']['group']}")
print(f"Subgolongan        : {report['levels']['subgroup']}")
print(f"Kelompok / 5-digit : {report['levels']['activity']}")
print("")
print(f"Total CSV records  : {report['total_records']}")
print(f"Unique codes       : {report['unique_codes']}")
print(f"Raw duplicates     : {len(duplicates)}")
print(f"Orphan codes       : {len(set(orphan))}")
print(f"Invalid codes      : {len(set(invalid))}")
print("")
print("DUPLICATES")
for code, count in duplicates.items():
    print(f"  {code}: {count}")

print("")
print("ORPHANS")
for code in sorted(set(orphan))[:50]:
    print(f"  {code}")

print("")
print("SAMPLE ACTIVITIES")
shown = 0
for r in records:
    if r["level"] == "activity":
        print(f"  {r['code']} | {r['title']}")
        shown += 1
        if shown >= 20:
            break

print("")
print("=" * 70)
print(f" STATUS : {report['status']}")
print("=" * 70)
