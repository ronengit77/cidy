# Country Data Retrieval Update - 2026-06-06

## Summary

This update improves the Programme Development `country_data` path so broad country or region questions such as `list work in Fiji` retrieve the correct Country Data source instead of sending noisy routing metadata into the generative answer query.

## Files Updated

- `Formulate_Response_Programme_Development.yaml`
  - Switched the `country_data` branch to the Country Data knowledge source: `copilots_header_3141e.topic.CidyCountryData_VUhURDqxKRX3LM0Lx4RKy`.
  - Added `Global.countryDataEnhancedQuestion` as the query passed to `SearchAndSummarizeContent`.
  - Changed the country-data query input from a long narrative prompt to a compact retrieval string.
  - For Fiji queries, the input begins with `Fiji FJI fji`, followed by country-data anchors such as `country card`, `country record`, `compact country file`, `projects`, `requests`, `proposals`, `activities`, `travel`, and `contacts`.
  - Removed `fileSearchDataSource: DoNotSearchFiles` from the `country_data` generate-answer card.
  - Added a `Global.testMode` debug block before the country-data generate-answer card to show the exact `userInput`, instructions, and knowledge source.
  - Removed country-data fallback to the general DA fallback when `Global.draftResponse` is blank.

- `Cidy_Intent.yaml`
  - Expanded classification and deterministic fallback rules so broad country/region work questions route to `programme_development` / `country_data`.
  - Covered phrasing such as `list work in country X`, `what is happening in country X`, `show work in region X`, `what do we have for SIDS`, `portfolio`, `support`, `current work`, and `ongoing work`.

- `Cidy_Intent_Clarifier.yaml`
  - Updated the country-data clarification option to cover country/region data, work, projects, requests, proposals, activities, travel, contacts, budgets, and statuses.

- `Question_Enhancer.yaml`
  - Added country/region retrieval terms such as country card, country record, regional record, ISO3, lowercase ISO3, compact country file, budget, portfolio, support, and `what is happening`.

- `Cidy_Intent_Variables_Defaults.json`
  - Added `Global.countryDataEnhancedQuestion`.
  - Reset `Global.countryDataEnhancedQuestion` on new user questions.
  - Removed the temporary `testing_country_data` allowed values from normal intent defaults.

## Retrieval Lesson

Do not pass low-value classifier or enhancer values into generate-answer `userInput`. Values such as `UNCLEAR`, `N/A`, `other_unclear`, or raw JSON metadata create retrieval noise and can make the knowledge search miss the right file.

When question enhancer or clarifier output is useful, convert it into concise retrieval text before adding it to `userInput`. For example, prefer:

```text
Fiji FJI fji country card country record compact country file projects requests proposals activities travel contacts
```

over:

```text
Question enhancements: {"funding_stream":"UNCLEAR","topic_area":"other_unclear"}
```

The generate-answer query should be optimized for finding the right source file first. Instructions about how to interpret and format the answer belong in `additionalInstructions`, not in the retrieval query.
