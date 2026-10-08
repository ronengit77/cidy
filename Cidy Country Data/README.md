# Cidy Country Data — Process Documentation

## Overview

This folder contains the scripts and outputs for parsing UN DESA CDPMO country-level engagement data from source `.docx` files into structured Excel outputs for use in SharePoint and analytics.

The primary output is a **flat SharePoint list** (`country_data_sharepoint.xlsx`) containing all records (Requests, Projects, Proposals, Activities, Travel, Evaluations) across 217 countries and entities in a single table. This list powers the Cidy Country Data knowledge source in Copilot Studio.

---

## Folder Contents

| File | Purpose |
|------|---------|
| `parse_country_data.py` | Primary script — parses all `.docx` files and writes the SharePoint Excel |
| `create_sharepoint_sample.py` | Generates a 6-row sample Excel for initial SharePoint list creation |
| `parse_country_data_database.py` | Secondary script — generates the normalized multi-sheet database Excel |
| `new_source_docs/` | Current source `.docx` files (update this folder when boss provides new exports) |
| `country_data_sharepoint.xlsx` | Flat list output — uploaded to SharePoint via Power Automate |
| `country_data_sharepoint_sample.xlsx` | 6-row sample for creating the SharePoint list (one row per record type) |
| `country_data_database.xlsx` | Normalized database output — 5 sheets for analytics/Dataverse |
| `country_data_instructions.md` | Copilot Studio agent instructions for the Cidy Country Data agent |
| `Cidy Country Data.csv` | Most recent export from the SharePoint list (for verification) |

---

## Source Files

Country data `.docx` files live in the `new_source_docs/` subfolder. Each file is named:
```
{country_code}-prjct-{n}-rqst-{n}-prpsl-{n}-act-{n}-trvl-{n}-cntct-{n}-{date}.docx
```

When the boss provides an updated export, replace the contents of `new_source_docs/` and re-run the script. The scripts automatically discover and process all `.docx` files in that folder, sorted alphabetically.

---

## Scripts

### `parse_country_data.py` — Primary (SharePoint)

Parses all source `.docx` files and writes `country_data_sharepoint.xlsx` — a single flat table formatted as an Excel Table named `AllRecords`.

**Run:**
```
python "C:\Users\woodj\Documents\cidy\Cidy Country Data\parse_country_data.py"
```

**Test a single file:**
```
cd "C:\Users\woodj\Documents\cidy\Cidy Country Data"
python parse_country_data.py bgd-prjct-11-rqst-45-....docx
```

**Output columns (32 total):**

| Column | SharePoint type | Populated for |
|--------|----------------|---------------|
| country_code | Single line | All |
| country_name | Single line | All |
| region | Single line | All |
| country_type | Single line | All (LDC / LLDC / SIDS) |
| snapshot_date | Single line | All |
| record_type | Single line | All (see record types below) |
| title | Multiple lines | All |
| division | Multiple lines | All |
| status | Single line | Project, Request |
| start_date | Single line | Project, Request, Proposal, Activity, Travel |
| end_date | Single line | Project, Request, Proposal, Activity, Travel |
| budget | Single line | Project, Proposal |
| partner_countries | Multiple lines | Project, Proposal, Evaluation |
| ref_number | Single line | Request |
| request_date | Single line | Request |
| contact | Single line | Request |
| summary | Multiple lines | Request |
| project_id | Single line | Proposal, Activity |
| consumed_budget | Single line | Activity |
| participants | Single line | Activity |
| women_participants | Single line | Activity |
| project_code | Single line | Project |
| scope | Single line | Project |
| travel_code | Single line | Travel |
| past_forecast | Single line | Travel |
| city | Single line | Travel |
| travel_reason | Single line | Travel |
| event_type | Single line | Travel |
| year | Single line | Evaluation |
| recommendations | Multiple lines | Evaluation |
| lessons_learned | Multiple lines | Evaluation |
| document_link | Single line | Evaluation |

Fields that don't apply to a record type are left blank.

**Record types:**

