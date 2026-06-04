# Cidy Intent Test Questions

Generated from documentation/Cidy_Intent_Test_Cases_90.json.

Total test cases: 99

## 1. Happy path - DA project planning

**Question:** What is required in a DA concept note?

**Expected behavior:** Intent Classifier sets knowledge_domain=da, funding_stream=DA, topic_area=project_planning_design, requires_clarification=No. Intent Clarifier bypasses. Intent Router routes to Formulate Response DA.

## 2. Happy path - DA project document

**Question:** For DA, how do I prepare a project document?

**Expected behavior:** Routes directly to Formulate Response DA with topic_area=project_planning_design.

## 3. Happy path - DA monitoring and reporting

**Question:** What are the DA requirements for project monitoring and reporting?

**Expected behavior:** Routes directly to Formulate Response DA with topic_area=monitoring_reporting.

## 4. Happy path - DA budget eligibility

**Question:** Under the Development Account, are travel costs eligible?

**Expected behavior:** Routes directly to Formulate Response DA with topic_area=budget_finance or eligibility_budget if available.

## 5. Happy path - DA Section 35 signal

**Question:** What does Section 35 say about project design?

**Expected behavior:** Recognizes Section 35 as DA signal and routes to Formulate Response DA.

## 6. Happy path - DA evaluation design

**Question:** How do I design a DA terminal evaluation?

**Expected behavior:** Routes directly to Formulate Response DA with topic_area=evaluation_design. This is guidance on designing an evaluation, not actual evaluation evidence.

## 7. Happy path - DA evaluation template

**Question:** What is the DA evaluation report template?

**Expected behavior:** Routes to Formulate Response DA with topic_area=evaluation_design or templates.

## 8. Happy path - DA general start

**Question:** How do I start a new DA project?

**Expected behavior:** Routes to Formulate Response DA. Topic may be general or project_planning_design.

## 9. Happy path - DA latest tranche

**Question:** Which DA tranche guidance should I use for a new project?

**Expected behavior:** Routes to Formulate Response DA and should prefer the latest tranche guidance.

## 10. Happy path - DA checklist

**Question:** Is there a DA checklist for reviewing concept notes?

**Expected behavior:** Routes to Formulate Response DA with topic_area=project_planning_design or templates.

## 11. Happy path - project evaluation evidence

**Question:** What do project evaluations say about sustainability?

**Expected behavior:** Routes directly to Programme Development with topic_area=projects_evaluations. This is actual evaluation evidence, not evaluation design guidance.

## 12. Happy path - evaluation recommendations

**Question:** Summarize recommendations from project evaluations related to stakeholder engagement.

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations.

## 13. Happy path - lessons learned

**Question:** What lessons learned are available from past capacity development projects?

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations.

## 14. Happy path - DA evaluation evidence distinction

**Question:** What have evaluations said about DA projects?

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations, using DA as context if available. It should not route to DA evaluation design guidance.

## 15. Happy path - recurring evaluation findings

**Question:** Are there recurring findings from past project evaluations?

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations.

## 16. Happy path - evaluation weaknesses

**Question:** What do evaluation reports say about project design weaknesses?

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations.

## 17. Happy path - partnerships in evaluations

**Question:** What have previous evaluations found about partnerships?

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations.

## 18. Happy path - sustainability recommendations

**Question:** What do evaluations recommend about sustainability?

**Expected behavior:** Routes to Programme Development with topic_area=projects_evaluations.

## 19. Happy path - Programme Development CD Strategy

**Question:** What is DESA's capacity development strategy?

**Expected behavior:** Routes to Formulate Response Programme Development with topic_area=cd_strategy.

## 20. Happy path - Programme Development Steering Committee

**Question:** What has the Steering Committee discussed about programme development?

**Expected behavior:** Routes to Programme Development with topic_area=steering_committee.

## 21. Happy path - Programme Development TAG

**Question:** What are the TAG meeting materials about?

**Expected behavior:** Routes to Programme Development with topic_area=tag_meetings.

## 22. Happy path - Programme Development general

**Question:** What guidance exists on programme development in Cidy?

**Expected behavior:** Routes to Programme Development with topic_area=general.

## 23. Happy path - Programme Development annual progress report template

**Question:** What instructions apply to the 2025 annual progress report template?

