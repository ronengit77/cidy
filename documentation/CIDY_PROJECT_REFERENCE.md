# Cidy Project Reference

**Read this document first before providing any debugging guidance or code changes.**

---

## 1. What Cidy Is

Cidy is a knowledge assistant for UN DESA's Capacity Development Programme Management Office (CDPMO), built in **Microsoft Copilot Studio**. It serves international UN staff who need support with capacity-development projects — drafting concept notes, project documents, progress reports, evaluations, and related guidance across three funding streams: DA, RPTC, and PDF/UNPDF.

- Platform: **Copilot Studio** (Power Virtual Agents)
- Logic: YAML topic files exported from Copilot Studio and version-controlled in git
- Repo: `https://github.com/ronengit77/cidy` — branches: `main` (production), `staging` (integration), personal branches per team member
- Working directory: `c:\Users\RRAPOPOR\Documents\Cidy testing\`

Cidy does **not** answer general HR, legal, travel, or non-CD questions. It escalates to a human via Outlook email when confidence is low or the user requests it.

---

## 2. Full Conversation Flow

```
conversation_start.yaml
  → user_inquiry.yaml               captures Global.userQuestion; greeting gate
      → greeting.yaml               greeting-only → clear state → back to user_inquiry
      → Cidy_Intent.yaml            AI classifier → sets domain/fund/topicArea/clarification vars
          → Cidy_Intent_Clarifier.yaml    asks fund/domain/artifact question if needed (max 2 attempts)
              → Question_Enhancer.yaml   adds search hints to Global.executiveQuestionEnhancements (NO routing changes)
                  → Cidy_Intent_Router.yaml   routes by domain/fund to Formulate Response topic
                      → Formulate_Response_DA.yaml
                      → Formulate_Response_RPTC.yaml
                      → Formulate_Response_Programme_Development.yaml
                      → Formulate_Response_Cidy_About.yaml
                      → Formulate_Response_General.yaml      (wide retry / general_cd)
                      → [Formulate_Response_PDF.yaml]        MISSING — router calls FormulateResponse dialog
                      → user_feedback.yaml                   out_of_scope / dead_end

Formulate Response (any) → writes Global.draftResponse
  → assess_confidence.yaml          parses ANSWER / SOURCES / CONFIDENCE from draftResponse
      → warn.yaml                   confidence < 4 → sets warning text
          → share_response.yaml     sends warning + answer + sources + confidence label
      → share_response.yaml         confidence ≥ 4 → sends answer directly
          → user_feedback.yaml      collects helpfulness feedback
              → continue_or_close.yaml    ask another / wide retry / escalate / close
                  → Cidy_Intent.yaml      (new question)
                  → Formulate_Response_General.yaml   (wide retry)
                  → escalate.yaml         sends Outlook email, then ContinueOrClose post-escalation
