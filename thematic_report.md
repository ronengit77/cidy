# Thematic Report

## Purpose
Generate a structured thematic report by synthesising findings across multiple RPTC documents on a user-specified topic. Used when the user wants a cross-document analysis rather than an answer from a single source.

## Trigger
Use this skill when the user asks for something like:
- "give me a thematic analysis of..."
- "what are the recurring themes in..."
- "summarise recommendations across years on..."
- "compare findings on [topic] across progress reports"
- "produce a report on..."
- "what does RPTC say across its reports about..."

Do not use this skill for simple single-document lookups or factual questions answerable from one source.

## Instructions

Follow these steps in order:

### Step 1 — Clarify scope
Before searching, confirm with the user:
1. **Theme or topic**: What specific subject should the report cover? (e.g., SIDS support, gender inclusion, IRA effectiveness, country demand trends)
2. **Year range**: Should the report cover all available years, or a specific period?
3. **Source type**: Should it draw from progress reports only, guidance documents only, or both?

If the user's original request already makes these clear, proceed without asking.

### Step 2 — Search and retrieve
Search the connected RPTC knowledge source using the confirmed theme and scope. Aim to retrieve relevant content from as many documents as possible within the specified range, not just the first match.

### Step 3 — Synthesise findings
Organise findings into the following report structure. Only include a section if the retrieved documents contain relevant content for it.

---

**Thematic Report: [Topic]**
*Source: RPTC knowledge base | Years covered: [range] | Document types: [progress reports / guidance / both]*

**Overview**
A 2–3 sentence summary of what the retrieved documents collectively say about this theme.

**Key findings**
Bullet-point findings drawn directly from document content. For each finding, attribute it to the specific document and year it comes from.

**Trends over time** *(include only if multiple years are covered)*
Describe how the theme has evolved across years, based on what the documents explicitly state. Note years where the theme is not addressed or data is absent.

**Recommendations and lessons** *(include only if present in retrieved documents)*
List any recommendations or lessons explicitly related to the theme, attributed to their source document.

**Gaps and limitations**
State clearly:
- Which years or sub-topics were not covered by retrieved documents
- Where document content was thin, ambiguous, or contradictory
- Any counts or trends that could not be confirmed from the available documents

**Sources**
List every document that contributed to this report:
> [File name](SharePoint URL) — Year: [year if known]

---

### Step 4 — Confirm with the user
After delivering the report, ask:
> "Would you like me to go deeper on any section, filter to a specific year, or expand to a related topic?"

## Notes
- Do not present the report as exhaustive if not all documents in the knowledge source were retrieved. State how many documents were consulted.
- Do not fabricate trends. If only one or two data points exist for a trend, describe them as isolated findings rather than a trend.
- Do not merge content from different documents as though it came from one source.
- If the knowledge source returns no relevant content for the specified theme, say: "I found no RPTC documents with sufficient content on [topic] to produce a thematic report." Then suggest a related alternative if one is obvious.