**Expected behavior:** Routes to Programme Development with topic_area=guidelines_templates.

## 24. Happy path - Programme Development final report template

**Question:** What should be included in the final report template for a capacity development project?

**Expected behavior:** Routes to Programme Development with topic_area=guidelines_templates.

## 25. Happy path - Programme Development project document preparation

**Question:** What guidance is available for preparing a project document, including theory of change, risks, workplan, and budget justification?

**Expected behavior:** Routes to Programme Development with topic_area=guidelines_templates.

## 26. Happy path - Programme Development implementing partner agreement

**Question:** When should DESA use an implementing partner agreement instead of procurement?

**Expected behavior:** Routes to Programme Development with topic_area=implementing_partners_grants.

## 27. Happy path - Programme Development grants due diligence

**Question:** What due diligence is required before approving a grant to an implementing partner?

**Expected behavior:** Routes to Programme Development with topic_area=implementing_partners_grants.

## 28. Happy path - Programme Development IPGC templates

**Question:** Where can I find the IPGC decision template and partner evaluation template for grants?

**Expected behavior:** Routes to Programme Development with topic_area=implementing_partners_grants.

## 29. Happy path - RPTC budget and finance

**Question:** What are the RPTC budget and finance requirements?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

## 30. Happy path - RPTC governance

**Question:** What are the RPTC governance arrangements?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

## 31. Happy path - RPTC roles

**Question:** What are RPTC roles and responsibilities?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

## 32. Happy path - RPTC programme design standards

**Question:** What programme design standards apply to RPTC?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

## 33. Happy path - RPTC evaluation criteria

**Question:** What are the RPTC evaluation criteria?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

## 34. Happy path - RPTC reports

**Question:** Where can I find guidance on RPTC reports?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

## 35. Happy path - PDF / UNPDF

**Question:** What does the UNPDF guidance say about reporting?

**Expected behavior:** Routes to Formulate Response PDF or the temporary not-yet-developed PDF message.

## 36. Happy path - About Cidy

**Question:** How does Cidy work?

**Expected behavior:** Routes to Formulate Response Cidy About with topic_area=about_cidy. No clarification should be required.

## 37. Happy path - About Cidy coverage

**Question:** What knowledge sources does Cidy currently use?

**Expected behavior:** Routes to Formulate Response Cidy About with topic_area=about_cidy.

## 38. Happy path - About Cidy maintenance

**Question:** Who maintains Cidy's knowledge?

**Expected behavior:** Routes to Formulate Response Cidy About with topic_area=about_cidy.

## 39. Clarification path - fund to DA

**Question:** How do I write an evaluation report?

**Clarification:** Development Account (DA)

**Expected behavior:** Classifier asks fund clarification. Clarifier maps Development Account (DA) to knowledge_domain=da, funding_stream=DA, topic_area=evaluation_design, intentStatus=ready_to_route. Router routes to Formulate Response DA.

## 40. Clarification path - fund to RPTC

**Question:** What are the reporting requirements?

**Clarification:** RPTC

**Expected behavior:** Classifier asks fund clarification. Clarifier maps to knowledge_domain=rptc, funding_stream=RPTC. Router routes to RPTC or temporary not-yet-developed RPTC message.

## 41. Clarification path - fund to PDF

**Question:** Which reporting template should I use?

**Clarification:** UNPDF / PDF

**Expected behavior:** Classifier asks fund or artifact clarification. After UNPDF/PDF selection, Clarifier maps to knowledge_domain=pdf, funding_stream=PDF. Router routes to PDF or temporary not-yet-developed message.

## 42. Clarification path - fund not sure

**Question:** Are travel costs eligible?

**Clarification:** Not sure

**Expected behavior:** Classifier asks fund clarification. Clarifier maps Not sure to general_cd or programme_development depending configured default. Router should avoid unsafe fund-specific answer and likely route to User Feedback or general guidance.

## 43. Clarification path - domain to DA

**Question:** I need help with a project. Where do I start?

**Clarification:** Development Account (DA)

**Expected behavior:** Classifier asks domain clarification. Clarifier maps to knowledge_domain=da, funding_stream=DA, topic_area=general or project_planning_design. Router routes to Formulate Response DA.

## 44. Clarification path - domain to Programme Development

**Question:** I need help with a project. Where do I start?

**Clarification:** Programme Development

