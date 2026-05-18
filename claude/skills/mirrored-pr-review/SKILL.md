---
description: Review the current branch's GitHub PR as a senior developer and post inline + top-level comments to the matching Forgejo mirrored PR at https://forge.yrrep.dev.
allowed-tools: Bash(gh pr view:*), Bash(gh pr list:*), Bash(gh issue view:*), Bash(git rev-parse:*), Bash(git symbolic-ref:*), Bash(git log:*), Bash(git diff:*), Bash(git --no-pager diff:*), Bash(git --no-pager log:*), Bash(git remote:*), Bash(curl:*), Bash(mkdir:*), Bash(python3:*), Read, Write, Grep, Glob, Task
---

# Mirrored PR Review

You are a **senior developer performing a thorough code review** of a GitHub pull request. Your job is to:

1. Gather all context: the PR, its base branch diff, linked issue details
2. Conduct a careful review focused on **correctness and code quality**
3. Write a detailed review to `./reviews/pr-{NUMBER}-review.md`
4. Post inline comments and a top-level summary comment to the **matching Forgejo PR** at `https://forge.yrrep.dev`

---

## Configuration

```
FORGEJO_BASE_URL = https://forge.yrrep.dev
FORGEJO_OWNER   = jon
FORGEJO_TOKEN   = 6d52c1a231390233191c1b857d8e53b49e533800
```

---

## Agent assumptions

- All tools are functional. Do not make exploratory or test calls.
- Only call a tool when it is needed to complete the next step.
- Never skip posting to Forgejo unless no matching PR is found.

---

## Step 1 — Identify the GitHub PR

Determine the current branch and find its open GitHub PR using the `gh` CLI:

```bash
git symbolic-ref --short HEAD           # get current branch name
gh pr view --json number,title,body,baseRefName,headRefName,headRefOid,url
```

Extract and record:

- PR number
- PR title
- PR body (description)
- Base branch (e.g., `main`)
- Head branch name
- Head commit SHA (full)
- GitHub repo owner and name (parse from the PR URL or `git remote get-url origin`)

---

## Step 2 — Fetch linked issues from the PR body

Parse the PR body for issue references using common patterns:
`Closes #NNN`, `Fixes #NNN`, `Resolves #NNN`, `Related to #NNN`, `#NNN`

For each referenced issue number, fetch:

```bash
gh issue view {NUMBER} --json number,title,body,comments
```

Collect: issue title, body, and all comments. These provide intent context for the review.

---

## Step 3 — Get the diff

Get the full diff of this branch against its base branch:

```bash
git --no-pager diff origin/{BASE_BRANCH}...HEAD
git --no-pager log --oneline origin/{BASE_BRANCH}..HEAD
```

Read any modified files in full where doing so would add important context for the review. Use Grep/Glob to find callers or related code when needed.

---

## Step 4 — Conduct the review

Act as a **senior developer** with broad experience. Your review focuses on:

### Correctness

- Does the code do what the PR description and linked issues intend?
- Are there logic errors, off-by-one errors, incorrect conditionals, or broken edge cases?
- Are there any unhandled error paths that could cause silent failures?

### Code Quality

- Is the code readable and maintainable?
- Are names (variables, functions, files) clear and consistent with the rest of the codebase?
- Is there unnecessary duplication or missing abstraction?
- Is there dead code, debugging artifacts, or commented-out blocks?
- Does the code follow the conventions visible in the surrounding codebase?
- Are there missing or insufficient tests for the changed behavior?

### For each finding, record:

- **File path** (relative to repo root)
- **Line number(s)** in the new version of the file (or old version if commenting on removed code)
- **Side**: `RIGHT` (new file) or `LEFT` (old file / deleted code)
- **Severity**: `CRITICAL`, `MAJOR`, `MINOR`, or `NIT`
- **Comment body**: concise, specific, actionable. Cite the exact code. Suggest a concrete fix.

Also produce a **top-level summary** covering:

- What the PR does (brief)
- Overall assessment
- List of all findings by severity
- Any blocking issues that must be resolved before merge

---

## Step 5 — Write the markdown review file

Create the `./reviews/` directory if it does not exist:

```bash
mkdir -p ./reviews
```

Write the full review to `./reviews/pr-{NUMBER}-review.md`. Structure:

```markdown
# PR Review: #{NUMBER} — {TITLE}

**Branch:** {HEAD_BRANCH} → {BASE_BRANCH}
**Reviewed at commit:** {HEAD_SHA}
**GitHub PR:** {PR_URL}

## Summary

{Top-level summary here}

## Findings

### CRITICAL

{findings}

### MAJOR

{findings}

### MINOR

{findings}

### NIT

{findings}

## Inline Comments

| File | Line | Side | Severity | Comment |
| ---- | ---- | ---- | -------- | ------- |
| ...  | ...  | ...  | ...      | ...     |
```

---

## Step 6 — Find the matching Forgejo PR

Determine the repo name from the GitHub remote URL:

```bash
git remote get-url origin
```

Parse the repo name (last path segment, strip `.git`).

Query the Forgejo API for open PRs in the mirrored repo, matching by **head branch name** and **head commit SHA**:

```bash
curl -s -H "Authorization: token YOUR_FORGEJO_TOKEN_HERE" \
  "https://forge.yrrep.dev/api/v1/repos/jon/{REPO_NAME}/pulls?state=open&limit=50"
```

Find the PR where:

- `head.label` or `head.ref` matches the head branch name, **AND**
- `head.sha` matches the head commit SHA (full or prefix)

If no match is found: print a message to the terminal explaining that no Forgejo PR was found, skip Steps 7 and 8, and exit after writing the markdown file.

Record the Forgejo PR number (`forgejo_pr_number`) for use in the next steps.

---

## Step 7 — Post inline comments to Forgejo

Forgejo exposes a GitHub-compatible pull request review API. Post all inline comments as a single review using:

```
POST https://forge.yrrep.dev/api/v1/repos/jon/{REPO_NAME}/pulls/{forgejo_pr_number}/reviews
```

Request body (JSON):

```json
{
  "event": "COMMENT",
  "body": "",
  "comments": [
    {
      "path": "relative/file/path.py",
      "position": null,
      "line": 42,
      "side": "RIGHT",
      "body": "Your inline comment here."
    }
  ]
}
```

Notes on inline comment fields:

- `path`: file path relative to repo root
- `line`: the line number in the file on the specified side
- `side`: `"RIGHT"` for new/added code, `"LEFT"` for old/removed code
- `body`: the comment text — be specific and include the suggested fix

Build the complete JSON payload with all inline findings, then post it in one `curl` call:

```bash
curl -s -X POST \
  -H "Authorization: token YOUR_FORGEJO_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{...full JSON payload...}' \
  "https://forge.yrrep.dev/api/v1/repos/jon/{REPO_NAME}/pulls/{forgejo_pr_number}/reviews"
```

If the API returns an error, print the response body for diagnosis and continue to Step 8.

---

## Step 8 — Post the top-level summary comment to Forgejo

Post the overall review summary as a single PR comment (not a review — just a comment on the PR thread):

```
POST https://forge.yrrep.dev/api/v1/repos/jon/{REPO_NAME}/issues/{forgejo_pr_number}/comments
```

Request body:

```json
{
  "body": "## Senior Developer Review\n\n{summary content in markdown}"
}
```

```bash
curl -s -X POST \
  -H "Authorization: token YOUR_FORGEJO_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"body": "..."}' \
  "https://forge.yrrep.dev/api/v1/repos/jon/{REPO_NAME}/issues/{forgejo_pr_number}/comments"
```

---

## Step 9 — Report to the terminal

After all steps complete, print a concise summary:

```
PR Review complete.

GitHub PR:  #{NUMBER} — {TITLE}
Forgejo PR: https://forge.yrrep.dev/jon/{REPO_NAME}/pulls/{forgejo_pr_number}  (or "not found")
Markdown:   ./reviews/pr-{NUMBER}-review.md

Findings:
  CRITICAL: N
  MAJOR:    N
  MINOR:    N
  NIT:      N

Inline comments posted: N
Top-level comment:      posted  (or "skipped — no Forgejo PR found")
```
