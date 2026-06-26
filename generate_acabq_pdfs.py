"""
Regenerate category-grouped ACABQ Q&A PDF knowledge files for Copilot Studio.

Run any time after updating ACABQ_QA_Complete_Tagged.xlsx:

    py generate_acabq_pdfs.py

Optional overrides:

    py generate_acabq_pdfs.py --input "path\\to\\file.xlsx" --outdir "path\\to\\outdir"

What it does (see printed output for full detail each run):
  1. Loads the QA sheet, prints sheet name / row count / headers.
  2. Keeps only rows where isDESA == "Yes" (case-insensitive); reports kept/dropped
     and any non-Yes/No values found.
  3. Skips rows with a blank Question or Answer (logs them).
  4. Groups the remaining rows by Category (whitespace-trimmed). Expects exactly
     9 distinct categories - if that count is off, it STOPS and prints the
     category list instead of guessing how to merge/split anything.
  5. Writes one PDF per category to --outdir, preserving full Question/Answer
     text and internal line breaks (no truncation, no rewording).
  6. Prints a final summary table, flags any output PDF under ~4KB, and shows
     the first Q&A block from one file so you can eyeball formatting.
"""

import argparse
import datetime
import os
import re
import sys
from xml.sax.saxutils import escape as xml_escape

try:
    import pandas as pd
    from reportlab.lib.pagesizes import LETTER
    from reportlab.lib.units import inch
    from reportlab.lib import colors
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, HRFlowable
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install requirements with:\n  py -m pip install pandas reportlab openpyxl")
    sys.exit(1)

REQUIRED_COLS = ["Question", "Answer", "SourceFile", "Category", "FilePathFull", "Year", "isDESA"]
EXPECTED_CATEGORY_COUNT = 9
TINY_FILE_THRESHOLD_BYTES = 4096

DEFAULT_INPUT = r"C:\Users\RRAPOPOR\Documents\Cidy testing\ACABQ_QA_Complete_Tagged.xlsx"
DEFAULT_OUTDIR = r"C:\Users\RRAPOPOR\Documents\Cidy testing\acabq_pdfs"


def sanitize_for_filename(category):
    s = re.sub(r"\s+", "_", category.strip())
    s = re.sub(r"[^A-Za-z0-9_\-]+", "_", s)
    s = re.sub(r"_+", "_", s).strip("_")
    return s


def text_to_paragraph_markup(text):
    """Escape XML-sensitive chars then convert newlines to <br/> for reportlab Paragraph."""
    s = str(text)
    s = s.replace("\r\n", "\n").replace("\r", "\n")
    s = xml_escape(s)
    s = s.replace("\n", "<br/>")
    return s


def is_blank(v):
    return pd.isna(v) or str(v).strip() == ""