**Expected behavior:** Clarifier maps to knowledge_domain=programme_development, funding_stream=UNCLEAR. Router routes to Programme Development.

## 45. Clarification path - domain to Evaluation Evidence

**Question:** I need help understanding project performance. Where should I look?

**Clarification:** Project Evaluations / Lessons Learned

**Expected behavior:** Clarifier maps to knowledge_domain=programme_development, topic_area=projects_evaluations and routes to Programme Development.

## 46. Clarification path - domain to About Cidy

**Question:** I need help. What is this tool?

**Clarification:** About Cidy

**Expected behavior:** Clarifier maps to knowledge_domain=about_cidy. Router routes to Formulate Response Cidy About.

## 47. Clarification path - domain to RPTC

**Question:** Can you help me with a project report?

**Clarification:** RPTC

**Expected behavior:** Clarifier maps to knowledge_domain=rptc, funding_stream=RPTC. Router routes to RPTC.

## 48. Clarification path - domain typed DA

**Question:** Can you help me with a project?

**Clarification:** DA

**Expected behavior:** Typed answer DA should normalize to knowledge_domain=da and funding_stream=DA. Router routes to DA.

## 49. Clarification path - domain typed Development Account

**Question:** Can you help me with a project?

**Clarification:** Development Account

**Expected behavior:** Typed answer should normalize to DA. Router routes to Formulate Response DA.

## 50. Clarification path - domain typed UNPDF

**Question:** What guidance applies to this project?

**Clarification:** UNPDF

**Expected behavior:** Typed answer should normalize to knowledge_domain=pdf, funding_stream=PDF.

## 51. Clarification path - artifact concept note

**Question:** Where is the template?

**Clarification:** Concept note

**Expected behavior:** Classifier asks artifact clarification. Clarifier maps topic_area=project_planning_design. If funding stream remains unclear, it may ask a second fund clarification or route to Programme Development/general depending configuration.

## 52. Clarification path - artifact evaluation report

**Question:** How do I fill out the document?

**Clarification:** Evaluation report

**Expected behavior:** Clarifier maps topic_area=evaluation_design. If fund is unclear and fund-specific guidance is needed, it asks second clarification; otherwise routes based on current domain.

## 53. Clarification path - artifact progress report

**Question:** Can you help me write the report?

**Clarification:** Progress report

**Expected behavior:** Clarifier maps topic_area=monitoring_reporting. If fund is unclear, it may ask fund clarification before routing.

## 54. Clarification path - artifact management response

**Question:** Which form should I use after an evaluation?

**Clarification:** Management response

**Expected behavior:** Clarifier maps topic_area=evaluation_design. Route depends on clarified/current domain, usually DA if DA is selected later.

## 55. Clarification path - second attempt succeeds

**Question:** Which template should I use?

**Clarification:** Attempt 1: something invalid. Attempt 2: Development Account (DA).

**Expected behavior:** Clarifier increments attempts, reprompts once, then maps DA correctly and routes to Formulate Response DA before max attempts is exceeded.

## 56. Clarification path - max attempts dead end

**Question:** Which template should I use?

**Clarification:** Attempt 1: random text. Attempt 2: still random text.

**Expected behavior:** Clarifier sets intentStatus=dead_end and requiresClarification=No. Router routes to User Feedback.

## 57. Vague path - domain clarification

**Question:** Where do I start?

**Expected behavior:** Classifier should not route directly. It should set requires_clarification=Yes, clarification_type=domain.

## 58. Vague path - template clarification

**Question:** I need a template.

**Expected behavior:** Classifier should ask artifact or fund clarification, not search knowledge directly.

## 59. Vague path - report clarification

**Question:** Can you help me write the report?

**Expected behavior:** Classifier should ask artifact and/or fund clarification. It should not route until enough information is available.

## 60. Vague path - guidance clarification

**Question:** What guidance is available?

**Expected behavior:** Classifier should ask domain clarification because the domain is unclear.

## 61. Vague path - project support clarification

**Question:** Can Cidy help me with my project?

**Expected behavior:** Classifier should ask domain clarification or route to About Cidy depending model judgment; should not fabricate a specific fund.

## 62. Out of scope - weather

**Question:** What is the weather in New York today?

**Expected behavior:** Classifier sets knowledge_domain=out_of_scope, requires_clarification=No. Router sends controlled scope message and routes to User Feedback.

