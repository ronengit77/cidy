# Jack PD Tests

## Overview

Testing focused on the Programme Development (PD) `Formulate_Response` topic. Two retrieval approaches were compared: narrow-to-broad (specific subfolder first, fallback to full corpus) and broad-to-narrow (full corpus first, fallback to specific subfolder). The core question was whether routing to specific subfolders improves source precision and answer quality compared to starting with the full PD knowledge base.

Full results are in `PD Comparison File NB vs BN.xlsx`.

---

## Background: PD Knowledge Structure

PD knowledge is split across eight subfolders within the broader `PD All` source:

| Subfolder | Knowledge Source ID |
|---|---|
| Steering Committee Meetings | `copilots_header_3141e.topic.PDSteeringCommitteeMeetings_z7GPixGVKf7DyA1Gcfd3R` |
| TAG Meetings | `copilots_header_3141e.topic.PDTAGMeetingsFileUpload_g8Dr4fDRx1UETjikXpbPa` |
| Projects / Evaluations | `copilots_header_3141e.topic.PDFileUpload_2jgoCTVdUcDDKUHd_xM9f` |
| Guidelines and Templates | `copilots_header_3141e.topic.PDGuidelinesandtemplates_TZDN7cnLS12tq0nY9ozDR` |
| Implementing Partners and Grants | `copilots_header_3141e.topic.PDImplementingPartnersandGrants_s6lDxcZ6AfXJwO3i9RKyf` |
| Resident Coordinator (RC) — two sources | `copilots_header_3141e.topic.CidyPDRC_3eeGCP3GTHDQ54COW1rW_` + `copilots_header_3141e.topic.PDRCFileUpload_NzkQjgVWtvuILEKEDdMvj` |
| CD Strategy | `copilots_header_3141e.topic.PDStrategyFileUpload_bZ94eM4vrVH5LkZCDRAA1` |
| Country Data | `copilots_header_3141e.topic.PDCountryDataFileUpload_DjIy3ZKRFMnjIw67L9atc` |
| Full PD All (broadest) | `copilots_header_3141e.topic.CidyPDAll_fpi14G9BVgM81C1jP17J5` |

The country_data subfolder requires special handling. Country card retrieval is anchored to a specific query built from the `detected_country_iso3` field plus a fixed set of retrieval anchors (`country card country record compact country file region subregion...`). This enhanced query is only applied in the narrow fallback pass — the broad pass uses standard `userInput` for all topics including country_data.

---

## Approach 1: Narrow-Broad (File Upload with Subfolder Routing + Fallback)

**File:** `Formulate_Response_Programme_Development_File_Upload.yaml`

### Structure

- **Pass 1** — routes to the matching subfolder based on `Global.topicArea`:
  - `steering_committee` → Steering Committee Meetings
  - `tag_meetings` → TAG Meetings
  - `guidelines_templates` → Guidelines and Templates
  - `implementing_partners_grants` → Implementing Partners and Grants
  - `resident_coordinator` → both RC sources
  - `cd_strategy` → CD Strategy
  - `projects_evaluations` → Projects / Evaluations
  - `country_data` → enhanced query + Country Data
  - else → Full PD All
- **Pass 2 (fallback)** — if Pass 1 returns blank → Full PD All (standard userInput)

### Results Summary

- **13 testable questions**: 13 answered (100%), 0 complete failures
- Subfolder routing correctly recovers precise sources for R11/R12 (RC policy), R4 (Steering Committee), R2 (evaluations)
- R14 (five service lines) misrouted to `country_data` instead of `cd_strategy` — answer hallucinated from country card files
- R6 (PD guidance in Cidy) misrouted through Cidy architecture topic rather than PD knowledge — meta answer returned
- R9 (IP agreement) required a second manual test run to succeed

---

## Approach 2: Broad-Narrow (Full Corpus First, Subfolder Fallback)

**File:** `Formulate_Response_PD_Broad_to_Narrow.yaml`

### Structure

- **Pass 1** — `SearchAndSummarizeContent` against the full `PD All` source for all topics (including country_data, using standard userInput)
- **Pass 2 (fallback)** — if Pass 1 returns blank → Nested ConditionGroup routes to the matching subfolder:
  - Same 8 topic conditions as narrow-broad
  - country_data uses the enhanced ISO3-anchored query in the narrow fallback
  - elseActions → retries Full PD All

### Results Summary

