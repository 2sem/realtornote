---
name: law-content-update
description: Summarize the law amendments downloaded by law-update-check (Laws/pending.json) and update the 공인중개사 study content (Projects/App/Resources/Content/parts) to match, then re-package the encrypted Content.zip. Use when asked "법령 개정 내용 반영", "update content with new laws", "summarize downloaded laws", or after law-update-check.
argument-hint: "[법령명 or subject to limit, e.g. 공인중개사법 | 공법]"
---

# Law content update

Turns downloaded amendments into edits of the study summaries. The repo is public, so plaintext `Content/` is gitignored and ships only as `Projects/App/Content.zip.secret` (git-secret) — never commit or paste content text anywhere public.

## 1. Preflight

- `Laws/pending.json` should exist (run `law-update-check` first) — it tells which laws changed at all; `law_diff.py` itself only needs the API key.
- `Projects/App/Resources/Content/` must exist (see law-update-check preflight to unpack it).
- Git: if on `main`, create a branch `content/law-update-<YYYYMMDD>`; if on an `a.b.c` release branch, checkout main first and branch from there. Never reuse a merged branch name.
- Back up before editing so the user can review a diff (Content is gitignored, `git diff` shows nothing):
  ```bash
  B=Laws/.backup/Content-$(date +%Y%m%d%H%M%S); mkdir -p Laws/.backup && cp -R Projects/App/Resources/Content "$B"
  ```
- Work **one part at a time** (argument: a part id, or a subject → go through its parts in order). With no argument, propose the smallest pending scope and confirm with the user — a full pass is large.

## 2. Per part: get the net diff (token budget)

Don't read `Laws/<법령명>/*.md` version files or `Laws/REPORT.md` — they hold every intermediate amendment plus full texts. Use `Scripts/law_diff.py`, which compares only the version in force when the content was last updated (`--from`, default 20241212) with the one in force on the exam date (`--to`, default 2026-10-31):

```bash
python3 Scripts/law_diff.py diff --part <id> > <scratchpad>/part<id>.diff; wc -c <scratchpad>/part<id>.diff
```

- Output is limited to the articles in `Scripts/part_articles.json` for that part, with 개정 tags and wording-only 정비 (하여야→해야, 아니한→않은) normalized away; `~` lines are inline word diffs (`[-old-]{+new+}`), `+`/`-` whole lines.
- If stderr says a law has no 조문 범위 for the part: run `python3 Scripts/law_diff.py toc "<법령명>" | grep -A1 "<장 keyword>"` (grep — never print a whole TOC of a big law), pick the 장/조 the part covers, add them to `part_articles.json` (`""` if the law doesn't concern the part), rerun. This is a one-time cost; the mapping is committed and reused next year.
- If the diff is still over ~20KB, narrow the ranges or split with `--law`. Read it once; don't re-run to re-read.
- Classify each change: **substantive** (요건, 기간·금액·비율·인원, 주체, 절차, 벌칙, 신설/삭제, renamed bodies) → reflect; **wording only** → fix only if the old wording is in the content.

## 3. Per part: edit

**Tree parts** (`Projects/App/Resources/Content/parts/<id>.json` exists, no `.txt`): the source is `ContentSource/parts/<id>.md` (syntax in `Scripts/content_tree.py` docstring and `docs/plans/content-tree.md` §2). Edit the Markdown with the same rules below, then:
```bash
python3 Scripts/content_tree.py build <id> --strict        # fails on syntax errors / leftover TODOs
cp ContentSource/build/parts/<id>.json Projects/App/Resources/Content/parts/<id>.json
python3 Scripts/content_tree.py render-a <id>              # what the app will show
```
Show the user `diff -u "$B/…/<id>.md"`-style edits of the Markdown instead of the txt diff. Never recreate the `.txt` for a tree part.

1. Read `Projects/App/Resources/Content/parts/<id>.txt` once (`cat -n`).
2. Edit to match the law in force **on the exam date**. Use `Edit` with small hunks — never rewrite the whole file.
3. Match the existing style exactly:
   - Numbering hierarchy `(1)` → `1)` → `a)` → `-`, `◎` sub-headings, `⇒` for conclusions; plain text, no markdown.
   - Terse phrases (`~할 것`, `~함`, `~ 가능`), `.` as the list separator inside a line (`시.도지사`), same spacing as neighbouring lines.
   - Change only what the law changed; don't rephrase untouched lines. Remove content for deleted provisions; add new provisions only when exam-relevant, placed where they belong in the outline.
4. Never create, delete, or renumber parts and never touch `subjects/*.json` (ids are synced by id into SwiftData; favorites reference them). If a change genuinely needs a new part, stop and ask.
5. Other parts that merely mention a renamed term (e.g. a body's new name) — list them in the summary as follow-ups instead of opening them now.

After each part, show the user the edit: `diff -u "$B/parts/<id>.txt" Projects/App/Resources/Content/parts/<id>.txt`.

## 4. Summary

Write/append `Laws/SUMMARY.md` (gitignored) and give the user the same in chat, per part:

| 파트 | 법령 (시행일) | 주요 개정 | 반영 내용 | 반영 안 함 (사유) / 후속 파트 |

Then ask the user to review the edits (`diff -ru "$B" Projects/App/Resources/Content`). **Stop here until the user approves.**

## 5. Package (after approval)

1. Bump the patch of `version` in `Projects/App/Resources/Content/manifest.json` (e.g. `1.2.3` → `1.2.4`). Required: `ContentSyncService` only re-syncs when this version is newer than the one stored on device, so without the bump users never get the edits.
2. Rebuild the zip with the same layout (`Content/` at the root — CI runs `unzip -o Projects/App/Content.zip -d Projects/App/Resources`):
   ```bash
   rm -f Projects/App/Content.zip
   (cd Projects/App/Resources && zip -rqX ../Content.zip Content -x '*.DS_Store')
   unzip -l Projects/App/Content.zip | sed -n 4,6p   # expect Content/...
   ```
3. If any `ContentSource/parts/*.md` changed, refresh the source backup first: `rm -f ContentSource.zip && zip -rqX ContentSource.zip ContentSource/parts -x '*.DS_Store'`.
   Encrypt: `git secret hide -m` (re-encrypts changed files only). Stage `Projects/App/Content.zip.secret`, `ContentSource.zip.secret` (and `.gitsecret/paths/mapping.cfg` if it changed). Never stage plaintext `Content.zip` or `Content/`.
4. Mark the processed laws reviewed:
   ```bash
   python3 Scripts/check_law_updates.py --update --law "<법령명>"   # per processed law (records the version in force on the exam date; later versions stay 이월)
   ```
   `--law` is a substring match (`건축법` also hits `건축법 시행령`) — only run it for names whose every match was processed. Stage `Scripts/law_versions.json`.
5. Build once so the app still loads the content (the `Content` folder reference must be bundled), then commit (`feat(content): 법령 개정 반영 — <laws>`), push, open a PR with the summary table (no diff/content text in the body — the content is private), and open it in the browser. Don't merge; wait for the user's simulator check.

Don't run `Scripts/verify_content.py` — it compares against the legacy xlsx, which is no longer the source of truth once content is edited.