## 63. Out of scope - sports

**Question:** Who won the last World Cup?

**Expected behavior:** Routes to User Feedback as out_of_scope. No clarification should be asked.

## 64. Out of scope - poem

**Question:** Write me a poem about cats.

**Expected behavior:** Routes to User Feedback as out_of_scope. No knowledge search.

## 65. Out of scope - laptop help

**Question:** How do I fix my laptop screen?

**Expected behavior:** Routes to User Feedback as out_of_scope.

## 66. Out of scope - stock investment

**Question:** What stock should I buy this week?

**Expected behavior:** Routes to User Feedback as out_of_scope.

## 67. Happy path - RPTC activity proposal template

**Question:** What information is required in an RPTC activity proposal template?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

**Date created:** 2026-05-26

## 68. Happy path - RPTC common reporting standards

**Question:** What are the common reporting standards and minimum data points for RPTC activities?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

**Date created:** 2026-05-26

## 69. Happy path - RPTC IRA guidance

**Question:** What guidance applies to Inter-Regional Adviser recruitment, renewal, reporting lines, and administration?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

**Date created:** 2026-05-26

## 70. Happy path - RPTC activity report template

**Question:** What should be captured in an RPTC activity report template after an activity?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

**Date created:** 2026-05-26

## 71. Happy path - RPTC planning and approval process

**Question:** How are RPTC activities planned, approved, revised, and reported after completion?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_guidance_templates.

**Date created:** 2026-05-26

## 72. Happy path - RPTC 2024 achievements

**Question:** What were the main achievements of the Regular Programme of Technical Cooperation in 2024?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_progress_reports.

**Date created:** 2026-05-26

## 73. Happy path - RPTC 2024 countries requests interventions

**Question:** How many countries, requests, interventions, and people were supported through RPTC in 2024?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_progress_reports.

**Date created:** 2026-05-26

## 74. Happy path - RPTC implementing entities

**Question:** Which UN implementing entities delivered RPTC activities, and how did their results differ?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_progress_reports.

**Date created:** 2026-05-26

## 75. Happy path - RPTC SIDS LDC LLDC support

**Question:** How did RPTC support least developed countries, landlocked developing countries, and small island developing States?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_progress_reports.

**Date created:** 2026-05-26

## 76. Happy path - RPTC future recommendations

**Question:** What challenges and recommendations does the RPTC progress report identify for strengthening future years?

**Expected behavior:** Routes to Formulate Response RPTC with topic_area=rptc_progress_reports.

**Date created:** 2026-05-26

## 77. Happy path - Programme Development Resident Coordinator mission notice

**Question:** When should DESA inform the RC or RCO about a planned country mission?

**Expected behavior:** Routes to Programme Development with topic_area=resident_coordinator.

**Date created:** 2026-05-27

## 78. Happy path - Programme Development UNSDCF alignment

**Question:** How should DESA align country-level support with the CCA and UNSDCF processes?

**Expected behavior:** Routes to Programme Development with topic_area=resident_coordinator.

**Date created:** 2026-05-27

## 79. Happy path - Programme Development UNCT membership

**Question:** When can DESA become a UNCT member or UNSDCF signatory?

**Expected behavior:** Routes to Programme Development with topic_area=resident_coordinator.

**Date created:** 2026-05-27

## 80. Happy path - Programme Development strategic priorities

**Question:** What are DESA's main action areas for 2023?

**Expected behavior:** Routes to Programme Development with topic_area=cd_strategy.

**Date created:** 2026-05-27

## 81. Happy path - Programme Development service delivery model

**Question:** What are the five service lines or areas of work in DESA's capacity development strategy?

**Expected behavior:** Routes to Programme Development with topic_area=cd_strategy.

**Date created:** 2026-05-27

## 82. Clarification path - Programme Development strategy from broad Cidy question

**Question:** How does the knowledge hub prioritize requests?

**Clarification:** Programme Development

**Expected behavior:** Classifier may ask domain clarification for broad Cidy-related knowledge hub wording. Clarifier maps Programme Development and routes to Programme Development with topic_area=cd_strategy.

**Date created:** 2026-05-27

## 83. Happy path - About Cidy overview

**Question:** What is Cidy and what problem is it intended to solve?

