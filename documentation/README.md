# Cidy Documentation Tools

## Knowledge Control Center

Open `cidy_knowledge_control_center.html` locally or through GitHub Pages. It reads `cidy_knowledge_inventory.json`, shows route/folder coverage, accepts knowledge-manager updates, and produces a generated to-do list.

Browser-entered updates are saved in localStorage. Use **Export JSON** to download an updated inventory file when you want to commit those updates.

Use **Response Map** from the control center to open `cidy_response_topic_map.html`, which lists existing `Formulate_Response_*.yaml` files and the topic areas, folders, source IDs, mapping status, and instructions under each one. The page supports local CRUD drafts, including moving a topic/folder mapping from one response YAML to another. Drafts persist in browser localStorage and can be exported/imported as JSON for review before updating the source YAML/inventory.

The response YAML files are the source of truth for generated response-map facts. Regenerate `cidy_knowledge_inventory.json` after YAML changes so the HTML reflects the latest topic tags, YAML branch IDs, source IDs, source labels, and source-use instructions. Keep owner units and other manually curated metadata in `cidy_knowledge_overrides.json`.

On GitHub, `.github/workflows/refresh-cidy-inventory.yml` regenerates the inventory after relevant YAML pushes and commits the refreshed generated files. Newly discovered response YAMLs or topic mappings are marked in the inventory and highlighted in yellow on the Response Map.

## Regenerating Inventory From YAML

When a `Formulate_Response_*.yaml` file or `Cidy_Intent_Router.yaml` changes, regenerate the control-center inventory:

```powershell
.\tools\generate_knowledge_inventory.ps1
```

The script:

- scrapes `Cidy_Intent_Router.yaml`,
- discovers all `Formulate_Response_*.yaml` files,
- extracts topic-area conditions,
- extracts knowledge source IDs,
- extracts `Global.sourceUseInstructions` where present,
- writes `documentation/cidy_knowledge_inventory.json`,
- refreshes the embedded fallback inventory inside `documentation/cidy_knowledge_control_center.html`.

## Manual Metadata

Generated facts should stay in `cidy_knowledge_inventory.json`.

Human-maintained metadata should go in `cidy_knowledge_overrides.json`, especially:

- owner units,
- curated folder labels,
- edited source-use instructions,
- knowledge-manager updates,
- review notes.

The generator merges overrides into the generated inventory so those notes survive future YAML scraping.

## Running Intent Route Tests

Run the structural route simulator after updating intent, clarifier, router, or response-topic YAMLs:

```powershell
.\tools\run_intent_test_cases.ps1
```

The runner reads `documentation/Cidy_Intent_Test_Cases_60.json` and writes:

- `documentation/cidy_intent_test_results.json` for every test case and route trace,
- `documentation/cidy_intent_test_failures.json` for failed cases only.

Open `cidy_intent_test_results_viewer.html` from the control center to review the results in a human-readable browser view with filters, failure details, expected behavior, final classification, final route, and the topic-by-topic trace.

The runner does not execute Copilot Studio's AI classifier. It simulates the expected route from the test-case expectation text and validates whether the current YAML inventory can support that route.
