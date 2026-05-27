# Cidy Copilot Studio Topic Documentation

This folder contains Copilot Studio topic YAML exports for Cidy, the UN DESA Capacity Development Assistant. The topics implement a user-inquiry, classification, clarification, question-enhancement, routing, response-generation, confidence, feedback, escalation, restart, and conversation-ending flow.

## Main Conversation Flow

```text
conversation_start.yaml
  -> user_inquiry.yaml                    [UserInquiry2]
      captures Global.userQuestion
      -> Cidy_Intent.yaml                 [Intent_c8W]
          -> Cidy_Intent_Clarifier.yaml   [Intent-Clarifier]
              -> Question_Enhancer.yaml   [QuestionEnhancer]
                  writes Global.executiveQuestionEnhancements
                  -> Cidy_Intent_Router.yaml  [Intent-Router]
                      -> Formulate_Response_DA.yaml
                      -> Formulate_Response_RPTC.yaml
                      -> FormulateResponse    [missing or ambiguous PDF topic]
                      -> user_feedback.yaml

Response topics
  -> assess_confidence.yaml               [AssessConfidence]
      -> share_response.yaml              [ShareResponse] when confidence >= 4
      -> warn.yaml                        [ApologizeWarn] when confidence < 4
          -> share_response.yaml
              -> user_feedback.yaml       [UserFeedback2]
                  -> continue_or_close.yaml [ContinueOrClose]

Feedback topic
  -> continue_or_close.yaml               [ContinueOrClose]
      -> Cidy_Intent.yaml                 [Intent_c8W] for another question
      -> Formulate_Response_General.yaml  [FormulateResponse] for wide retry
      -> escalate.yaml                    [Escalate] for human escalation
      -> close session

Escalation topic
  -> continue_or_close.yaml               [ContinueOrClose]
      post-escalation menu is the single user-facing confirmation and omits "Escalate to a human" because the inquiry has already been escalated

Utility/system-like topics
  -> start_over.yaml
      -> reset_conversation.yaml          [ResetConversation, file currently empty]
  -> Goodbye.yaml
      -> end_of_conversation.yaml         [EndofConversation]
  -> mutliple_topics_match.yaml
      -> Fallback                         [missing or built-in]
```

## Validation Flows

Use these flows as smoke tests for the classifier, clarifier, router, and response-topic wiring.

| Scenario | Test question | Clarification | Expected behavior |
| --- | --- | --- | --- |
| Happy path -> developed topic | What is required in a DA concept note? | None | Routes directly to `Formulate Response DA`. Expected variables: `knowledgeDomain=da`, `fundingStream=DA`, `topicArea=project_planning_design`, `requiresClarification=No`. |
| Clarification path -> developed topic | How do I write an evaluation report? | Choose Development Account (DA) | First asks fund clarification. After DA selection, routes to `Formulate Response DA` with `topicArea=evaluation_design`. |
| Clarification path -> not-yet-developed topic | What are the reporting requirements? | Choose RPTC | First asks fund clarification. After RPTC selection, routes to the RPTC branch or the temporary "not developed yet" message, depending on the current router/response-topic alignment. |
| Vague path | I need help with a project. Where do I start? | Choose Development Account (DA) only if asked after domain clarification | Should ask domain clarification, not force DA/RPTC/PDF immediately. Expected clarification type: `domain`. |
| Out of scope | What is the weather in New York today? | None | Should classify as `out_of_scope`, show the scope message, then go to the feedback/escalation path. No clarification. |
| Happy path -> undeveloped topic | How does Cidy work? | None | Should route to `about_cidy` or the temporary "About Cidy is not yet developed" message. No clarification. |

## Topic Inventory

