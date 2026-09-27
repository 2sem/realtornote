---
name: law-content-update
description: Summarize the law amendments downloaded by law-update-check (Laws/pending.json) and update the 공인중개사 study content (Projects/App/Resources/Content/parts) to match, then re-package the encrypted Content.zip. Use when asked "법령 개정 내용 반영", "update content with new laws", "summarize downloaded laws", or after law-update-check.
argument-hint: "[법령명 or subject to limit, e.g. 공인중개사법 | 공법]"
---

# Law content update

Turns downloaded amendments into edits of the study summaries. The repo is public, so plaintext `Content/` is gitignored and ships only as `Projects/App/Content.zip.secret` (git-secret) — never commit or paste content text anywhere public.

## 1. Preflight

- `Laws/pending.json` must exist — otherwise run the `law-update-check` skill first.
- `Projects/App/Resources/Content/` must exist (see law-update-check preflight to unpack it).
- Git: if on `main`, create a branch `content/law-update-<YYYYMMDD>`; if on an `a.b.c` release branch, checkout main first and branch from there. Never reuse a merged branch name.
- Back up before editing so the user can review a diff (Content is gitignored, `git diff` shows nothing):
  ```bash
  B=Laws/.backup/Content-$(date +%Y%m%d%H%M%S); mkdir -p Laws/.backup && cp -R Projects/App/Resources/Content "$B"
  ```
- If an argument is given, only process laws whose name contains it (or whose parts belong to that subject). With no argument and many laws pending, propose an order by subject and confirm scope with the user before starting — a full pass is large.

## 2. Per law: summarize

Work **one law at a time** to keep context small. For each entry in `pending.json` → each version file:

1. Read the top of the version file only: the 신구법 비교 list, `검토할 파트` hits, and `## 제개정이유`. Do **not** read the `## 전문` section whole; grep it for a specific article when the diff alone lacks context (e.g. `grep -n -A12 "^제41조(" <file>`).
2. Classify each changed article:
   - **Substantive** — changes requirements, numbers (기간·금액·비율·인원), 주체, 절차, 벌칙, 신설/삭제 조문, renamed bodies/terms. → content must reflect it.
   - **Wording only** — 문장 정비 (하여야→해야, 한자어 순화, 조문 번호만 이동), 타법개정 name changes of other laws. → only fix if the old wording appears in content.
3. Write a 1–3 line Korean summary per version (what changed, 시행일).

## 3. Per part: edit

For each part id mapped to the law (`parts` in `pending.json`):

1. Read `Projects/App/Resources/Content/parts/<id>.txt`. Use the `검토할 파트` hits as starting points, but also scan for the topic itself — hits only catch old wording that survived verbatim.
2. Edit to match the law in force **on the exam date** (a `시행예정` version counts if it takes effect on/before that date; otherwise leave the current rule and mention it in the summary).
3. Match the existing style exactly:
   - Numbering hierarchy `(1)` → `1)` → `a)` → `-`, with `⇒` for conclusions; plain text, no markdown.
   - Terse noun-ending phrases (`~할 것`, `~함`, `~ 가능`), same indentation and spacing as neighbouring lines.
   - Change only what the law changed; don't rephrase or "improve" untouched lines. Remove content for deleted provisions; add new provisions only when exam-relevant, placed where they belong in the outline.
4. Never create, delete, or renumber parts and never touch `subjects/*.json` (ids are synced by id into SwiftData; favorites reference them). If a change genuinely needs a new part, stop and ask.

After each law, show the user the edit: `diff -u "$B/parts/<id>.txt" Projects/App/Resources/Content/parts/<id>.txt`.

## 4. Summary

Write `Laws/SUMMARY.md` (gitignored) and give the user the same in chat, per law:

| 법령 | 시행일 | 주요 개정 | 수정한 파트 | 반영 안 함 (사유) |

Then ask the user to review the edits (`diff -ru "$B" Projects/App/Resources/Content`). **Stop here until the user approves.**

## 5. Package (after approval)

1. Bump the patch of `version` in `Projects/App/Resources/Content/manifest.json` (e.g. `1.2.3` → `1.2.4`). Required: `ContentSyncService` only re-syncs when this version is newer than the one stored on device, so without the bump users never get the edits.
2. Rebuild the zip with the same layout (`Content/` at the root — CI runs `unzip -o Projects/App/Content.zip -d Projects/App/Resources`):
   ```bash
   rm -f Projects/App/Content.zip
   (cd Projects/App/Resources && zip -rqX ../Content.zip Content -x '*.DS_Store')
   unzip -l Projects/App/Content.zip | sed -n 4,6p   # expect Content/...
   ```
3. Encrypt: `git secret hide -m` (re-encrypts changed files only). Stage `Projects/App/Content.zip.secret` (and `.gitsecret/paths/mapping.cfg` if it changed). Never stage plaintext `Content.zip` or `Content/`.
4. Mark the processed laws reviewed:
   ```bash
   python3 Scripts/check_law_updates.py --update --law "<법령명>"   # per processed law
   ```
   `--law` is a substring match (`건축법` also hits `건축법 시행령`) — only run it for names whose every match was processed. Stage `Scripts/law_versions.json`.
5. Build once so the app still loads the content (the `Content` folder reference must be bundled), then commit (`feat(content): 법령 개정 반영 — <laws>`), push, open a PR with the summary table (no diff/content text in the body — the content is private), and open it in the browser. Don't merge; wait for the user's simulator check.

Don't run `Scripts/verify_content.py` — it compares against the legacy xlsx, which is no longer the source of truth once content is edited.
