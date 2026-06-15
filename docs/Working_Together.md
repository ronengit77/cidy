# Working Together on Cidy

A guide for the Cidy team on how we collaborate on knowledge updates, topic area testing, and publishing.

---

## How our work is organized

Cidy's knowledge and logic lives in YAML files in this folder. Each file is a topic in Copilot Studio. When we want to add or improve a knowledge area, we edit these files locally, test in Copilot Studio, and then publish.

We use **Git** to make sure everyone's work is tracked and we can always roll back if something breaks. Think of Git like a shared save history for the whole folder — every change is recorded, who made it, when, and why.

---

## Git: the basics you need

### What Git does
Git keeps a complete history of every version of every file. If we break something, we can go back. If two people edit different parts of the same file, Git can merge them. If you're not sure what changed, Git can show you a diff.

### Branches
A **branch** is an isolated copy of the work where you can make changes safely without affecting anyone else. Think of it like a personal working notebook that you later hand in for review.

We have two permanent branches:

| Branch | Purpose |
|---|---|
| `main` | The clean, stable version. Matches what has been published to Copilot Studio. Only the lead merges into this. |
| `staging` | The integration branch. Validated changes from all team members accumulate here before being pushed to production. |

You always start your work from `staging`, not from `main`.

### Your personal branch
When you start working on a topic area, you create your own branch from `staging`. Name it:

```
[your-name]/[funding-stream]-[topic-area]
```

Examples: `alice/da-evaluation`, `bob/rptc-activity-reporting`

---

## Setup (one time only)

### 1. Install Git
Download from https://git-scm.com/downloads and install with default options.

### 2. Install GitHub Desktop (recommended for beginners)
Download from https://desktop.github.com — this gives you a visual interface so you don't have to type Git commands.

### 3. Clone the repository
In GitHub Desktop: File → Clone repository → paste the repo URL → choose where to save it on your computer.

This downloads the entire project to your machine.

---

## Your daily workflow

### Starting a new topic area

**Step 1 — Get the latest staging branch**

In GitHub Desktop:
- Switch to the `staging` branch (top left dropdown)
- Click "Fetch origin" then "Pull origin" to get the latest changes

**Step 2 — Create your personal branch**

In GitHub Desktop:
- Branch → New Branch
- Name it `[your-name]/[funding-stream]-[topic-area]`
- Make sure it says "from staging" before confirming

**Step 3 — Do your work**

Follow the topic area preparation process (see `How_to_prepare_a_topic_area_branch.md`):
1. Copy `_test_topic_area_isolation_template.yaml` → rename to `Testing_[FundingStream]_[TopicArea].yaml`
2. Fill in all `[REPLACE: ...]` values
3. Push your test topic to Copilot Studio and validate
4. Update only your conditionItem branch in `Formulate_Response_[FundingStream]_Staging.yaml`

**Step 4 — Save your work (commit)**

After each meaningful unit of work, save a checkpoint in Git. In GitHub Desktop:
- Bottom left: write a short summary of what you did (e.g. "Add DA evaluation test topic — validated 8 questions")
- Click "Commit to [your-branch-name]"

Commit often. Each commit is a restore point.

**Step 5 — Share your work (push)**

In GitHub Desktop, click "Push origin" (top right). This uploads your commits so others can see them and the lead can review.

**Step 6 — Request a review (pull request)**

In GitHub Desktop: Branch → Create Pull Request. This opens a page where you describe what you did and ask for it to be merged into `staging`.

The lead reviews, may ask for changes, and then merges your branch into `staging`.

---

## Branch protection rules (enforced by GitHub)

These rules are configured directly on the repository and cannot be bypassed by team members:

| Branch | Rule |
|---|---|
| `main` | No direct pushes allowed — not even the lead. All changes must come in via a pull request with at least 1 approval. |
| `staging` | Team members cannot push directly. All contributions must come via a pull request from a personal branch. The lead can push directly to staging when needed. |

If you try to `git push` to `staging` or `main` directly and get a "protected branch" error, that is expected. Open a pull request instead.

---

## What you should NOT do

- **Do not push directly to `main`** — blocked by GitHub; open a PR instead
- **Do not push directly to `staging`** — blocked by GitHub for all team members; open a PR from your personal branch
- **Do not edit `Formulate_Response_[X].yaml` (production files)** — only edit the `Staging` version
- **Do not publish in Copilot Studio** — only the lead publishes
- **Do not edit another person's branch** — if you need to coordinate, ask first

---

## The Cidy-specific workflow in one picture

```
staging
   │
   ├── alice/da-evaluation        ← Alice works here
   │       │
   │       └── tests → validates → updates Staging YAML → PR to staging
   │
   ├── bob/da-steering-committee  ← Bob works here
   │       │
   │       └── tests → validates → updates Staging YAML → PR to staging
   │
staging  ← lead reviews, merges both PRs
   │
   └── lead pushes staging YAML to Copilot Studio → validates end-to-end → publishes
          │
         main ← lead merges staging into main after successful publish
```

---

## File naming conventions

| File pattern | Purpose |
|---|---|
| `Testing_[FundingStream]_[TopicArea].yaml` | Your isolated test topic — stays in Copilot Studio as a draft, never published |
| `Formulate_Response_[FundingStream]_Staging.yaml` | The staging integration file — this is what gets pushed to production when ready |
| `Formulate_Response_[FundingStream].yaml` | Production file — do not edit directly |
| `_test_topic_area_isolation_template.yaml` | Starting template — copy, never edit the original |

---

## Quick reference: Git commands (if you prefer the terminal)

```bash
# Get latest staging
git checkout staging
git pull

# Create your branch
git checkout -b alice/da-evaluation

# Save a checkpoint
git add Testing_DA_Evaluation.yaml Formulate_Response_DA_Staging.yaml
git commit -m "Add DA evaluation test topic — 8 questions validated, CONFIDENCE 4-5"

# Upload your work
git push -u origin alice/da-evaluation
```

---

## When things go wrong

**"I edited the wrong file"**
In GitHub Desktop: right-click the file → Discard Changes. This restores it to the last committed state.

**"I committed something I shouldn't have"**
Tell the lead — do not try to fix it yourself with advanced Git commands.

**"I pulled and now there are conflicts"**
Tell the lead — merge conflicts in YAML files are easy to resolve but require care.

**"I'm not sure if my changes are saved"**
In GitHub Desktop, any file with unsaved changes shows in the left panel. If the panel is empty, your working directory is clean.