```

Rescue paths:
- `return_to_cidy.yaml` — triggered by "Back to Cidy flow"; cancels all topics, clears state, restarts intake
- `start_over.yaml` → `reset_conversation.yaml` — clears state, back to user_inquiry
- `Goodbye.yaml` → `end_of_conversation.yaml` — CSAT, optional escalate, can return to user_inquiry

---

## 3. Global Variables (all variables that matter)

| Variable | Type | Owner | Purpose |
|---|---|---|---|
| `Global.userQuestion` | String | user_inquiry | Raw user question before classification |
| `Global.intentJson` | String | Cidy_Intent | Raw JSON from classifier |
| `Global.intentStatus` | String | Intent/Clarifier/Router | Flow state machine: `needs_classification` → `needs_clarification` → `ready_to_route` → `out_of_scope` / `dead_end` |
| `Global.knowledgeDomain` | String | Intent/Clarifier | Primary routing key: `da`, `rptc`, `pdf`, `programme_development`, `general_cd`, `about_cidy`, `out_of_scope`, `unclear` |
| `Global.fundingStream` | String | Intent/Clarifier | `DA`, `RPTC`, `PDF`, `UNCLEAR` |
| `Global.topicArea` | String | Intent/Clarifier | Sub-classification used by Formulate Response to pick the knowledge folder branch |
| `Global.requiresClarification` | String `Yes/No` | Intent/Clarifier | Whether to ask clarification |
| `Global.clarificationType` | String | Intent/Clarifier | `none`, `fund`, `domain`, `artifact` |
| `Global.clarificationAttempts` | Number | Clarifier | Max 2; dead_end after that |
| `Global.executiveQuestionEnhancements` | String | Question_Enhancer | Search hints (acronyms, dates, filters, synonyms) — MUST NOT be used by Router to change routing |
| `Global.sourceUseInstructions` | String | Formulate Response | Folder-specific instructions passed to `additionalInstructions` |
| `Global.draftResponse` | String | Formulate Response | Full AI response: `ANSWER: ... SOURCES: ... CONFIDENCE: N` |
| `Global.formattedAnswer` | String | assess_confidence | Extracted answer after parsing |
| `Global.formattedSources` | String | assess_confidence | Extracted sources |
| `Global.confidenceScore` | String | assess_confidence | Number 0–5 |
| `Global.confidenceLabel` | String | assess_confidence | Human label |
| `Global.warningMessage` | String | warn / Router | Warning text for low confidence or errors |
| `Global.routingTarget` | String | Router | Diagnostic: which Formulate Response was selected |
| `Global.testMode` | Boolean | Cidy_Intent (set at top) | `true` = show DEBUG SendActivity messages; `false` = silent |
| `Global.requestStartTime` | DateTime | user_inquiry | Set to `Now()` at question capture for response time measurement |
| `Global.responseTimeSeconds` | Number | Formulate Response | `DateDiff(requestStartTime, Now(), TimeUnit.Seconds)`; guarded: `If(IsBlank(...), -1, DateDiff(...))` |
| `Global.transcript` | String | user_inquiry/escalate | Running conversation text |
| `Global.nextActionContext` | String | user_feedback/escalate/continue_or_close | `feedback` or `post_escalation` — controls which menu ContinueOrClose shows |
| `Global.cidyMode` | String | conversation_start | `structured` (normal) or `open` |
| `Global.awaitingNewQuestion` | Boolean | greeting/continue_or_close | Whether next message is a fresh question |
| `Global.countryDataEnhancedQuestion` | String | Formulate_Response_Programme_Development | Enhanced retrieval query for country_data branch |
| `Global.ppdRetrievalQuestion` (Topic-scoped) | String | Formulate_Response_DA | Flat expanded query for project_planning_design branch only |

---

## 4. Intent Router — Domain Routing Table

| Condition | Routes to | YAML file |
|---|---|---|
| `knowledgeDomain = "about_cidy"` | FormulateResponseCidyAbout | Formulate_Response_Cidy_About.yaml |
| `knowledgeDomain = "programme_development"` OR topicArea in [projects_evaluations, tag_meetings, steering_committee, cd_strategy, guidelines_templates, implementing_partners_grants, resident_coordinator, country_data] | FormulateResponseProgrammeDevelopment | Formulate_Response_Programme_Development.yaml |
| `knowledgeDomain = "da"` OR `fundingStream = "DA"` | DA | Formulate_Response_DA.yaml |
| `knowledgeDomain = "rptc"` OR `fundingStream = "RPTC"` OR topicArea in [rptc_guidance_templates, rptc_progress_reports] | FormulateResponseCopy | Formulate_Response_RPTC.yaml |
| `knowledgeDomain = "pdf"` OR `fundingStream = "PDF"` | FormulateResponse | **MISSING — Formulate_Response_PDF.yaml does not exist** |
| `knowledgeDomain = "general_cd"` | FormulateResponse | Formulate_Response_General.yaml |
| elseActions | User Feedback | Unable to route |

**Special normalization (before routing):** `knowledgeDomain = "project_evaluation_evidence"` OR `topicArea = "evaluation_evidence"` are remapped to `knowledgeDomain = programme_development` + `topicArea = projects_evaluations`.

**Patience message** fires before every `BeginDialog` in all 6 successful routes: *"I identified a relevant knowledge folder for your question. Searching and generating a response — this may take up to 40 seconds. Thank you for your patience."*

---

## 5. Formulate Response DA — Branch Structure

This is the most active file for debugging. All branches end with the stop-timer pattern then `BeginDialog: AssessConfidence`.

```
Formulate_Response_DA.yaml
  ├── [fallback timer start] If(IsBlank(Global.requestStartTime)) → set to Now()
  ├── conditionGroup_rsyEfm
  │   ├── topicArea = "project_planning_design"
  │   │   ├── Set sourceUseInstructions (PPD folder instructions)
  │   │   ├── Set Topic.ppdRetrievalQuestion = userQuestion & [flat anchor string]
  │   │   ├── DEBUG block (testMode gate): shows incoming text, question, topic, expanded query, KS, test plan
  │   │   ├── SearchAndSummarizeContent → Global.draftResponse
  │   │   │   userInput: =Topic.ppdRetrievalQuestion   ← FLAT EXPANSION, no labels
  │   │   │   KS: CidyDAProjectPlanningandDesign_oy_jlk_uCuNf2iko9HdJK
  │   │   └── DEBUG block: Pass 1 result
  │   ├── topicArea = "evaluation_design"
  │   │   ├── Set sourceUseInstructions (Evaluation folder instructions)
  │   │   └── SearchAndSummarizeContent KS: Evaluations_zeK4BT8uZXrgHEy5vAivo
  │   ├── topicArea = "general"
  │   │   └── SearchAndSummarizeContent KS: CidyDAProjectPlanningandDesign_oy_jlk_uCuNf2iko9HdJK
  │   └── elseActions → SearchAndSummarizeContent KS: CidyDAAll_fNqeT7A_zZXF76sp_dprZ
  ├── conditionGroup_fallback (if draftResponse is blank)
  │   ├── SearchAndSummarizeContent KS: CidyDAAll_fNqeT7A_zZXF76sp_dprZ
  │   └── DEBUG block: Pass 2 result
  ├── set_responseTimeSeconds → If(IsBlank(requestStartTime), -1, DateDiff(...))
  ├── DEBUG block (testMode): Response time | Funding stream | Topic area | Result
  └── BeginDialog: AssessConfidence
