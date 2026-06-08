# Cidy Copilot Studio Conversation Eval Imports

Generated from `documentation/Cidy_Intent_Test_Cases_90.json` for Copilot Studio conversation evaluation import.

Files:
- `cidy_conversation_eval_all_100.csv`: all 100 cases in the local template shape, useful for review.
- `cidy_conversation_eval_01_001-020.csv` through `cidy_conversation_eval_05_081-100.csv`: five 20-case chunks for Copilot Studio conversation test sets.

Mapping:
- `conversationNumber`: one single-turn conversation per test question.
- `question`: original Cidy intent test question.
- `response`: expected routing behavior from the local test suite.

Notes:
- The local template uses `conversationNumber,question,response`.
- Copilot Studio conversation test sets are limited to 20 test cases in current Microsoft documentation.
- The imported `response` is a reference answer. Test methods are selected after import in Copilot Studio, and routing variables are not automatically asserted unless the evaluation environment exposes them in the conversation transcript or a custom evaluation method is configured.
- For route-level validation, use a custom/classification test method or an evaluation build that emits route/debug state in the transcript.
