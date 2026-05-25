# Cidy Response Topic Update Workflow

Use this workflow every time a `Formulate_Response_*.yaml` topic is created or updated.

## Command

```powershell
.\tools\refresh_after_response_topic_change.ps1
```

## What The Script Does

1. Creates timestamped backups of:
   - `Cidy_Intent.yaml`
   - `Cidy_Intent_Clarifier.yaml`
   - `Cidy_Intent_Router.yaml`
   - `Cidy_Intent_Variables_Defaults.json`

2. Keeps only the latest three backup folders under `Backups/`.

3. Regenerates `documentation/cidy_knowledge_inventory.json` from:
   - `Cidy_Intent_Router.yaml`
   - all existing `Formulate_Response_*.yaml` files
   - `documentation/cidy_knowledge_overrides.json`

4. Synchronizes topic-area tags into:
   - `Cidy_Intent.yaml`
   - `Cidy_Intent_Variables_Defaults.json`

5. Refreshes the embedded inventory in:
   - `documentation/cidy_knowledge_control_center.html`

6. Runs:
   - `tools/run_intent_test_cases.ps1`

7. Writes:
   - `documentation/test_case_yyyy_mm_dd_hh_mm_ss.md`

## Manual Review Rules For Codex

After running the script, Codex must review the generated Markdown report and decide whether additional YAML edits are needed.

### Cidy_Intent.yaml

Update when:
- a new `topic_area` appears in a `Formulate_Response_*.yaml`,
- a new `knowledge_domain` is introduced,
- classifier rules need examples or routing guidance for the new topic.

### Cidy_Intent_Variables_Defaults.json

Update when:
- a new allowed `topic_area`, `knowledge_domain`, or `funding_stream` is introduced.

The script updates `Global.topicArea.allowedValues` automatically from the generated inventory.

### Cidy_Intent_Clarifier.yaml

Review manually when:
- a new topic should appear as a clarification choice,
- a new artifact type should map to a topic area,
- a new domain choice should set a specific topic area,
- a vague user answer should normalize to the new topic.

### Cidy_Intent_Router.yaml

Review manually when:
- a new `Formulate_Response_*.yaml` represents a new `knowledge_domain`,
- a currently not-wired domain should begin routing to a response YAML,
- router status in the response map shows `missing_yaml` or `not_wired`.

For new topic areas inside an existing response YAML, the router usually does not need changes.

## Expected Git Flow

1. Update or create the `Formulate_Response_*.yaml`.
2. Run `.\tools\refresh_after_response_topic_change.ps1`.
3. Review the generated `documentation/test_case_*.md`.
4. Review changed intent/router/clarifier/default files.
5. Commit and push all related YAML, JSON, HTML, test-result, backup, and report changes.

## Notes

The HTML pages do not run local scripts. GitHub Actions regenerates the inventory after relevant pushes, but local work should still use the refresh script before committing so the repo has a reviewable report and fresh test output.