- **13 testable questions**: 11 answered (85%), 2 complete failures
- Complete failures: R11 (CCA/UNSDCF alignment) and R13 (DESA 2023 action areas) — both failed broad pass and narrow fallback
- R14 (five service lines) correctly retrieved via the broad pass (undesa-cdo-strategy + DESA Strategy March 2017)
- R10 (due diligence) retrieved both the guidelines and annexes via the broad pass — better source coverage than narrow-broad
- R5 (TAG meetings) retrieved more sources via broad pass (minutes, ToR, concept note) — more comprehensive than narrow-broad

---

## Comparison

### Overall Retrieval Success

| | Narrow-broad | Broad-narrow |
|---|---|---|
| Questions answered | 13 / 13 (100%) | 11 / 13 (85%) |
| Complete failures | 0 | 2 (R11 UNSDCF, R13 DESA 2023) |

### Answer Quality (of answered questions)

| Quality | Narrow-broad | Broad-narrow |
|---|---|---|
| Excellent | 8 (62%) | 7 (64%) |
| Good | 3 (23%) | 2 (18%) |
| Adequate | 1 (8%) | 2 (18%) |
| Poor | 1 (8%) | 0 |

### Source Correctness (of answered questions)

| Sources | Narrow-broad | Broad-narrow |
|---|---|---|
| Yes | 9 (69%) | 8 (73%) |
| Partial | 2 (15%) | 1 (9%) |
| No | 2 (15%) | 2 (18%) |

### Question-by-Question Comparison

| Row | Topic | NB Quality | NB Sources | BN Quality | BN Sources | Winner |
|---|---|---|---|---|---|---|
| R2 | Evaluations – sustainability | Good | Partial | Adequate | No | Narrow-broad |
| R3 | CD strategy | Excellent | Yes | Good | Yes | Narrow-broad |
| R4 | Steering Committee | Excellent | Yes | Excellent | Yes | Tie |
| R5 | TAG meetings | Good | Yes | Excellent | Yes | Broad-narrow |
| R6 | PD guidance in Cidy | Adequate | No | Adequate | No | Tie (both wrong) |
| R7 | Final report template | Excellent | Yes | Excellent | Yes | Tie |
| R8 | Project doc preparation | Excellent | Yes | Good | Partial | Narrow-broad |
| R9 | IP agreement vs procurement | Excellent | Yes | Excellent | Yes | Tie |
| R10 | Due diligence | Good | Partial | Excellent | Yes | Broad-narrow |
| R11 | CCA/UNSDCF alignment | Excellent | Yes | N/A | N/A | Narrow-broad |
| R12 | UNCT membership | Excellent | Yes | Excellent | Yes | Tie |
| R13 | DESA 2023 action areas | Excellent | Yes | N/A | N/A | Narrow-broad |
| R14 | Five service lines | Poor | No | Excellent | Yes | Broad-narrow |

---

## Conclusion

**Narrow-broad is the stronger approach** due to its 100% retrieval rate versus 85% for broad-narrow. The two complete failures in broad-narrow (R11 and R13) represent cases where neither the broad pass nor the narrow fallback cleared the relevance threshold — the targeted subfolder routing in narrow-broad recovers these reliably.

Where broad-narrow wins (R5, R10, R14), the gains are real but outweighed by the failures:
- **R10**: the broad pass happens to retrieve both the guidelines and the annexes, giving better source coverage
- **R5**: the broad pass retrieves more TAG materials including minutes and ToR
- **R14**: the broad pass routes correctly to CD strategy docs where narrow-broad's topic classification misroutes to country_data

**Root cause of narrow-broad's R14 failure:** the topic classifier assigned `country_data` to a question about CD strategy service lines. This is a classification error, not a retrieval problem — fixing the classifier (or the topic detection logic) would close this gap without changing the retrieval architecture.

The pattern parallels RPTC: narrow-broad's ability to route directly to the right subfolder gives it higher reliability overall. The broad pass in broad-narrow is susceptible to threshold failures on the full corpus, and when those occur the narrow fallback does not always recover either.

---

## Outstanding Issues

| Issue | Status |
|---|---|
| R14 (five service lines) misrouted to `country_data` in narrow-broad | Topic classification error — `cd_strategy` questions with service line framing misclassified |
| R6 (PD guidance in Cidy) wrong routing in both approaches | Question is ambiguous — hits Cidy architecture topic rather than PD knowledge routing |
| R11 and R13 complete failures in broad-narrow | Threshold failure on full PD All corpus; RC and CD strategy subfolders are relatively small |
| country_data enhanced query only applies in narrow fallback pass | By design — broad pass uses standard userInput; enhanced query would not improve full-corpus recall |
