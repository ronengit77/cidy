"""
parse_country_data_database.py

Parses Cidy Country Data .docx files into a normalized multi-sheet Excel
database (Countries, Projects, Requests, Proposals, Activities).

This is a secondary script for analytics and Dataverse use.
For the live SharePoint list, use parse_country_data.py instead.

Requirements:
    pip install python-docx openpyxl pandas

Usage:
    python parse_country_data_database.py
"""

from pathlib import Path
import pandas as pd

from parse_country_data import DOCX_FOLDER, parse_docx, _clean_int, _clean_money

OUTPUT_PATH = Path(__file__).parent / "country_data_database.xlsx"


# ── DATABASE BUILDER ──────────────────────────────────────────────────────────

def build_dataframes(all_results):
    countries, projects, requests, proposals, activities = [], [], [], [], []

    for r in all_results:
        cc = r["country_code"]
        m  = r.get("metrics", {})

        countries.append({
            "country_code":            cc,
            "country_name":            r["country_name"],
            "region":                  r["region"],
            "country_type":            r["country_type"],
            "snapshot_date":           r["snapshot_date"],
            "export_date":             r["export_date"],
            "total_projects":          _clean_int(m.get("Projects")),
            "project_budget":          _clean_money(m.get("Project budget")),
            "total_requests":          _clean_int(m.get("Requests")),
            "total_proposals":         _clean_int(m.get("RPTC proposals")),
            "proposal_planned_budget": _clean_money(m.get("Proposal planned budget")),
            "total_activities":        _clean_int(m.get("RPTC activities")),
            "consumed_rptc_budget":    _clean_money(m.get("Consumed RPTC budget")),
            "activity_participants":   _clean_int(m.get("Activity participants")),
            "women_participants":      _clean_int(m.get("Women participants")),
            "travel_records":          _clean_int(m.get("Travel records")),
            "travel_cost":             _clean_money(m.get("Travel cost")),
            "data_quality_note_count": _clean_int(m.get("Data quality notes")),
            "filename":                r["filename"],
        })

        for p in r["projects"]:
            projects.append({"country_code": cc, **p})
        for req in r["requests"]:
            requests.append({"country_code": cc, **req})
        for prop in r["proposals"]:
            proposals.append({"country_code": cc, **prop})
        for act in r["activities"]:
            activities.append({"country_code": cc, **act})

    return (
        pd.DataFrame(countries),
        pd.DataFrame(projects),
        pd.DataFrame(requests),
        pd.DataFrame(proposals),
        pd.DataFrame(activities),
    )


# ── EXCEL OUTPUT ──────────────────────────────────────────────────────────────

def write_excel(dfs, output_path):
    df_countries, df_projects, df_requests, df_proposals, df_activities = dfs
    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        df_countries.to_excel(writer,  sheet_name="Countries",  index=False)
        df_projects.to_excel(writer,   sheet_name="Projects",   index=False)
        df_requests.to_excel(writer,   sheet_name="Requests",   index=False)
        df_proposals.to_excel(writer,  sheet_name="Proposals",  index=False)
        df_activities.to_excel(writer, sheet_name="Activities", index=False)
    print(f"Database Excel written -> {output_path}")


# ── ENTRY POINT ───────────────────────────────────────────────────────────────

def main():
    docx_files = sorted(DOCX_FOLDER.glob("*.docx"))
    print(f"Parsing {len(docx_files)} file(s)\n")

    all_results, errors = [], []
    for f in docx_files:
        try:
            r = parse_docx(f)
            all_results.append(r)
            print(f"  {r['country_code']:12s} projects={len(r['projects']):3d}  "
                  f"requests={len(r['requests']):3d}  proposals={len(r['proposals']):3d}  "
                  f"activities={len(r['activities']):3d}")
        except Exception as e:
            errors.append((f.name, str(e)))
            print(f"  ERROR {f.name}: {e}")

    if errors:
        print(f"\n{len(errors)} file(s) failed:")
        for name, msg in errors:
            print(f"  {name}: {msg}")

    dfs = build_dataframes(all_results)
    write_excel(dfs, OUTPUT_PATH)

    df_countries, df_projects, df_requests, df_proposals, df_activities = dfs
    print(f"\nRow counts:")
    print(f"  Countries:  {len(df_countries)}")
    print(f"  Projects:   {len(df_projects)}")
    print(f"  Requests:   {len(df_requests)}")
    print(f"  Proposals:  {len(df_proposals)}")
    print(f"  Activities: {len(df_activities)}")


if __name__ == "__main__":
    main()