**Expected behavior:** Intent Classifier sets knowledge_domain=about_cidy, funding_stream=UNCLEAR, topic_area=about_cidy, requires_clarification=No. Intent Router routes to Formulate Response Cidy About.

**Date created:** 2026-05-27

## 84. Happy path - About Cidy comparison

**Question:** How does Cidy differ from a general-purpose AI chatbot?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 85. Happy path - About Cidy coverage

**Question:** Which topics and knowledge areas does Cidy currently cover?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 86. Happy path - About Cidy user questions

**Question:** What kinds of DA, RPTC, Programme Development, and general CDPMO questions can users ask Cidy?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 87. Happy path - About Cidy prompt examples

**Question:** What are examples of good user questions for Cidy?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 88. Happy path - About Cidy routing flow

**Question:** How does Cidy classify a question and route it to the right knowledge source?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 89. Happy path - About Cidy low confidence

**Question:** What happens when Cidy is uncertain or the answer has low confidence?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 90. Happy path - About Cidy architecture

**Question:** What are the main components of Cidy's Copilot Studio architecture?

**Expected behavior:** Routes directly to Formulate Response Cidy About with topic_area=about_cidy.

**Date created:** 2026-05-27

## 91. Greeting path - English greeting only

**Question:** Hi

**Expected behavior:** User Inquiry greeting classifier sets isGreeting=true and routes to Greeting. Greeting sends the Cidy scope message, clears Global.userQuestion and Global.awaitingNewQuestion, then returns to User Inquiry for a fresh substantive question. It should not route the greeting to Intent.

**Date created:** 2026-05-28

## 92. Greeting path - Multilingual greeting only

**Question:** Bonjour

**Expected behavior:** User Inquiry greeting classifier sets isGreeting=true and routes to Greeting. Greeting sends the Cidy scope message, clears Global.userQuestion and Global.awaitingNewQuestion, then returns to User Inquiry for a fresh substantive question. It should not route the greeting to Intent.

**Date created:** 2026-05-28

## 93. Greeting guard - greeting plus substantive question

**Question:** Good morning, how do I design a DA concept note?

**Expected behavior:** User Inquiry greeting classifier sets isGreeting=false because the input includes a substantive question. The input continues to Intent and routes to Formulate Response DA with funding_stream=DA and topic_area=project_planning_design.

**Date created:** 2026-05-28

## 94. Exit Cidy flow command - exact phrase

**Question:** exit Cidy flow

**Expected behavior:** Exit Cidy Flow switches Global.cidyMode to open, sends the outside structured Cidy flow message, and continues future user messages through open conversation mode without routing the command to Intent.

**Date created:** 2026-05-31

## 95. Exit Cidy flow command - Cindy typo

**Question:** exit Cindy flow

**Expected behavior:** Exit Cidy Flow recognizes the Cindy typo, switches Global.cidyMode to open, sends the outside structured Cidy flow message, and does not route the command as an About Cidy knowledge question.

**Date created:** 2026-05-31

## 96. Return to Cidy rescue path

**Question:** Back to Cidy flow

**Expected behavior:** Return to Cidy topic cancels other topics, clears active Cidy state, asks for a fresh substantive question, stores it as Global.userQuestion, and routes that captured question to Intent_c8W.

**Date created:** 2026-05-28

## 97. Happy path - Country Data active projects by country

**Question:** Which projects are currently active in Kenya?

**Expected behavior:** Routes directly to Formulate Response Programme Development with knowledge_domain=programme_development, funding_stream=UNCLEAR, topic_area=country_data, requires_clarification=No. Response uses the Country Data folder for active projects by country.

**Date created:** 2026-06-02

## 98. Happy path - Country Data proposal year list

**Question:** I'd like to see 2026 proposals.

**Expected behavior:** Routes directly to Formulate Response Programme Development with knowledge_domain=programme_development, funding_stream=UNCLEAR, topic_area=country_data, requires_clarification=No. Response uses the Country Data folder for proposal-year filtering.

**Date created:** 2026-06-02

## 99. Happy path - Country Data LDC activity count

**Question:** How many activities in 2025 targeted LDCs?

**Expected behavior:** Routes directly to Formulate Response Programme Development with knowledge_domain=programme_development, funding_stream=UNCLEAR, topic_area=country_data, requires_clarification=No. Response uses the Country Data folder for activity counts by year and LDC target group.

**Date created:** 2026-06-02

