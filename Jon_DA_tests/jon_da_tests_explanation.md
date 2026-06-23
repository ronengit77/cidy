# Jon DA Tests

## Formulate_Response_DA_broad_test.yaml

Ignores topic area entirely. Single search against one folder, "NR - DA All". One pass, no fallback retry. NR stands for new routing refering to file upload knowledge option.

This was also done for Sharepoint connect file option but yielded bad results.

## Formulate_Response_DA_broad_to_narrow_test.yaml

*** Gave best results across 3 different ablations tested (see excel). ***

Also uses the NR or file upload knowledge option

4 branches by topic area: `project_planning_design`, `evaluation_design`, `monitoring_reporting`, `general`.

- PPD, evaluation_design, monitoring_reporting: Pass 1 searches broad "NR - DA All"; Pass 2 (only if Pass 1 is blank) searches the matching narrow folder.
- general: single pass against the general DA folder only, no Pass 2.

Knowledge source IDs for the narrow folders and some broad references are left blank (`[]`) until set manually in Copilot Studio.

## Shared traits

- `userInput` uses plain `Global.userQuestion` only — no question-enhancer text.
- DEBUG messages report `HAS CONTENT` / `BLANK`, never the raw answer text, so the answer doesn't get shown twice.
- Debug output only appears when `Global.testMode = true`.
