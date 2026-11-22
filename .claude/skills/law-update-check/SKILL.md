---
name: law-update-check
description: Check whether the laws behind the 공인중개사 study content (민법, 공인중개사법, 공법, 공시법, 세법 …) were amended, and download the changed versions (신구법 비교, 제개정이유, full text) to Laws/. Use when asked "법령 개정 확인", "check law updates", "download laws", or before updating content for a new exam year. Follow with the law-content-update skill.
argument-hint: "[--since YYYYMMDD] [--law 법령명]"
---

# Law update check

Runs `Scripts/check_law_updates.py` against the 국가법령정보 Open API and saves every changed law version under the gitignored `Laws/` folder so `law-content-update` can summarize it and edit the content.

## 1. Preflight

- **Key**: `Scripts/.env` must contain `LAW_API_OC=...` (or `$LAW_API_OC` exported). If missing, ask the user for their OC and write it there — never into a tracked file. `Scripts/.env` is gitignored; confirm with `git check-ignore Scripts/.env`.
- **Content**: `Projects/App/Resources/Content/` must exist for the part search. If absent: `git secret reveal` (asks for the GPG passphrase — let the user run it via `! git secret reveal`), then `unzip -o Projects/App/Content.zip -d Projects/App/Resources`.
- **Baseline**: if `Scripts/law_versions.json` exists, the default run reports changes since the last review. If it doesn't, ask the user for a `--since YYYYMMDD` (the date the content was last brought up to date; if unknown, suggest Jan 1 of the previous exam year).

## 2. Run

```bash
python3 Scripts/check_law_updates.py --download [--since YYYYMMDD] [--law 법령명] > /dev/null 2> <scratchpad>/law-check.log
```

- Takes ~2 min for all 43 laws. Send stdout to /dev/null — the report is saved to `Laws/REPORT.md` and can be thousands of lines; don't pull it into context whole.
- `--law` matches by substring (`--law 공인중개사법` = 법률 + 시행령 + 시행규칙).
- **Never pass `--update` here.** It marks laws as reviewed; only `law-content-update` does that, after the content is edited.

If the log shows `사용자 정보 검증에 실패` / IP 등록 message: the API only accepts the IP registered on open.law.go.kr. Get the current IP with `curl -s https://api.ipify.org` and ask the user to register it (open.law.go.kr → 마이페이지 → API 신청 정보), then rerun. Home IPs change; this is the usual cause.

## 3. Report to the user

Read only the summary lines at the top of `Laws/REPORT.md` and `Laws/pending.json`, then tell the user:

- How many laws changed out of how many checked, grouped by subject (tracked-law → subject mapping is in `Scripts/laws.json`; part ids 11–14 부동산학, 15–33 민법, 34–46 중개법, 47–67 공시법/세법, 68–73 공법).
- The exam phase line at the top of the report (from `Scripts/exam.json` via `exam_calendar.py`: normal / window ≤60d / freeze ≤14d / needs-next-exam) and the 반영 대상 vs 이월 counts. The exam uses laws in force on the exam date, so versions taking effect after it are 이월 (next cycle) — don't edit content for them. In `freeze`, only corrections; no content releases. When the exam has passed (`needs-next-exam`), add the next year's date (YYYYMMDD, from the Q-Net 공고) to `Scripts/exam.json` before the next run.
- `pending.json` entries carry `in_scope` per version and an `exam` block; `시행예정` marks versions not yet in force today.
- Where things are: `Laws/REPORT.md` (all diffs + part hits), `Laws/<법령명>/<시행일자>_<MST>.md` (per-version file).
- Next step: run the `law-content-update` skill.

Keep it short — a table of changed laws per subject is enough. `Laws/` is gitignored; nothing to commit from this skill.
