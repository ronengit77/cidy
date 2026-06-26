"""
Build/refresh KS_Mapping_Table.xlsx: maps Jack/Jon test-topic knowledge-source
IDs to their production knowledge-source ID equivalents.

Run any time after Jack or Jon add new test topics:

    py build_ks_mapping_table.py

Scans every Formulate_Response_*.yaml at the repo root (production) and every
Jack_*/Jon_* folder (test environments) for knowledge-source references
(list items under a `SearchSpecificKnowledgeSources` block), then tries to
auto-match each test ID to a production ID by normalized label similarity.

Auto-fill only happens when there's a single unambiguous high-confidence
match. Ambiguous or unmatched IDs are left blank with candidates listed in
the Candidates column - never silently guessed.

Incremental: re-running preserves any row where you've already filled in
ProductionKnowledgeSourceID (or just added a Note) - those are never
overwritten. New IDs found get appended. IDs no longer found in any current
Jack/Jon file are kept (not deleted) and marked STALE.
"""

import glob
import os
import re
import sys
from difflib import SequenceMatcher

try:
    import openpyxl
    from openpyxl.worksheet.table import Table, TableStyleInfo
    from openpyxl.worksheet.datavalidation import DataValidation
    from openpyxl.styles import Alignment, Font
    from openpyxl.utils import get_column_letter
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install requirements with:\n  py -m pip install openpyxl")
    sys.exit(1)

ROOT = r"C:\Users\RRAPOPOR\Documents\Cidy testing"
OUT_XLSX = os.path.join(ROOT, "KS_Mapping_Table.xlsx")
PREFIX = "copilots_header_3141e.topic."

FOLDER_TO_PROD_FILE = {
    "Jack_PD_Tests": "Formulate_Response_Programme_Development.yaml",
    "Jack_RPTC_tests": "Formulate_Response_RPTC.yaml",
    "Jon_DA_tests": "Formulate_Response_DA.yaml",
}

PREFIX_STRIP = ["nrda", "nr", "da", "pd", "cidy", "rptc"]
SUFFIX_STRIP = ["fileupload", "file_upload"]
ABBREVIATIONS = {
    "ppd": "projectplanninganddesign",
    "ed": "evaluationanddesign",
    "pmr": "projectmonitoringandreporting",
}

AUTOFILL_RATIO = 0.90
AUTOFILL_MARGIN = 0.15
HINT_RATIO = 0.35

HEADERS = ["SourceFolder", "SourceFile", "UsedIn", "TestKnowledgeSourceID", "GuessedLabel",
           "ProductionKnowledgeSourceID", "Status", "Candidates", "Notes"]

KS_LINE_RE = re.compile(r"^(\s*)-\s+(copilots_header_3141e\.topic\.\S+)\s*$")


def extract_ks_refs(path):
    """List of (line_no, full_id) for list items that genuinely sit under a
    SearchSpecificKnowledgeSources block (checked structurally, not just a
    bare regex match anywhere in the file - avoids picking up unrelated
    'dialog: ...' references that share the same ID prefix)."""
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    refs = []
    for i, line in enumerate(lines):
        m = KS_LINE_RE.match(line.rstrip("\n"))
        if not m:
            continue
        full_id = m.group(2)
        window = lines[max(0, i - 6):i]
        if any("SearchSpecificKnowledgeSources" in w for w in window):
            refs.append((i + 1, full_id))
    return refs


def guess_label(full_id):
    remainder = full_id[len(PREFIX):] if full_id.startswith(PREFIX) else full_id
    return remainder.split("_", 1)[0]


def normalize_label(label):
    s = label.lower()
    changed = True
    while changed:
        changed = False
        for p in sorted(PREFIX_STRIP, key=len, reverse=True):
            if s.startswith(p) and len(s) > len(p):
                s = s[len(p):]
                changed = True
                break
    for suf in SUFFIX_STRIP:
        if s.endswith(suf) and len(s) > len(suf):
            s = s[: -len(suf)]
            break
    return ABBREVIATIONS.get(s, s)


def best_matches(norm_label, candidates):
    scored = []
    for full_id, cand_norm, cand_raw in candidates:
        ratio = SequenceMatcher(None, norm_label, cand_norm).ratio()
        scored.append((ratio, full_id, cand_raw))
    scored.sort(key=lambda t: -t[0])
    return scored