| File | Purpose | Entry trigger | Calls |
| --- | --- | --- | --- |
| `conversation_start.yaml` | Sends the welcome message and stores `Topic.conversationID`. | `OnConversationStart` | `UserInquiry2` |
| `user_inquiry.yaml` | Captures the user's first or looped follow-up question into `Global.userQuestion` and initializes/appends transcript text. | `OnRecognizedIntent` | `Intent_c8W` |
| `Cidy_Intent.yaml` | Classifies the user's question into intent variables such as `Global.knowledgeDomain`, `Global.fundingStream`, `Global.topicArea`, and clarification state. | `OnRecognizedIntent` | `Intent-Clarifier` |
| `Cidy_Intent_Clarifier.yaml` | Resolves unclear fund, domain, or artifact classifications through targeted questions. | `OnRecognizedIntent` | `QuestionEnhancer` |
| `Question_Enhancer.yaml` | Adds non-routing search intelligence to `Global.executiveQuestionEnhancements` after clarification and before routing. It expands useful acronyms, dates, recency cues, filters, and source-selection hints without changing finalized intent variables. | `OnRecognizedIntent` | `Intent-Router` |
| `Cidy_Intent_Router.yaml` | Routes finalized intent variables to response, feedback, or not-yet-developed handling. | `OnRecognizedIntent` | `UserFeedback2`, `DA`, `FormulateResponseCopy`, `FormulateResponse` |
| `Formulate_Response_DA.yaml` | Searches DA knowledge sources and writes `Global.draftResponse`. | `OnRecognizedIntent` | `AssessConfidence` |
| `Formulate_Response_RPTC.yaml` | Searches RPTC knowledge sources and writes `Global.draftResponse`. | `OnRecognizedIntent` | `AssessConfidence` |
| `Formulate_Response_General.yaml` | Searches the general CDPMO knowledge source and writes `Global.draftResponse`. | `OnRecognizedIntent` | `AssessConfidence` |
| `Formulate_Response_Programme_Development.yaml` | Searches Programme Development sources, including TAG/Steering Committee materials, project evaluations, guidelines/templates, implementing partners/grants, Resident Coordinator country engagement, DESA capacity-development strategy, and the broad Programme Development fallback. | `OnRecognizedIntent` | `AssessConfidence` |
| `assess_confidence.yaml` | Parses/formats a generated answer into answer, sources, confidence score, confidence label, and explanation. | `OnRecognizedIntent` | `ShareResponse`, `ApologizeWarn` |
| `warn.yaml` | Sets warning text for low or medium confidence answers. | `OnRecognizedIntent` | `ShareResponse` |
| `share_response.yaml` | Sends the warning, answer, sources, and confidence label to the user, then asks for feedback. | `OnRecognizedIntent` | `UserFeedback2` |
| `user_feedback.yaml` | Collects helpfulness feedback, sets `Global.nextActionContext=feedback`, and hands off to the reusable next-step menu. | `OnRecognizedIntent` | `ContinueOrClose` |
| `continue_or_close.yaml` | Offers context-aware next-step choices. Normal feedback can ask another question, retry wide knowledge, escalate, or close; post-escalation can ask another question, retry wide knowledge, or close. | `OnRecognizedIntent` | `Intent_c8W`, `FormulateResponse`, `Escalate` |
| `escalate.yaml` | Collects escalation notes, generates an issue summary, sends an Outlook email to staff, records the escalation in transcript, then sets `Global.nextActionContext=post_escalation` for the single visible confirmation/follow-up prompt. | `OnEscalate` plus trigger phrases | `Office365Outlook-SendanemailV2` action, `ContinueOrClose` |
| `start_over.yaml` | Confirms restart and redirects to reset conversation. | `OnRecognizedIntent` with start-over phrases | `ResetConversation` |
| `reset_conversation.yaml` | Intended target for restart flow. | None, file is empty | None |
| `Goodbye.yaml` | Handles goodbye intent and optionally ends the conversation. | `OnRecognizedIntent` with goodbye phrases | `EndofConversation` |
| `end_of_conversation.yaml` | System redirect flow that asks satisfaction/CSAT, offers retry, and can escalate if the user says the answer did not help. | `OnSystemRedirect` | `Escalate` |
| `mutliple_topics_match.yaml` | Handles multiple matched topics by asking the user to choose one, with a "None of these" option. | `OnSelectIntent` | `Fallback` via `ReplaceDialog` |

## Inferred Topic Name Mapping

The YAML files in this folder do not include an explicit exported topic ID field. The mappings below are inferred from `dialog:` references and topic behavior.

| Referenced topic name | Likely file |
| --- | --- |
| `UserInquiry2` | `user_inquiry.yaml` |
| `Intent_c8W` | `Cidy_Intent.yaml` |
| `Intent-Clarifier` | `Cidy_Intent_Clarifier.yaml` |
| `QuestionEnhancer` | `Question_Enhancer.yaml` |
| `Intent-Router` | `Cidy_Intent_Router.yaml` |
| `UserFeedback2` | `user_feedback.yaml` |
| `ContinueOrClose` | `continue_or_close.yaml` |
| `DA` | `Formulate_Response_DA.yaml` |
| `FormulateResponseCopy` | `Formulate_Response_RPTC.yaml` |
| `AssessConfidence` | `assess_confidence.yaml` |
| `ApologizeWarn` | `warn.yaml` |
| `ShareResponse` | `share_response.yaml` |
| `Escalate` | `escalate.yaml` |
| `ResetConversation` | `reset_conversation.yaml`, but the file is currently empty |
| `EndofConversation` | `end_of_conversation.yaml` |

## Called Topics Not Found Or Not Complete

These topic references appear in `dialog:` or `ReplaceDialog` calls but do not have a complete clear YAML file in this folder.

| Referenced topic/action | Called from | Notes |
| --- | --- | --- |
| `FormulateResponse` | `Cidy_Intent_Router.yaml` | Used for the PDF/UNPDF route. No clear PDF response YAML exists. If this is meant to be a PDF topic, add/export it. If it maps to an existing file, rename/document the mapping. |
| `ResetConversation` | `start_over.yaml` | `reset_conversation.yaml` now exists but is zero bytes, so this route is still incomplete in the export. |
| `Fallback` | `mutliple_topics_match.yaml` | Called when the user selects "None of these" from the multiple-topic selector. No `fallback.yaml` or clear matching file exists. This may be a built-in/system topic, but confirm in Copilot Studio. |
| `Office365Outlook-SendanemailV2` | `escalate.yaml` | This is an action/connector call, not expected to be represented as a topic YAML file. |