def is_yes(v):
    return isinstance(v, str) and v.strip().lower() == "yes"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default=DEFAULT_INPUT, help="Path to the reviewed Excel file")
    parser.add_argument("--outdir", default=DEFAULT_OUTDIR, help="Directory to write PDFs into")
    args = parser.parse_args()

    src_xlsx = args.input
    out_dir = args.outdir

    if not os.path.exists(src_xlsx):
        print(f"STOP: input file not found: {src_xlsx}")
        sys.exit(1)

    # -----------------------------------------------------------------
    # Load
    # -----------------------------------------------------------------
    df_raw = pd.read_excel(src_xlsx, sheet_name="QA", engine="openpyxl")
    print(f"Loaded sheet 'QA' from {os.path.basename(src_xlsx)}")
    print(f"Total row count (data rows): {len(df_raw)}")
    print(f"Column headers detected: {list(df_raw.columns)}")
    print()

    lower_to_actual = {c.lower().strip(): c for c in df_raw.columns}
    col_map = {}
    missing = []
    for needed in REQUIRED_COLS:
        actual = lower_to_actual.get(needed.lower())
        if actual is None:
            missing.append(needed)
        else:
            col_map[needed] = actual

    if missing:
        print(f"STOP: required columns not found: {missing}")
        sys.exit(1)

    df = df_raw.rename(columns={v: k for k, v in col_map.items()})

    # -----------------------------------------------------------------
    # Filter: isDESA == Yes (case-insensitive)
    # -----------------------------------------------------------------
    from collections import Counter
    desa_raw_values = Counter(df["isDESA"].apply(lambda v: repr(v)))
    print("Distinct isDESA raw values found (with counts):")
    for val, cnt in desa_raw_values.items():
        print(f"  {val}: {cnt}")

    mask_yes = df["isDESA"].apply(is_yes)
    non_yes_values = sorted(set(repr(v) for v in df.loc[~mask_yes, "isDESA"]))
    if non_yes_values:
        print(f"\nValues treated as NOT Yes (excluded): {non_yes_values}")

    kept_df = df[mask_yes].copy()
    dropped_count = len(df) - len(kept_df)
    print(f"\nRows kept (isDESA = Yes): {len(kept_df)}")
    print(f"Rows dropped (not Yes): {dropped_count}")
    print()

    # -----------------------------------------------------------------
    # Data hygiene: blank Question or Answer
    # -----------------------------------------------------------------
    blank_mask = kept_df["Question"].apply(is_blank) | kept_df["Answer"].apply(is_blank)
    skipped_rows = kept_df[blank_mask]
    if len(skipped_rows):
        print(f"Rows skipped for blank Question/Answer: {len(skipped_rows)}")
        for _, r in skipped_rows.iterrows():
            print(f"  SourceFile={r.get('SourceFile')!r} Question={r.get('Question')!r} Answer={r.get('Answer')!r}")
    else:
        print("Rows skipped for blank Question/Answer: 0")

    clean_df = kept_df[~blank_mask].copy()
    print()

    # -----------------------------------------------------------------
    # Category validation
    # -----------------------------------------------------------------
    clean_df["Category"] = clean_df["Category"].astype(str).str.strip()
    cat_counts = clean_df["Category"].value_counts().sort_index()
    print(f"Distinct categories after filtering + trimming: {len(cat_counts)}")
    for cat, cnt in cat_counts.items():
        print(f"  {cat!r}: {cnt}")
    print()

    if len(cat_counts) != EXPECTED_CATEGORY_COUNT:
        print(f"STOP: expected exactly {EXPECTED_CATEGORY_COUNT} distinct categories, found "
              f"{len(cat_counts)}. Category list printed above - fix the source data "
              "(extra/missing/blank/near-duplicate category names) before re-running.")
        sys.exit(1)

    # -----------------------------------------------------------------
    # PDF generation
    # -----------------------------------------------------------------
    os.makedirs(out_dir, exist_ok=True)

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "TitleHeader", parent=styles["Title"], fontName="Helvetica-Bold",
        fontSize=20, spaceAfter=4,
    )
    subtitle_style = ParagraphStyle(
        "SubtitleHeader", parent=styles["Normal"], fontName="Helvetica",
        fontSize=11, textColor=colors.HexColor("#444444"), spaceAfter=16,
    )
    question_style = ParagraphStyle(
        "Question", parent=styles["Normal"], fontName="Helvetica-Bold",
        fontSize=11, leading=15, spaceAfter=8, textColor=colors.HexColor("#1a1a1a"),
    )
    answer_style = ParagraphStyle(
        "Answer", parent=styles["Normal"], fontName="Helvetica",
        fontSize=10.5, leading=14.5, spaceAfter=10,
    )
    meta_style = ParagraphStyle(
        "Meta", parent=styles["Normal"], fontName="Helvetica-Oblique",
        fontSize=8.5, leading=11, textColor=colors.HexColor("#666666"),
    )

    gen_date = datetime.date.today().strftime("%Y-%m-%d")
    summary_rows = []
    tiny_file_warnings = []
    first_block_preview = None

    for category, group in clean_df.groupby("Category", sort=True):
        group = group.reset_index(drop=True)
        n_entries = len(group)
        safe_cat = sanitize_for_filename(category)
        filename = f"ACABQ_QA_{safe_cat}_{n_entries}Q.pdf"
        out_path = os.path.join(out_dir, filename)

        doc = SimpleDocTemplate(
            out_path, pagesize=LETTER,
            leftMargin=0.85 * inch, rightMargin=0.85 * inch,
            topMargin=0.85 * inch, bottomMargin=0.85 * inch,
        )

        flow = []
        flow.append(Paragraph(xml_escape(category), title_style))
        flow.append(Paragraph(f"Generated: {gen_date} &nbsp;|&nbsp; Entries: {n_entries}", subtitle_style))
        flow.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#999999")))
        flow.append(Spacer(1, 14))

        for i, row in group.iterrows():
            q_markup = text_to_paragraph_markup(row["Question"])
            a_markup = text_to_paragraph_markup(row["Answer"])
            source_file = xml_escape(str(row["SourceFile"])) if not pd.isna(row["SourceFile"]) else ""
            year_val = "" if pd.isna(row["Year"]) else str(row["Year"])
            year_val = xml_escape(year_val)
            path_val = xml_escape(str(row["FilePathFull"])) if not pd.isna(row["FilePathFull"]) else ""
            cat_val = xml_escape(category)

            flow.extend([
                Paragraph(f"Q: {q_markup}", question_style),
                Paragraph(a_markup, answer_style),
                Paragraph(f"Category: {cat_val} &nbsp;|&nbsp; Source: {source_file} &nbsp;|&nbsp; Year: {year_val}", meta_style),
                Paragraph(f"Path: {path_val}", meta_style),
                Spacer(1, 6),
                HRFlowable(width="100%", thickness=0.5, color=colors.HexColor("#cccccc")),
                Spacer(1, 14),
            ])

            if first_block_preview is None:
                first_block_preview = {
                    "category": category,
                    "filename": filename,
                    "question": str(row["Question"]),
                    "answer": str(row["Answer"]),
                    "source": str(row["SourceFile"]),
                    "year": year_val,
                    "path": str(row["FilePathFull"]),
                }

        doc.build(flow)

        file_size_bytes = os.path.getsize(out_path)
        text_char_count = group["Question"].astype(str).str.len().sum() + group["Answer"].astype(str).str.len().sum()

        summary_rows.append({
            "category": category,
            "entries": n_entries,
            "filename": filename,
            "size_bytes": file_size_bytes,
            "text_chars": int(text_char_count),
        })

        if file_size_bytes < TINY_FILE_THRESHOLD_BYTES:
            tiny_file_warnings.append((filename, file_size_bytes))

    # -----------------------------------------------------------------
    # Final summary
    # -----------------------------------------------------------------
    print("\n" + "=" * 100)
    print("SUMMARY")
    print("=" * 100)
    print(f"{'Category':<42} {'Entries':>8} {'Filename':<55} {'Size (KB)':>10}")
    print("-" * 120)
    total_entries = 0
    for r in summary_rows:
        total_entries += r["entries"]
        print(f"{r['category']:<42} {r['entries']:>8} {r['filename']:<55} {r['size_bytes']/1024:>9.1f}")

    print("-" * 120)
    print(f"Total entries exported: {total_entries}")
    print(f"Rows dropped (not DESA): {dropped_count}")
    print(f"Rows skipped (blank Q or A): {len(skipped_rows)}")
    print(f"PDF files written: {len(summary_rows)} -> {out_dir}")

    if tiny_file_warnings:
        print("\nWARNING - tiny output files (<4KB) that may index poorly:")
        for fn, sz in tiny_file_warnings:
            print(f"  {fn}: {sz} bytes")
    else:
        print("\nNo tiny-file warnings.")

    if first_block_preview:
        print("\n" + "=" * 100)
        print(f"FIRST Q&A BLOCK PREVIEW (from {first_block_preview['filename']}, category: {first_block_preview['category']})")
        print("=" * 100)
        print("Q:", first_block_preview["question"])
        print()
        print(first_block_preview["answer"])
        print()
        print(f"Category: {first_block_preview['category']}  |  Source: {first_block_preview['source']}  |  Year: {first_block_preview['year']}")
        print(f"Path: {first_block_preview['path']}")


if __name__ == "__main__":
    main()
