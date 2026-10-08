# Cidy Country Data — Quality Flags

Issues identified during data review (October 2026 snapshot). Flag these to the boss for follow-up.

---

## 1. Typo in source file — ARMANIA

**File:** `new_source_docs/armania-prjct-0-rqst-0-prpsl-0-act-0-trvl-1-cntct-0-26-10-05-14-20.docx`

This appears to be Armenia (`ARM`) but was exported with a typo in the filename. A separate correct `arm-...docx` file also exists, so Armenia data is currently split across two entries in the list.

**Action:** Ask boss to re-export Armenia as a single file with the correct code `arm`.

---

## 2. Three proposals with no title

Three rows in the SharePoint list have a blank `title` field. These may be formatting anomalies in the source `.docx` files.

| country_code | record_type | Count |
|---|---|---|
| RGN-ALL-REGIONS | Proposal | 2 |
| IND (India) | Proposal | 1 |

**Action:** Check the source `.docx` for `RGN-ALL-REGIONS` and `IND` proposals — look for proposals with missing or unusually formatted title rows.

---

## 3. European countries with unexpectedly low record counts

These mid-sized European countries have only 1 record each, which seems low compared to similar countries.

| country_code | Record count | Record type |
|---|---|---|
| CZE (Czech Republic) | 1 | Proposal |
| HRV (Croatia) | 1 | Proposal |
| LVA (Latvia) | 1 | Request |
| MLT (Malta) | 1 | Travel |
| SVK (Slovakia) | 1 | Request |
| SVN (Slovenia) | 1 | Request |

**Action:** Confirm with boss whether these countries have limited engagement or whether data may be missing from the export.

---

## 4. Territories and groups with no region assigned

The following country codes have a blank `region` field. This may be expected (territories not assigned to a UN region in the system), but worth confirming.

`AMERICAN-SAMOA`, `ARUBA`, `CARIBBEAN`, `CENTRAL-AMERICA`, `FRENCH-POLYNESIA`, `GUAM`, `MAYOTTE`, `NEW-CALEDONIA`, `NORTHERN-MARIANA-ISLANDS`, `PITCAIRN`, `PUERTO-RICO`, `REUNION`, `SAINT-HELENA`, `TOKELAU`, `UNSPECIFIED-COUNTRY`, `WALLIS-AND-FUTUNA-ISLANDS`

Note: `RGN-ALL-REGIONS` also has no region — this is intentional (it represents multi-region records).

**Action:** Confirm whether these territories are expected to have no region, or if the source documents should include one.

---

*Reviewed: 2026-10-08*