Resolved since the previous scan:

- `UserInquiry2` now maps to `user_inquiry.yaml`.
- `EndofConversation` now maps to `end_of_conversation.yaml`.
- `mutliple_topics_match.yaml` is no longer empty; it is a multiple-topic disambiguation topic.

## Potentially Unused Or Cleanup Candidates

| File | Why it may be unused or risky | Recommendation |
| --- | --- | --- |
| `reset_conversation.yaml` | The file exists but is empty, while `start_over.yaml` calls `ResetConversation`. | Re-export or recreate the reset topic before relying on start-over behavior. |
| `Formulate_Response_Programme_Development.yaml` | The topic is now wired for programme-development topic areas, but some branch prompt text/source labels still need human validation. | Review programme-development source IDs and wording as knowledge coverage matures. |
| `Formulate_Response_General.yaml` | The topic is now used for broad/general retry behavior. | Keep it aligned with the top-level `Knowledge` source and wide-retry feedback path. |
| `Goodbye.yaml` | Not called by other custom topics, but it has its own goodbye trigger phrases. | Keep if the bot should support standalone goodbye intent. |
| `start_over.yaml` | Not called by other custom topics, but it has its own start-over trigger phrases. | Keep if the bot should support standalone restart intent after `reset_conversation.yaml` is populated. |

## Routing Gaps And Consistency Notes

1. `about_cidy` is recognized by the classifier and clarifier, but no matching response YAML exists yet.
2. `Formulate_Response_Programme_Development.yaml` is wired for current Programme Development branches, including specific source IDs for `Cidy-PD-RC` and `Cidy-PD-Strategy`.
3. The PDF/UNPDF route calls `FormulateResponse`, but there is no clearly named PDF YAML file in this folder.
4. RPTC has been consolidated around two current knowledge areas: `rptc_guidance_templates` for planning, approval, implementation, activity proposals, IRA guidance, reporting standards, activity report templates, and post-activity reporting; and `rptc_progress_reports` for achievements, supported countries, requests, interventions, people supported, implementing entities, LDC/LLDC/SIDS support, challenges, and recommendations. The RPTC `elseActions` branch is the RPTC folder-level fallback: it is used only after routing has already selected RPTC, when no more specific RPTC topic-area condition matched, and it should search the broad RPTC-all folder rather than the top-level Cidy `Knowledge` source.
5. Programme Development now includes `resident_coordinator` for RC/RCO, UNCT, CCA/UNSDCF, country-level support, and CDPMO country-engagement questions; and `cd_strategy` for strategic priorities, service delivery model, service lines, request prioritization, partnerships, and the AI-enabled Capacity Development Knowledge Hub/Cidy.
6. DEBUG `SendActivity` messages in the active intent, clarifier, router, and question enhancer topics are controlled by `Global.testMode`. The default is `false`, set near the top of `Cidy_Intent.yaml`; set it to `true` only when route diagnostics should be visible.
7. `share_response.yaml` should use the production-facing `**Answer:**` label, not a DEBUG answer label.
8. `continue_or_close.yaml` is the shared next-step topic. It uses `Global.nextActionContext` so post-escalation users are not offered a second escalation option.
9. `warn.yaml` has typos in user-facing text: `requst` and `coleague`.
10. The file `mutliple_topics_match.yaml` appears to have a typo in the filename: `mutliple` instead of `multiple`.

## Response Pipeline Notes

All `SearchAndSummarizeContent` actions in Formulate Response topics that are followed by `AssessConfidence` must set `autoSend: false` and write to `Global.draftResponse`. If a search action sends directly to chat and leaves `Global.draftResponse` blank, the user can see a valid answer followed by the fallback/no-results warning because the confidence/share pipeline has no draft response to assess.

`Question_Enhancer.yaml` runs between clarification and routing. It may write search hints to `Global.executiveQuestionEnhancements`, but it must not change `Global.knowledgeDomain`, `Global.fundingStream`, `Global.topicArea`, `Global.intentStatus`, or other routing variables. Formulate Response topics include the enhancement text in `SearchAndSummarizeContent.userInput` so retrieval can consider expanded acronyms, dates, recency cues, filters, and source-selection hints while the router remains the only topic that selects the response path.

## Suggested Next Cleanup Pass

1. Re-export or rebuild `reset_conversation.yaml`, because the file exists but is empty.
2. Decide whether `FormulateResponse` is an exported PDF topic that is missing from this folder. If so, add it. If not, update the router to the correct topic name.
3. Confirm whether `Fallback` is a built-in/system topic. If it is custom, export it into this folder.
4. Align classifier `topic_area` values with the condition checks inside each response topic, especially RPTC.
5. Rename typoed files only if Copilot Studio export/import tooling and any external references will tolerate the filename changes.
