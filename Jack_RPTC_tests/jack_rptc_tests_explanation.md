# Jack RPTC Tests

## Overview

Testing focused on the RPTC `Formulate_Response` topic and the `Question_Enhancer`. The core problem investigated was why the agent consistently failed first-pass subfolder searches and fell back to the broader RPTC knowledge source, and whether retrieval quality and consistency could be improved.

Full results are in `RPTC Comparison File uploadvsbroad.xlsx`.

---

## Background: Why Subfolders Fail

RPTC knowledge is split into two subfolders:
- **Guidance and templates** — 6 documents (activity proposal template, activity report template, IRA guidelines, common reporting standards, RPTC guidelines, Readme.txt)
- **Progress reports** — 11 documents (reports 1–10 plus Readme.txt)

The guidance subfolder is too small for reliable vector search. With only 6 documents, all chunks score similarly and nothing clears the relevance threshold consistently. The progress reports subfolder (11 docs) performs better due to greater volume and diversity. This is a fundamental property of vector search on small, homogeneous corpora — not a configuration or prompt problem.

The SharePoint connector (keyword search) was also tested on these subfolders prior to switching to file upload. Keyword search performed worse than vector search on small corpora because all documents are topically similar and relevance scores cluster even more tightly.

---

## Approach 1: File Upload with Subfolder Routing + Fallback

**File:** `Formulate_Response_RPTC_File_Upload.yml`

### Structure

- **Pass 1A** — `rptc_progress_reports` topic area → searches progress reports subfolder (`RPTCprogressreports`)
- **Pass 1B** — guidance/template topic areas (14 topic area values) → searches guidance subfolder (`RPTCGuidanceandtemplates`)
- **Pass 1 else** — unrecognised topic areas → searches full RPTC folder (`RPTCFileUpload`)
- **Pass 2 (noResultFallback)** — if Pass 1 returns blank → searches full RPTC folder (`RPTCFileUpload`)

### Knowledge Source IDs (file upload)
- Progress reports subfolder: `copilots_header_3141e.topic.RPTCprogressreports_XYyUtMHo_PJP3fzcGI6Hh`
- Guidance and templates subfolder: `copilots_header_3141e.topic.RPTCGuidanceandtemplates_o7qVVnHqFpHKWMZb9RWwK`
- Full RPTC folder: `copilots_header_3141e.topic.RPTCFileUpload_vV7zz8x3_EXkXTX80LY34`

### Results Summary
- **17 testable questions**: 15 eventually answered (88%), 2 complete failures
- Complete failures: common reporting standards (`annex_4_common_reporting_standards_.pdf` likely has an indexing issue), 2024 achievements (10th progress report retrieval inconsistency)
- When the guidance subfolder finds the answer, source quality is high — actual template documents are retrieved with field-level detail
- When fallback to the full RPTC folder is used, progress reports dominate the results due to their volume (10 reports vs. 5 guidance docs)

---

## Approach 2: Broad Only

**File:** `Formulate_Response_RPTC_Broad_Only.yaml`

### Structure

Single `SearchAndSummarizeContent` against the full RPTC folder (`RPTCFileUpload`) for all topic areas. No subfolder routing, no fallback.

The `additionalInstructions` include source-type preference guidance:
- For guidance/template/governance questions: draw from RPTC guidelines and template documents first
- For progress report questions: draw from RPTC progress reports

### Results Summary
- **17 testable questions**: 11 eventually answered (65%), 5 complete failures
- Complete failures include questions the File Upload approach answered (planning/approval process, programme design standards, challenges/recommendations)
- Template-specific questions (activity proposal template, activity report template) returned summary-level answers from `Readme.txt` rather than the actual template documents
- The elimination of subfolder routing did not improve overall reliability — the full RPTC corpus still suffers from progress report volume dominance

---

## Comparison: File Upload vs. Broad Only

| Metric | File Upload | Broad Only |
|---|---|---|
| Questions answered | 15 / 17 (88%) | 11 / 17 (65%) |
| Complete failures | 2 | 5 |
| Template questions (source quality) | High — actual docs found | Low — Readme.txt used |
| Governance/roles questions | Good — via fallback | Good — when found |
| Reliability (no second-try needed) | Moderate (fallback adds latency) | Lower (more outright failures) |

**File Upload with subfolder + fallback performs better overall**, primarily because it recovers the actual template documents for guidance questions. Broad Only's advantage (no failed first-pass step) is outweighed by complete failures on questions the File Upload approach answers, and lower source quality on template questions.


## Question Enhancer Update

**File:** `Question_Enhancer_updated.yaml`

### Problem

The original `userInput` formula passed the full JSON output of the question enhancer to vector search:

```
="User question: " & Global.userQuestion & Char(10) & Char(10) & 
"Question enhancements: " & Global.executiveQuestionEnhancements
```

Vector search embeds the entire input text as a single semantic vector. Passing a JSON blob — including field names, structural characters, and unrelated fields like `filters`, `retrieval_strategy`, `confidence_cautions` — dilutes the query vector and can shift it away from the semantic target. A large, keyword-heavy input produces a diffuse vector that achieves moderate similarity with many documents rather than high similarity with the right one.

### Change

Added a `reformulated_search_query` field to the enhancer output schema:

> Rewrite the user question as a single natural language sentence of 10–20 words optimised for vector search retrieval. Naturally incorporate 1–2 of the most relevant synonyms into the sentence. Write in the style of a sentence that would appear in a knowledge document on this topic. Do not use semicolons, keyword lists, or bullet points.

The `userInput` formula in Generate Answers cards becomes:

```
=If(IsBlank(Text(ParseJSON(Global.executiveQuestionEnhancements).reformulated_search_query)), 
    Global.userQuestion, 
    Text(ParseJSON(Global.executiveQuestionEnhancements).reformulated_search_query))
```

The fallback to `Global.userQuestion` protects against enhancer failures. The existing `synonyms_and_search_terms` field is retained for use in `additionalInstructions` at the generation step.

### Observed Effect

The enhancer now produces clean, natural language queries (e.g. "What are the financial rules and budget guidelines for the Regular Programme of Technical Cooperation?"). The guidance subfolder threshold problem persists regardless of query quality — confirming that corpus size, not query phrasing, is the root cause of first-pass failures.

---

## Outstanding Issues

| Issue | Status |
|---|---|
| `annex_4_common_reporting_standards_.pdf` never retrieved | Likely PDF extraction/indexing problem — no query change will fix it |
| 10th progress report (2024 achievements) inconsistent | Threshold variance — second try usually succeeds |
| Progress reports dominate full RPTC source for guidance questions | Volume imbalance (10 reports vs. 5 guidance docs); no prompt change resolves this fully |
| Question Enhancer returns malformed JSON after funding stream clarification | Separate bug — prompt or invocation issue in post-clarification flow |
| `evaluation_design` topic area not in guidance condition list | `design_evaluation` is listed but `evaluation_design` is not — hits elseActions instead |
