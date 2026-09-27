---
name: law-summary-review
description: Review study-content edits made from law amendments (law-content-update) before they are packaged — checks each edited Content part against the actual law text for accuracy, completeness, leftover old rules, style and scope, and reports findings without editing. Use when asked "요약 검토", "review the law updates", "review part N", or before approving a law-content-update.
argument-hint: "<part id> [more part ids] [--backup Laws/.backup/Content-…]"
---

# Law summary review

An independent check of what `law-content-update` wrote. The reviewer **verifies against the law text, not against the author's reasoning** — ignore any summary or explanation from the editing step and judge only the diff and the law. Read-only: report findings, don't edit (unless the user then asks for fixes).

Best run in a fresh session (or right after `/clear`) so the editing context doesn't bias the review.

## 1. Inputs (per part)

- **Backup**: latest `Laws/.backup/Content-*` unless `--backup` is given: `ls -d Laws/.backup/Content-* | tail -1`.
- **Content diff**: `diff -u "$B/parts/<id>.txt" Projects/App/Resources/Content/parts/<id>.txt`. Empty → nothing to review for this part; say so.
- **Law diff**: `python3 Scripts/law_diff.py diff --part <id> > <scratchpad>/review<id>.diff` (full texts are cached, so this is cheap). Same token rules as law-content-update: don't read `Laws/<법령명>/*.md` or `Laws/REPORT.md`.
- **Exact wording** when a claim needs checking: `python3 Scripts/law_diff.py article "<법령명>" <조> [<조> …]` (exam-date version; `--at 20241212` for the old one). Fetch only the articles you need.
- Read the edited part itself (`cat -n`) once, for context around the hunks.

## 2. Checks

For every `+`/`-` hunk and every change in the law diff:

1. **Accuracy** — each added/changed line is supported by the exam-date law text: numbers (기간·금액·비율·인원·과태료), 주체 (국토교통부 장관 / 시·도지사 / 등록관청), 인가 vs 승인 vs 신고 vs 등록, 의무 (`해야`) vs 재량 (`할 수 있다`), 법 vs 시행령 level. Any unsupported or overstated line is a finding.
2. **Completeness** — each substantive change in the law diff within the part's topic is reflected, or deliberately left out for a stated reason (not exam-relevant, 시행일 after the exam). Missing ones are findings.
3. **Leftovers** — old rules still in the part: grep the part for the old side of the diff (`[-…-]` fragments, deleted articles' key terms), e.g. `grep -n "지부\|설립인가" parts/<id>.txt`. Also flag old wording in untouched lines of the same part.
4. **Unchanged rules intact** — lines the edit removed or reworded whose law provision did *not* change (the edit went beyond the amendment).
5. **Style** — same as neighbouring lines: `(1)` → `1)` → `a)` → `-`, `◎`, `⇒`; terse endings; `.` separators (`시.도지사`); no markdown; no dates/article numbers unless the part already uses them.
6. **Scope** — only `parts/*.txt` changed: `diff -rq "$B" Projects/App/Resources/Content` must list parts only — no `subjects/*.json`, no new/removed files. `manifest.json` changes are expected only after packaging.
7. **Other parts** — terms renamed by the amendment that still appear elsewhere: `grep -rln "<old term>" Projects/App/Resources/Content/parts` → list as follow-ups (not findings for this part).

## 3. Report

Per part, a verdict and a findings table, most severe first:

**Part <id> — <제목>: ✅ approve / ⚠️ approve with fixes / ❌ needs changes**

| # | 심각도 | 줄 | 문제 | 근거 (법령 조문) | 제안 |
|---|---|---|---|---|---|

- 심각도: **오류** (wrong rule/number — a student would learn something false), **누락** (substantive change not reflected), **잔존** (old rule left), **스타일**, **범위**.
- 근거 must quote the article (short) — no finding without a law reference, except style/scope.
- End with follow-up parts (check 7) and one line: ready to package or not.

Keep it tight — no restating the edits that are fine. If the user asks to fix findings, hand back to `law-content-update` step 3 (small `Edit` hunks), then re-run this review on the same part.
