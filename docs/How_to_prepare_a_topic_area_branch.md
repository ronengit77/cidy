# How to Prepare a Topic Area Branch in Cidy

A step-by-step guide for adding a new topic area knowledge branch to Cidy's Formulate Response topics. Based on lessons learned building the DA Project Planning and Design branch.

---

## Why This Process Exists

Adding a new branch directly to a production Formulate Response topic is risky. If retrieval fails, you have no visibility into why, and you can block other branches or break publishing. The process below uses an **isolated test topic** to prove the retrieval approach before touching any production YAML.

---

## Step 1: Understand the Knowledge Folder

Before writing any YAML, read the folder's `readme.docx` (or equivalent index file).

**What to extract:**
- How files are organized (e.g. by tranche, by document type, by year)
- Which document types exist: guidelines, templates, annexes, checklists, annotated templates, etc.
- Which document type answers which question type:
  - Guidelines → substantive answers
  - Templates → only when user asks for a blank document
  - Excel annexes → budget/table questions
  - Review checklists → QA, internal review, pre-submission questions
- Which document is the most recent (tranche number, date, version)
- Any special rules (e.g. "use T15+ for management response template")

**Output:** A plain-language `sourceUseInstructions` paragraph you will paste into the YAML. Example:

```
The Project Planning and Design folder is organized by tranche. Use the highest tranche
number as the most recent. Prefer Concept Note Guidelines for concept note questions and
Project Document Guidelines for project document questions. Do not use blank templates
unless the user specifically asks for templates. Use Excel annexes for annex-table
questions together with Project Document Guidelines. Use review checklists only for
QA/QC, internal review, or pre-submission review questions.
```

---

## Step 2: Create an Isolated Test Topic

Copy `Testing_DA_PPD.yaml` or `Testing_Country_Data.yaml` as a starting template.

**Critical settings:**

```yaml
startBehavior: CancelOtherTopics   # bypasses all routing — essential
```

```yaml
triggerQueries:
  - "testing mode: [topic-specific phrase]"
  - "testing mode: [another phrase]"
  - ...  # add 15–20 diverse examples so NLU generalizes
```

**Naming convention:** `Testing_[FundingStream]_[TopicArea].yaml`  
**Trigger prefix:** `testing mode: [anything relevant to the branch]`

The test topic should:
- Accept the raw user question and strip the "testing mode:" prefix
- Build the expanded retrieval question (see Step 3)
- Run Pass 1 against the specific knowledge source
- Run Pass 2 against the broad fallback (e.g. `CidyDAAll`) if Pass 1 is blank
- Output full DEBUG blocks showing the query sent and the raw response

Do **not** touch `Formulate_Response_[X].yaml` until Steps 4–5 are complete.

---

## Step 3: Build the Question Enhancement Suffix

The `userInput` field in `SearchAndSummarizeContent` is a **vector embedding query**. How you format it determines what gets retrieved.

### The rule: flat dense string only

**Bad (dilutes the vector embedding):**
```
="User question: " & Global.userQuestion & Char(10) &
"Question enhancements: " & Global.executiveQuestionEnhancements
```
Labels like "User question:", structured JSON blobs, and Char(10) separators all add noise that pulls the embedding away from the actual domain content. Retrieval fails silently.

**Good (flat expansion):**
```
=Topic.cleanQuestion & " Development Account DA concept note CN project document PD
guidelines template Excel annex review checklist tranche T19 T18 T17 T16 T15 T14
latest most recent project planning design requirements sections objectives budget
results framework quality assurance internal review submission implementing entity"
```

### How to build the suffix from the readme

1. Include all document type names as they appear in file titles (both long form and abbreviation: "concept note" and "CN", "project document" and "PD")
2. Include all tranche labels in the folder, from most recent down
3. Add recency language: "latest most recent"
4. Add the main concepts users ask about: sections, objectives, budget, results framework, review, submission
5. Add any domain-specific terms: "implementing entity", "quality assurance", "internal review"

**Keep the suffix to one flat line.** No punctuation between terms. No labels. No JSON.

---

## Step 4: Verify the Knowledge Source ID

Before any testing, confirm the knowledge source ID in your test YAML is current.

**How to find the current ID:**
1. In Copilot Studio, go to Knowledge → your knowledge source
2. The ID appears in the URL or in the YAML export of any topic that references it