def main():
    prod_files = sorted(glob.glob(os.path.join(ROOT, "Formulate_Response_*.yaml")))
    test_dirs = sorted(
        d for d in glob.glob(os.path.join(ROOT, "*"))
        if os.path.isdir(d) and (os.path.basename(d).startswith("Jack_") or os.path.basename(d).startswith("Jon_"))
    )

    print(f"Production files scanned: {len(prod_files)}")
    for pf in prod_files:
        print(f"  {os.path.basename(pf)}")
    print(f"Test folders scanned: {len(test_dirs)}")
    for d in test_dirs:
        print(f"  {os.path.basename(d)}")
    print()

    # ---- production inventory ----
    prod_index = {}
    for pf in prod_files:
        fname = os.path.basename(pf)
        for line_no, full_id in extract_ks_refs(pf):
            label = guess_label(full_id)
            norm = normalize_label(label)
            entry = prod_index.setdefault(full_id, {"label": label, "norm": norm, "locations": [], "file": fname})
            entry["locations"].append(f"{fname}:{line_no}")

    prod_all_candidates = [(fid, e["norm"], e["label"]) for fid, e in prod_index.items()]
    prod_by_file = {}
    for fid, e in prod_index.items():
        prod_by_file.setdefault(e["file"], []).append((fid, e["norm"], e["label"]))

    print(f"Distinct production knowledge-source IDs found: {len(prod_index)}")
    print()

    # ---- test inventory (one row per distinct full_id per folder) ----
    test_rows = []
    for d in test_dirs:
        folder_name = os.path.basename(d)
        files = sorted(glob.glob(os.path.join(d, "*.yaml")) + glob.glob(os.path.join(d, "*.yml")))
        files = [f for f in files if not os.path.basename(f).lower().endswith(".production_ready.yaml")
                 and not os.path.basename(f).lower().endswith(".production_ready.yml")]
        folder_ids = {}
        for f in files:
            for line_no, full_id in extract_ks_refs(f):
                info = folder_ids.setdefault(full_id, {"file": os.path.basename(f), "locations": []})
                info["locations"].append(f"{os.path.basename(f)}:{line_no}")

        prod_file_name = FOLDER_TO_PROD_FILE.get(folder_name)
        pool = prod_by_file.get(prod_file_name, prod_all_candidates)
        scope_note = prod_file_name if prod_file_name in prod_by_file else "ALL production files (no scoped match found)"

        print(f"{folder_name}: {len(folder_ids)} distinct ID(s), matched against {scope_note}")

        for full_id, info in folder_ids.items():
            label = guess_label(full_id)
            norm = normalize_label(label)
            scored = best_matches(norm, pool)

            prod_id = ""
            status = "NO PRODUCTION MATCH"
            candidates_str = f"(no knowledge sources found in {scope_note})"

            if scored:
                top_ratio, top_id, top_label = scored[0]
                second_ratio = scored[1][0] if len(scored) > 1 else 0.0
                if top_ratio >= AUTOFILL_RATIO and (top_ratio - second_ratio) >= AUTOFILL_MARGIN:
                    prod_id = top_id
                    status = "Auto-matched - please confirm"
                    candidates_str = f"{top_label} ({top_ratio:.2f})"
                else:
                    close = [s for s in scored if s[0] >= HINT_RATIO][:3]
                    if close:
                        status = "AMBIGUOUS" if (len(close) >= 2 and close[0][0] >= 0.6) else "NO CONFIDENT MATCH"
                        candidates_str = "; ".join(f"{lbl} ({r:.2f})" for r, _, lbl in close)
                        candidates_str += " | IDs: " + "; ".join(fid for r, fid, lbl in close)
                    else:
                        status = "NO CONFIDENT MATCH"
                        candidates_str = f"(no candidate in {scope_note} scored above {HINT_RATIO})"

            test_rows.append({
                "SourceFolder": folder_name,
                "SourceFile": info["file"],
                "UsedIn": "; ".join(info["locations"]),
                "TestKnowledgeSourceID": full_id,
                "GuessedLabel": label,
                "ProductionKnowledgeSourceID": prod_id,
                "Status": status,
                "Candidates": candidates_str,
                "Notes": "",
            })
    print()

    # ---- incremental merge with existing workbook ----
    existing = {}
    if os.path.exists(OUT_XLSX):
        wb_old = openpyxl.load_workbook(OUT_XLSX, data_only=True)
        if "Mapping" in wb_old.sheetnames:
            ws_old = wb_old["Mapping"]
            headers_old = [c.value for c in ws_old[1]]
            for r in ws_old.iter_rows(min_row=2, values_only=True):
                row = dict(zip(headers_old, r))
                tid = row.get("TestKnowledgeSourceID")
                if tid:
                    existing[tid] = row

    found_ids = {row["TestKnowledgeSourceID"] for row in test_rows}
    preserved_count = 0
    for row in test_rows:
        old = existing.get(row["TestKnowledgeSourceID"])
        if old:
            if old.get("Notes"):
                row["Notes"] = old["Notes"]
            if old.get("ProductionKnowledgeSourceID"):
                row["ProductionKnowledgeSourceID"] = old["ProductionKnowledgeSourceID"]
                row["Status"] = "Confirmed"
                preserved_count += 1

    stale_rows = []
    for tid, old in existing.items():
        if tid not in found_ids:
            stale = {h: old.get(h, "") for h in HEADERS}
            stale["Status"] = "STALE - not found in any current Jack/Jon file"
            stale_rows.append(stale)

    final_rows = test_rows + stale_rows

    # ---- write workbook ----
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Mapping"
    ws.append(HEADERS)
    for row in final_rows:
        ws.append([row.get(h, "") for h in HEADERS])

    wrap = Alignment(wrap_text=True, vertical="top")
    for row in ws.iter_rows(min_row=1, max_row=ws.max_row, min_col=1, max_col=len(HEADERS)):
        for cell in row:
            cell.alignment = wrap

    widths = {"A": 16, "B": 38, "C": 30, "D": 42, "E": 22, "F": 42, "G": 26, "H": 50, "I": 30}
    for col, w in widths.items():
        ws.column_dimensions[col].width = w

    last_row = len(final_rows) + 1
    last_col_letter = get_column_letter(len(HEADERS))
    tbl = Table(displayName="KS_Mapping", ref=f"A1:{last_col_letter}{last_row}")
    tbl.tableStyleInfo = TableStyleInfo(
        name="TableStyleMedium2", showFirstColumn=False,
        showLastColumn=False, showRowStripes=True, showColumnStripes=False,
    )
    ws.add_table(tbl)

    # Dictionaries sheet: list of known production IDs, backs the dropdown
    dict_ws = wb.create_sheet("Dictionaries")
    dict_ws["A1"] = "ProductionKnowledgeSourceID"
    dict_ws["B1"] = "GuessedLabel"
    dict_ws["C1"] = "SourceFile"
    r = 2
    for fid, e in sorted(prod_index.items(), key=lambda kv: kv[1]["label"].lower()):
        dict_ws.cell(row=r, column=1, value=fid)
        dict_ws.cell(row=r, column=2, value=e["label"])
        dict_ws.cell(row=r, column=3, value=e["file"])
        r += 1
    dict_last_row = r - 1
    dict_ws.column_dimensions["A"].width = 55
    dict_ws.column_dimensions["B"].width = 30
    dict_ws.column_dimensions["C"].width = 38

    prod_col_letter = get_column_letter(HEADERS.index("ProductionKnowledgeSourceID") + 1)
    dv = DataValidation(type="list", formula1=f"Dictionaries!$A$2:$A${dict_last_row}",
                         allow_blank=True, showDropDown=False)
    dv.error = "Please choose a production knowledge-source ID from the dropdown (or paste one from the Dictionaries tab)."
    dv.errorTitle = "Unknown production ID"
    ws.add_data_validation(dv)
    dv.add(f"{prod_col_letter}2:{prod_col_letter}{last_row}")

    # ReadMe sheet
    readme_ws = wb.create_sheet("ReadMe", 0)
    readme_lines = [
        "KS_Mapping_Table - Jack/Jon test knowledge sources -> production knowledge sources",
        "",
        "Each row is one distinct knowledge-source ID found in a Jack_*/Jon_* test folder.",
        "ProductionKnowledgeSourceID: the production ID it should become before you paste a",
        "  confirmed topic into Copilot Studio. Auto-filled when confident; left blank when",
        "  ambiguous or when there's no production equivalent yet - check the Candidates column.",
        "Status: Auto-matched - please confirm | AMBIGUOUS | NO CONFIDENT MATCH | NO PRODUCTION MATCH",
        "  | Confirmed (you filled it in, or accepted a prior auto-match - preserved on re-run)",
        "  | STALE (ID no longer found in any current Jack/Jon file - kept for reference)",
        "Candidates: best-guess production matches with similarity scores, for you to pick from",
        "  when the row is blank. The dropdown on ProductionKnowledgeSourceID is restricted to",
        "  the Dictionaries tab so you can't typo a production ID.",
        "",
        "Re-run build_ks_mapping_table.py any time Jack/Jon add new test topics - it merges in",
        "new IDs without touching rows you've already filled in or annotated.",
        "",
        "Once this table is in good shape, run apply_ks_mapping.py against a specific Jack/Jon",
        "yaml file to produce a '<name>.production_ready.yaml' with the IDs swapped in - that's",
        "what you paste into Copilot Studio. Unmapped references are left untouched and printed",
        "as warnings so you know exactly which ones still need manual reselection.",
    ]
    for i, line in enumerate(readme_lines, start=1):
        readme_ws.cell(row=i, column=1, value=line)
    readme_ws.column_dimensions["A"].width = 100

    wb.save(OUT_XLSX)

    # ---- summary ----
    autofilled = sum(1 for r in test_rows if r["Status"] == "Auto-matched - please confirm")
    ambiguous = sum(1 for r in test_rows if r["Status"] == "AMBIGUOUS")
    no_match = sum(1 for r in test_rows if r["Status"] in ("NO PRODUCTION MATCH", "NO CONFIDENT MATCH"))

    print("=" * 90)
    print("SUMMARY")
    print("=" * 90)
    print(f"Total test knowledge-source IDs: {len(test_rows)}")
    print(f"  Auto-matched (please confirm): {autofilled}")
    print(f"  Ambiguous (multiple candidates): {ambiguous}")
    print(f"  No confident match: {no_match}")
    print(f"Preserved from previous run (already confirmed/typed): {preserved_count}")
    print(f"Stale rows carried forward (not found this run): {len(stale_rows)}")
    print(f"\nSaved: {OUT_XLSX}")


if __name__ == "__main__":
    main()
