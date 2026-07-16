# Meeting Summary

## Description
Retrieves and structures key decisions, discussion points, and outcomes from a specified CDSC or TAG meeting, or compares findings across multiple meetings.

## Trigger
Use this skill when the user asks for something like:
- "summarise the [year] CDSC meeting"
- "what was decided at the TAG meeting in [year]?"
- "what has the steering committee discussed about [topic]?"
- "compare TAG decisions across years on [topic]"
- "what were the outcomes of the last steering committee meeting?"

Do not use this skill for simple single-fact lookups from a meeting document — answer those directly.

## Instructions

### Step 1 — Identify the meeting type and scope
Determine from the user's request:
1. **Meeting body**: CDSC (Capacity Development Steering Committee) or TAG (Technical Advisory Group)
2. **Year or range**: A specific year, a range of years, or all available years
3. **Topic focus** (if any): A specific agenda item or theme the user wants to trace across meetings

If the meeting body or year is ambiguous, ask the user to confirm before searching.

### Step 2 — Search and retrieve
Search the relevant knowledge source (CDSC or TAG meetings folder) using the meeting body name, year, and any topic focus as retrieval anchors. Aim to retrieve content from all meetings in the specified scope, not just the first match.

### Step 3 — Structure the summary
Organise findings using the format below. Adjust sections based on what the retrieved documents actually contain — only include a section if the source supports it.

---

**Meeting Summary: [CDSC / TAG] — [Year or range]**
*Source: PD [Steering Committee / TAG] Meetings knowledge source*

**Meeting overview**
Date(s), attendees or quorum noted, and any stated purpose or agenda, drawn directly from the document.

**Key decisions**
Bullet-point list of decisions made, attributed to the specific meeting and document they appear in.

**Discussion highlights**
Main topics discussed, as recorded in the minutes or background notes. Do not paraphrase beyond what the document states.

**Action items** *(include only if explicitly listed in the document)*
Actions assigned, with owner and deadline if stated.

**Cross-meeting comparison** *(include only if multiple years are in scope)*
Describe how decisions or discussion on a topic have evolved across meetings, based only on what the documents explicitly state. Note years where a topic does not appear.

**Gaps and limitations**
Note any years or meetings not covered by retrieved documents, and any sections of the minutes that were unclear or incomplete.

**Sources**
List every document used:
> [File name](SharePoint URL) — Meeting date/year: [if known]

---

### Step 4 — Offer next steps
After delivering the summary, ask:
> "Would you like to go deeper on a specific decision, trace a topic across more years, or look at the other meeting body?"

## Notes
- Do not paraphrase or interpret decisions beyond what the document states. If the minutes use qualified language ("the committee noted", "it was suggested"), reproduce that framing rather than presenting it as a firm decision.
- If the requested year's meeting is not in the knowledge source, say so clearly and offer the nearest available year.
- CDSC and TAG are separate bodies — do not mix their records unless the user explicitly asks for a combined view.
