# Git Quick Reference

Basic terminal commands for the Cidy project.

---

## Check what's changed

```bash
git status
```
Shows which files have been modified, added, or are untracked. Run this before anything else.

```bash
git diff
```
Shows the exact line-by-line changes in modified files.

---

## Save your work (commit)

```bash
git add filename.yaml
```
Stage a specific file to be included in the next commit.

```bash
git add .
```
Stage **all** changed files at once. Use carefully — check `git status` first.

```bash
git commit -m "Your message here"
```
Save a snapshot with a short description of what you did. Be specific — e.g. `"Add DA evaluation branch — 5 questions validated"`.

---

## Upload to GitHub (push)

```bash
git push origin staging
```
Upload your committed changes to the remote `staging` branch.

```bash
git push -u origin your-branch-name
```
First-time push for a new personal branch. The `-u` sets up tracking so future pushes only need `git push`.

---

## Download from GitHub (pull)

```bash
git pull
```
Download and apply the latest changes from GitHub to your current branch. Do this at the start of every work session.

---

## Branches

```bash
git branch
```
List all local branches. The one with `*` is your current branch.

```bash
git branch -a
```
List all branches including remote ones.

```bash
git checkout staging
```
Switch to the `staging` branch.

```bash
git checkout -b alice/da-evaluation
```
Create a new branch called `alice/da-evaluation` and switch to it. Always branch off `staging`, not `main`.

---

## See history

```bash
git log --oneline
```
Show recent commits in a compact one-line format.

```bash
git log --oneline -10
```
Show only the last 10 commits.

---

## Undo a local change (before committing)

```bash
git checkout -- filename.yaml
```
Discard all unsaved changes to a file and restore the last committed version. **This cannot be undone.**

---

## Typical workflow from start to finish

```bash
# 1. Get the latest version
git checkout staging
git pull

# 2. Create your personal branch
git checkout -b yourname/da-evaluation

# 3. Do your work in the files, then check what changed
git status

# 4. Stage the files you want to commit
git add Testing_DA_Evaluation.yaml

# 5. Commit with a message
git commit -m "Add DA evaluation test topic — 6 questions validated"

# 6. Push to GitHub
git push -u origin yourname/da-evaluation

# 7. Open a pull request on GitHub → into staging
```

---

## Common errors and fixes

| Error | What it means | Fix |
|---|---|---|
| `Your branch is behind origin/staging` | Someone else pushed changes you don't have | Run `git pull` |
| `Please commit your changes before merging` | You have unsaved changes that conflict | Commit or discard them first |
| `protected branch` on push | The branch requires a pull request | Push to your personal branch and open a PR |
| `fatal: not a git repository` | You're in the wrong folder | Navigate to the project folder first |
| `-1s` response time in Cidy | `requestStartTime` not set | `user_inquiry.yaml` changes not published yet |
