#!/usr/bin/env python3
"""Exam calendar for the law-update tools (reads Scripts/exam.json).

The exam tests the laws in force on the exam date, so:
  - an amendment whose 시행일자 is <= the exam date must be reflected in the content;
  - one taking effect later is carried over to the next exam cycle.

Phases (by days left until the next exam):
  normal           > window_days   weekly check, release on the regular schedule
  window           <= window_days  weekly check, release only in-scope changes
  freeze           <= freeze_days  no content releases except corrections
  needs-next-exam  last exam passed and no later date configured

Usage:
    python3 Scripts/exam_calendar.py [--today YYYYMMDD]
"""

import datetime
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
EXAM_FILE = Path(__file__).resolve().parent / "exam.json"
FALLBACK_FROM = "20241212"  # content baseline before the first configured exam


def _day(value):
    return datetime.datetime.strptime(value, "%Y%m%d").date()


def load():
    data = json.loads(EXAM_FILE.read_text(encoding="utf-8"))
    data["exams"] = sorted(data["exams"], key=lambda e: e["date"])
    return data


def status(today=None):
    """Returns {exam, exam_date, days_left, phase, advice, baseline_from}."""
    data = load()
    today = today or datetime.date.today()
    stamp = today.strftime("%Y%m%d")
    upcoming = [e for e in data["exams"] if e["date"] >= stamp]
    past = [e for e in data["exams"] if e["date"] < stamp]
    baseline_from = (past[-1]["date"] if past else FALLBACK_FROM)

    if not upcoming:
        last = data["exams"][-1] if data["exams"] else None
        return {
            "exam": last, "exam_date": last["date"] if last else None, "days_left": None,
            "phase": "needs-next-exam", "baseline_from": baseline_from,
            "advice": "시험 종료 — 다음 시험일을 Scripts/exam.json 에 추가하고, 콘텐츠 반영 후 --update 로 기준일을 갱신하세요.",
        }

    exam = upcoming[0]
    days_left = (_day(exam["date"]) - today).days
    if days_left <= data["freeze_days"]:
        phase, advice = "freeze", f"배포 동결 (D-{days_left}) — 오류 정정 외 콘텐츠 변경·배포 금지."
    elif days_left <= data["window_days"]:
        phase, advice = "window", f"시험 임박 (D-{days_left}) — 주 1회 확인, 시험일 이전 시행분만 반영·배포."
    else:
        phase, advice = "normal", f"평시 (D-{days_left}) — 주 1회 개정 확인, 정기 배포 일정에 맞춰 반영."
    # The diff baseline is the previous exam date (content already reflects it).
    prev = [e for e in data["exams"] if e["date"] < exam["date"]]
    return {
        "exam": exam, "exam_date": exam["date"], "days_left": days_left, "phase": phase,
        "advice": advice, "baseline_from": prev[-1]["date"] if prev else FALLBACK_FROM,
    }


def in_scope(effective_date, exam_date):
    """True when a version taking effect on `effective_date` is tested on `exam_date`."""
    return exam_date is None or effective_date <= exam_date


if __name__ == "__main__":
    today = None
    if "--today" in sys.argv:
        today = _day(sys.argv[sys.argv.index("--today") + 1])
    s = status(today)
    print(json.dumps(s, ensure_ascii=False, indent=2))