```

**Key technical rule:** The `userInput` for the PPD branch uses **flat expansion only** — a single dense string of anchor terms appended to the user question. NO labels (`"User question: "`, `"Question enhancements: "`), NO JSON blobs, NO `Char(10)` separators. Labels dilute the vector embedding and cause silent retrieval failures.

---

## 6. Formulate Response — Other Topics

### Formulate_Response_RPTC.yaml
Branches: `rptc_progress_reports` → `rptc_guidance_templates` (+ many aliases) → elseActions (broad RPTC fallback) → fallback if blank.

### Formulate_Response_Programme_Development.yaml
Branches: `steering_committee` → `tag_meetings` → `projects_evaluations` → `guidelines_templates` → `implementing_partners_grants` → `resident_coordinator` → `cd_strategy` → `country_data` (has enhanced query with ISO3 expansion) → elseActions → fallback (excludes country_data from blank check).

### Formulate_Response_Cidy_About.yaml
Single branch + top-level KS fallback if blank.

### Formulate_Response_General.yaml
Single SearchAndSummarizeContent against the top-level `Knowledge` KS. Used for wide retry.

### Formulate_Response_DA_Staging.yaml
Identical to `Formulate_Response_DA.yaml`. Used for testing PPD changes before applying to production. **Not wired to the router** — must be imported into Copilot Studio separately.

---

## 7. Knowledge Source ID Reference

| Domain / Folder | Knowledge Source ID |
|---|---|
| DA — Project Planning & Design | `copilots_header_3141e.topic.CidyDAProjectPlanningandDesign_oy_jlk_uCuNf2iko9HdJK` |
| DA — Evaluations | `copilots_header_3141e.topic.Evaluations_zeK4BT8uZXrgHEy5vAivo` |
| DA — All (broad fallback) | `copilots_header_3141e.topic.CidyDAAll_fNqeT7A_zZXF76sp_dprZ` |
| RPTC — Progress Reports | `copilots_header_3141e.topic.progressreports_zzSLrTzDYpILKYSyzN1DS` |
| RPTC — Guidance & Templates | `copilots_header_3141e.topic.CidyRPTCGuidanceandtemplates_oKZNYKzHMYWToPKwis3yk` |
| RPTC — All (broad fallback) | `copilots_header_3141e.topic.RPTC_ng_c2cW2FsuWn_CZ41qlf` |
| RPTC — (combined) | `copilots_header_3141e.topic.CidyRPTCAll_tRqm_5BANa6OlaqipYIAS` |
| Programme Dev — Steering Committee | `copilots_header_3141e.topic.SteeringCommitteeMeetings_A6vL6_OHQKf_M7XeF2S3d` |
| Programme Dev — TAG Meetings | `copilots_header_3141e.topic.TAGMeetings_EFq0d2SBZNEdI4W5P8DkF` |
| Programme Dev — Project Evaluations | `copilots_header_3141e.topic.ProjectEvaluations_4Cj3nKCE0nIEC_Ll1o8Se` |
| Programme Dev — Guidelines & Templates | `copilots_header_3141e.topic.Guidelinesandtemplates_iPiEFA1ueLu3wiVtlbIdS` |
| Programme Dev — Implementing Partners | `copilots_header_3141e.topic.CidyImplementingPartnersandGrants_4lDwybsiRV1xRZ0AAi1Pa` |
| Programme Dev — Resident Coordinator | `copilots_header_3141e.topic.CidyPDRC_3eeGCP3GTHDQ54COW1rW_` |
| Programme Dev — CD Strategy | `copilots_header_3141e.topic.CidyPDStrategy__W4VIB7zkK7KQdy8_9Xg9` |
| Programme Dev — Country Data | `copilots_header_3141e.topic.CidyCountryData_VUhURDqxKRX3LM0Lx4RKy` |
| Programme Dev — All (broad fallback) | `copilots_header_3141e.topic.CidyPDAll_fpi14G9BVgM81C1jP17J5` |
| About Cidy | `copilots_header_3141e.topic.CidyAbout_G0C_NOH4HBzjTFPTB5DPs` |
| Top-level Knowledge (wide retry) | `copilots_header_3141e.topic.Knowledge_WYTpGldAWsk7o_B4cI6Vn` |

**Critical rule:** Stale or wrong KS IDs cause `InvalidReferenceError` that blocks ALL publishes for the entire agent. Always verify IDs match what Copilot Studio currently has before adding new knowledge source references.

---

## 8. SearchAndSummarizeContent — How It Works

Two-phase operation:
1. **Phase 1 — Vector retrieval:** `userInput` field is embedded and used to find the most relevant chunks from the knowledge source.
2. **Phase 2 — Generation:** The retrieved chunks + `additionalInstructions` are sent to the LLM to generate the final answer.

**Retrieval rules:**
- `userInput` should be a flat dense string — the user question plus domain-relevant anchor terms
- Labels (`"User question:"`, `"Question enhancements:"`), JSON blobs, and `Char(10)` separators in `userInput` dilute the vector embedding → retrieval fails silently
- `additionalInstructions` can be rich/detailed — it goes to generation, not retrieval
- `autoSend: false` + `variable: Global.draftResponse` is required — if autoSend is true, the answer goes directly to chat and `draftResponse` is blank, breaking the confidence pipeline

**YAML scalar rule:** Power Fx expression values must use `value: |-` (strip trailing newline), never `value: |`. A trailing newline in a Power Fx value causes silent parse failures.

---

## 9. Response Format Contract

Every `SearchAndSummarizeContent` `additionalInstructions` in this project ends with:

```
Format your response as follows:
ANSWER: Your detailed answer
SOURCES: List each source as a markdown link in this exact format: [name of file](full url)...
CONFIDENCE: Write ONLY a single number from 0 to 5 on this line, nothing else.
```

`assess_confidence.yaml` parses this format to extract `Global.formattedAnswer`, `Global.formattedSources`, `Global.confidenceScore`. If the format contract is broken, parsing fails and the user sees a fallback warning.

---

## 10. Timer Implementation

Start: `Global.requestStartTime = Now()` is set in two places in `user_inquiry.yaml`:
1. Initial path — right after the question is captured
2. Awaiting path — after `capture_newQuestion` before exit-command check

Each Formulate Response file also has a **fallback timer start** at its very top: `If(IsBlank(Global.requestStartTime)) → Set Global.requestStartTime = Now()`. This fires if user_inquiry changes haven't been published yet.

Stop: Before `BeginDialog: AssessConfidence` in all 6 Formulate Response files:
```powerfx
Global.responseTimeSeconds = If(IsBlank(Global.requestStartTime), -1, DateDiff(Global.requestStartTime, Now(), TimeUnit.Seconds))
```

Display: Controlled by `Global.testMode = true`. Debug message shows: `Response time: Xs | Funding stream: X | Topic area: X | Result: HAS CONTENT / BLANK`

---

## 11. testMode Debug Architecture

`Global.testMode` is set at the top of `Cidy_Intent.yaml`. Default is `false`.

When `true`, debug `SendActivity` messages appear at:
- `user_inquiry.yaml` — raw question capture
- `Cidy_Intent.yaml` — raw classification JSON
- `Cidy_Intent_Clarifier.yaml` — clarifier bypass or state
- `Question_Enhancer.yaml` — enhancement JSON
- `Cidy_Intent_Router.yaml` — entry state + domain route selected
- `Formulate_Response_DA.yaml` — PPD branch entry, Pass 1 result, Pass 2 result (fallback), response time
- `Formulate_Response_Programme_Development.yaml` — country_data branch input

To test without publishing: push YAML changes to Copilot Studio via the Kit/SDK — draft topic changes are immediately active in the test chat without publishing. Existing topic changes require a publish; new topics are immediately available as drafts.

---

## 12. Known Gaps and Open Issues

| Gap | Status | Notes |
|---|---|---|
| `Formulate_Response_PDF.yaml` | **Missing** | Router calls `copilots_header_3141e.topic.FormulateResponse` for PDF/UNPDF but no PDF YAML exists |
| DA `monitoring_reporting` branch | Not mapped | Falls to elseActions → broad DA KS |
| DA `budget_finance` / `eligibility_budget` branches | Not mapped | Falls to elseActions |
| DA `templates` branch | Not mapped | Falls to elseActions |
| RPTC `elseActions` userInput | Old labeled format | Still uses `"User question: " & ... & Char(10)` — known retrieval risk, deferred |
| Intent Clarifier Issues 2, 3, 4 | Deferred | Only Issue 1 (`value: |` → `value: |-`) was fixed |
| Question Enhancer `retrieval_query` field | Deferred | Add dedicated retrieval anchor |
| OnError topic | Deferred | User to bring from another codebase |
| TC52 / TC53 unclear domain | Gap | After max clarification, domain stays unclear → no route matched → falls to elseActions message |

---

## 13. Git and Branching

- `main` — production (what's published to users)
- `staging` — integration branch; all recent work committed here
- Personal team branches: `[name]/[funding-stream]-[topic-area]` format

A pre-commit hook runs `tools/run_intent_test_cases.ps1` automatically on every commit. It does structural route simulation (not live AI) against the test cases in `documentation/Cidy_Intent_Test_Cases_90.json`. Results written to `documentation/cidy_intent_test_results.json` and `cidy_intent_test_failures.json`. Last run: **83 passed / 17 failed**.

Publishing: Changes to existing topics require a publish in Copilot Studio to go live. New topics are available in draft testing immediately after pushing YAML.

---

## 14. File Naming and Topic ID Mapping

| YAML File | Copilot Studio Topic Name | Dialog ID used in router |
|---|---|---|
| `user_inquiry.yaml` | UserInquiry2 | — |
| `Cidy_Intent.yaml` | Intent_c8W | — |
| `Cidy_Intent_Clarifier.yaml` | Intent-Clarifier | — |
| `Question_Enhancer.yaml` | QuestionEnhancer | — |
| `Cidy_Intent_Router.yaml` | Intent-Router | — |
| `Formulate_Response_DA.yaml` | DA | `copilots_header_3141e.topic.DA` |
| `Formulate_Response_RPTC.yaml` | FormulateResponseCopy | `copilots_header_3141e.topic.FormulateResponseCopy` |
| `Formulate_Response_Programme_Development.yaml` | FormulateResponseProgrammeDevelopment | `copilots_header_3141e.topic.FormulateResponseProgrammeDevelopment` |
| `Formulate_Response_Cidy_About.yaml` | FormulateResponseCidyAbout | `copilots_header_3141e.topic.FormulateResponseCidyAbout` |
| `Formulate_Response_General.yaml` | FormulateResponse | `copilots_header_3141e.topic.FormulateResponse` |
| `assess_confidence.yaml` | AssessConfidence | `copilots_header_3141e.topic.AssessConfidence` |
| `warn.yaml` | ApologizeWarn | — |
| `share_response.yaml` | ShareResponse | — |
| `user_feedback.yaml` | UserFeedback2 | — |
| `continue_or_close.yaml` | ContinueOrClose | — |
| `escalate.yaml` | Escalate | — |
| `return_to_cidy.yaml` | Return to Cidy | — |
| `greeting.yaml` | Greeting | — |

`Formulate_Response_DA_Staging.yaml` is **not wired to the router** — it is a staging/test copy used to validate changes before applying them to the production DA file. Must be manually imported and swapped in Copilot Studio for testing.
