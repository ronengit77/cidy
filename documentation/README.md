# Cidy Documentation Tools

## Knowledge Control Center

Open `cidy_knowledge_control_center.html` locally or through GitHub Pages. It reads `cidy_knowledge_inventory.json`, shows route/folder coverage, accepts knowledge-manager updates, and produces a generated to-do list.

Browser-entered updates are saved in localStorage. Use **Export JSON** to download an updated inventory file when you want to commit those updates.

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