| record_type | Description |
|-------------|-------------|
| Request | Technical cooperation requests from countries |
| Project | Active or completed development projects |
| Proposal | RPTC activity proposals |
| Activity | RPTC activities with participant/budget data |
| Travel | Travel records (past and forecast) |
| Evaluation | Project evaluations with recommendations |

### `create_sharepoint_sample.py` — Sample for List Creation

SharePoint's "Import from Excel" is capped at 5,000 rows. Since the full dataset exceeds this limit, use this script to create a 6-row sample (one per record type) that SharePoint can import to set up the list columns. The Power Automate flow then loads all rows.

**Run after `parse_country_data.py`:**
```
python "C:\Users\woodj\Documents\cidy\Cidy Country Data\create_sharepoint_sample.py"
```

**Output:** `country_data_sharepoint_sample.xlsx` — 6 rows covering all 32 columns.

---

### `parse_country_data_database.py` — Secondary (Database/Analytics)

Generates `country_data_database.xlsx` with 5 normalized sheets: Countries, Projects, Requests, Proposals, Activities. Imports parsing functions from `parse_country_data.py` — both scripts must be in the same folder.

**Run:**
```
python parse_country_data_database.py
```

---

## SharePoint List

### Setup (one-time or after schema change)

The full dataset (6,228 rows) exceeds SharePoint's 5,000-row import limit. Use the sample file instead:

1. Run `parse_country_data.py` → generates `country_data_sharepoint.xlsx` (full data)
2. Run `create_sharepoint_sample.py` → generates `country_data_sharepoint_sample.xlsx` (6 rows)
3. In SharePoint, create a new list via **Import from Excel** using `country_data_sharepoint_sample.xlsx`
4. Fix column types (see below)
5. Upload `country_data_sharepoint.xlsx` to OneDrive and run the Power Automate flow to load all rows

After list creation, manually set the following column types in List Settings:

**Must be Multiple lines of text:**

| Column |
|--------|
| title |
| division |
| partner_countries |
| summary |
| recommendations |
| lessons_learned |

**Must be Single line of text (not Number):**

| Column | Reason |
|--------|--------|
| budget | Contains currency text |
| ref_number | Contains text/mixed values |
| consumed_budget | Contains currency text |
| participants | May be blank |
| women_participants | May be blank |
| travel_code | Contains text codes (e.g. T-2026-001) |
| year | Stored as text string |

All other columns will auto-detect correctly as Single line of text.

### Refresh Process

When the boss provides updated `.docx` files:

1. Replace the contents of `new_source_docs/` with the new files
2. Run `parse_country_data.py` to regenerate `country_data_sharepoint.xlsx`
3. Upload `country_data_sharepoint.xlsx` to OneDrive (replace the existing file)
4. Trigger the **Country Data Refresh** Power Automate flow manually

The flow:
- Deletes all existing SharePoint list items
- Reads all rows from the Excel table (pagination enabled, threshold 5,000)
- Creates a new SharePoint list item for each row

### Power Automate Flow — Column Mapping Notes

For numeric fields that may be blank, use an expression to send `null` instead of an empty string:

```
if(empty(items('Apply_to_each')?['budget']), null, items('Apply_to_each')?['budget'])
```

Apply this pattern to: `budget`, `ref_number`, `consumed_budget`, `participants`, `women_participants`.

All other fields map directly from dynamic content under "List rows present in a table".

If schema changes require recreating the "Create item" action, delete it and add a fresh one — this forces Power Automate to re-read the current column types from SharePoint rather than using a cached schema.

---

## Copilot Studio Agent

The **Cidy Country Data** agent in Copilot Studio uses the SharePoint list as its knowledge source. Agent instructions are in `country_data_instructions.md`.

The agent is reached via the Cidy Daisy orchestrator when questions are about a specific country or DESA's work in a country.

---

## Data Statistics (as of October 2026 snapshot)

| Metric | Count |
|--------|-------|
| Countries / entities | 217 |
| Total records | 6,228 |
| Requests | 2,979 |
| Travel | 1,136 |
| Evaluations | 847 |
| Projects | 561 |
| Proposals | 517 |
| Activities | 188 |
