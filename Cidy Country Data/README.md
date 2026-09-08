# Cidy Country Data — Process Documentation

## Overview

This folder contains the scripts and outputs for parsing UN DESA CDPMO country-level engagement data from source `.docx` files into structured Excel outputs for use in SharePoint and analytics.

The primary output is a **flat SharePoint list** (`country_data_sharepoint.xlsx`) containing all records (Requests, Projects, Proposals, Activities) across 204 countries in a single table. This list powers the Cidy Country Data knowledge source in Copilot Studio.

---

## Folder Contents

| File | Purpose |
|------|---------|
| `parse_country_data.py` | Primary script — parses all `.docx` files and writes the SharePoint Excel |
| `parse_country_data_database.py` | Secondary script — generates the normalized multi-sheet database Excel |
| `country_data_sharepoint.xlsx` | Flat list output — uploaded to SharePoint via Power Automate |
| `country_data_database.xlsx` | Normalized database output — 5 sheets for analytics/Dataverse |
| `country_data_instructions.md` | Copilot Studio agent instructions for the Cidy Country Data agent |
| `Cidy Country Data.csv` | Most recent export from the SharePoint list (for verification) |

---

## Source Files

Country data `.docx` files live at:
```
Knowledge/Programme Development/Cidy - Country Data/
```

Each file is named using the pattern:
```
{country_code}-prjct-{n}-rqst-{n}-prpsl-{n}-act-{n}-trvl-{n}-cntct-{n}-{date}.docx
```

The scripts automatically discover and process all `.docx` files in that folder, sorted alphabetically.

---

## Scripts

### `parse_country_data.py` — Primary (SharePoint)

Parses all source `.docx` files and writes `country_data_sharepoint.xlsx` — a single flat table formatted as an Excel Table named `AllRecords`.

**Run:**
```
python parse_country_data.py
```

**Test a single file:**
```
python parse_country_data.py jam-prjct-2-rqst-15-....docx
```

**Output columns (21 total):**

| Column | Type | Notes |
|--------|------|-------|
| country_code | Text | ISO code from filename (e.g. JAM, BGD) |
| country_name | Text | Full name parsed from document header |
| region | Text | Africa / Asia / Americas / Europe / Oceania |
| country_type | Text | LDC, LLDC, SIDS (space-separated if multiple) |
| snapshot_date | Text | Data cut-off date from document header |
| record_type | Text | Request / Project / Proposal / Activity |
| title | Text | Record title (can be very long for Requests) |
| division | Text | Responsible DESA division(s) |
| status | Text | e.g. Ongoing, Completed, Under consideration |
| start_date | Text | YYYY-MM-DD |
| end_date | Text | YYYY-MM-DD |
| budget | Text | Numeric string; blank for record types without budget |
| partner_countries | Text | Partner countries listed (Proposals/Projects only) |
| ref_number | Text | Request reference number (Requests only) |
| request_date | Text | Date request was submitted (Requests only) |
| contact | Text | Contact name and email (Requests only) |
| summary | Text | Full narrative description (Requests only) |
| project_id | Text | Project/proposal ID (Proposals/Activities only) |
| consumed_budget | Text | Consumed RPTC budget (Activities only) |
| participants | Text | Total participants (Activities only) |
| women_participants | Text | Women participants (Activities only) |

Fields that don't apply to a record type are left blank.

### `parse_country_data_database.py` — Secondary (Database/Analytics)

Generates `country_data_database.xlsx` with 5 normalized sheets: Countries, Projects, Requests, Proposals, Activities. Imports parsing functions from `parse_country_data.py` — both scripts must be in the same folder.

**Run:**
```
python parse_country_data_database.py
```

---

## SharePoint List

### Setup (one-time)

The SharePoint list **Cidy Country Data** was created by importing `country_data_sharepoint.xlsx` into SharePoint. The following column types must be set manually after creation:

| Column | Required type |
|--------|--------------|
| title | Multiple lines of text |
| division | Multiple lines of text |
| partner_countries | Multiple lines of text |
| summary | Multiple lines of text |
| budget | Single line of text |
| ref_number | Single line of text |
| consumed_budget | Single line of text |
| participants | Single line of text |
| women_participants | Single line of text |

All other columns: Single line of text.

### Refresh Process

When source `.docx` files are updated:

1. Run `parse_country_data.py` to regenerate `country_data_sharepoint.xlsx`
2. Upload `country_data_sharepoint.xlsx` to OneDrive (replace existing file)
3. Trigger the **Country Data Refresh** Power Automate flow manually

The flow:
- Gets and deletes all existing SharePoint list items
- Reads all 3,304 rows from the Excel table (pagination enabled, threshold 5,000)
- Creates a new SharePoint list item for each row

### Power Automate Flow — Column Mapping Notes

For numeric fields that may be blank, use an expression instead of direct mapping to avoid type errors:

```
if(empty(items('Apply_to_each')?['budget']), null, items('Apply_to_each')?['budget'])
```

Apply this pattern to: `budget`, `ref_number`, `consumed_budget`, `participants`, `women_participants`.

---

## Copilot Studio Agent

The **Cidy Country Data** agent in Copilot Studio uses the SharePoint list as its knowledge source. Agent instructions are in `country_data_instructions.md`.

The agent is reached via the Cidy Daisy orchestrator when questions are about a specific country or DESA's work in a country.

---

## Data Statistics (as of June 2026 snapshot)

| Metric | Count |
|--------|-------|
| Countries / entities | 204 |
| Total records | 3,304 |
| Requests | 2,932 |
| Projects | 127 |
| Proposals | 128 |
| Activities | 117 |