**Why this matters:** If a knowledge folder is deleted and re-created (e.g. after remapping the SharePoint path), the old ID becomes stale. A stale ID in any YAML causes an `InvalidReferenceError` that **blocks all publishes for the entire agent** — not just the affected topic.

Always check IDs when:
- A knowledge source was renamed, remapped, or re-indexed
- You see `InvalidReferenceError` during publish
- Retrieval returns blank despite a seemingly correct setup

---

## Step 5: Test with Narrow Questions First

In the Copilot Studio test panel (no publish needed — draft is live immediately):

Start with questions where you know exactly which document should answer:
- Direct document name: `testing mode: concept note guidelines T19`
- Specific section: `testing mode: what sections are in the project document`
- Specific output: `testing mode: what goes in the results framework`

**What to look for in the DEBUG output:**
- `DEBUG_RETRIEVAL:` — does it name the right document and tranche?
- `CONFIDENCE:` — aim for 4–5 on direct questions; 3 is acceptable for broad questions
- If response is BLANK — the query didn't match. Revisit the suffix terms

**If Pass 1 returns blank:**
- Check the knowledge source ID is correct
- Check the suffix includes the actual terms used in the file names
- Try adding abbreviations or synonyms used in the documents themselves

---

## Step 6: Validate with a Broader Question Set

Once narrow questions pass, run at least 5–8 varied questions covering all question types in the folder:

| Question type | Example |
|---|---|
| Guidelines / how-to | `testing mode: how to draft a concept note` |
| Specific section | `testing mode: how should I fill in the results framework` |
| Comparison | `testing mode: what is the difference between a concept note and a project document` |
| Budget / annex | `testing mode: which annexes do I need to submit for a T19 project document` |
| Process / workflow | `testing mode: internal review steps before submitting a concept note` |
| QA / checklist | `testing mode: what does the quality review checklist cover` |
| Recency | `testing mode: what is the latest guidance for T19` |

All should return CONFIDENCE ≥ 3. If a category consistently fails, the suffix is missing terms for that document type — go back to the readme and add them.

---

## Step 7: Apply to the Main Formulate Response YAML

Once Step 6 passes, make exactly these changes to `Formulate_Response_[FundingStream].yaml`:

1. **Add the `SetTextVariable` for `sourceUseInstructions`** before the `SearchAndSummarizeContent` node (copy from your test topic)

2. **Replace the `userInput`** with the proven flat expansion string from your test topic

3. **Verify the `knowledgeSources` ID** matches the current live ID (same check as Step 4)

4. **Do not change `additionalInstructions`** unless you have a specific reason — the standard template works

5. Publish and test via the main flow

---

## Key Lessons Learned

| Lesson | Why it matters |
|---|---|
| Flat expansion string beats labeled/structured `userInput` | Labels and JSON dilute the vector embedding. Retrieved chunks drop from CONFIDENCE 5 to BLANK. |
| Isolated test topic first, production second | A failing branch in a multi-branch ConditionGroup is invisible without debug output. The test topic makes retrieval failures explicit. |
| `startBehavior: CancelOtherTopics` is required on test topics | Without it, the test topic competes with routing and classification, making results unreliable. |
| Stale knowledge source IDs block ALL publishes | One stale ID causes `InvalidReferenceError` on publish, preventing every change in the agent from going live — not just the affected topic. |
| New topics activate as drafts immediately; existing topic changes need a publish | This is why a new test topic works right away while changes to production topics seem to have no effect. |
| NLU trigger queries need 15–20 diverse examples | The NLU must generalize from examples to route arbitrary questions. Too few examples = missed routing. Add questions covering every relevant phrasing pattern. |
| Read the readme before writing a single line of YAML | The readme defines which document answers which question type. Without this, the suffix terms and `sourceUseInstructions` are guesswork. |

---

## Quick Reference: Test Topic Checklist

- [ ] `startBehavior: CancelOtherTopics` set
- [ ] Trigger prefix `testing mode:` with 15+ diverse examples
- [ ] `SetVariable` strips prefix and stores clean question
- [ ] Flat expansion suffix built from readme content
- [ ] Knowledge source ID verified as current
- [ ] Pass 1 hits specific folder; Pass 2 hits broad fallback
- [ ] DEBUG blocks output query sent + raw response
- [ ] Narrow questions pass (CONFIDENCE 4–5)
- [ ] Broad question set passes (CONFIDENCE ≥ 3 across all types)
- [ ] Only then: apply to `Formulate_Response_[X].yaml`
