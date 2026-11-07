"""Builds the pass-rate table (Markdown) from reports/runs.jsonl."""

from __future__ import annotations

import argparse
import json
from collections import OrderedDict
from pathlib import Path

from e2e_test.runner import REPORTS_DIR, RUNS_LOG


def load_runs(path: Path, profile: str | None) -> list[dict]:
    if not path.exists():
        return []
    runs = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        record = json.loads(line)
        if profile and record.get("profile") != profile:
            continue
        runs.append(record)
    return runs


def classify(passed: int, total: int) -> str:
    if total == 0:
        return "-"
    if passed == total:
        return "Ổn định"
    if passed == 0:
        return "Lỗi (fail ổn định)"
    return "Flaky"


def build_table(runs: list[dict], last_n: int) -> str:
    grouped: "OrderedDict[str, list[dict]]" = OrderedDict()
    for record in sorted(runs, key=lambda r: (r["case_id"], r["started_at"])):
        grouped.setdefault(record["case_id"], []).append(record)

    lines = [
        "| Mã TC | Nhóm | Tên test case | Kết quả từng lần | Pass / Tổng | Pass rate | Thời gian TB | Đánh giá |",
        "| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |",
    ]
    total_pass = total_runs = 0
    for case_id, records in grouped.items():
        recent = records[-last_n:] if last_n > 0 else records
        passed = sum(1 for r in recent if r["passed"])
        total = len(recent)
        total_pass += passed
        total_runs += total
        marks = " ".join("✅" if r["passed"] else "❌" for r in recent)
        avg = sum(r["duration_s"] for r in recent) / total
        lines.append(
            f"| {case_id} | {recent[-1]['category']} | {recent[-1]['title']} | {marks} | "
            f"{passed}/{total} | {passed / total:.0%} | {avg:.0f}s | {classify(passed, total)} |"
        )
    if total_runs:
        lines.append(
            f"| **Tổng** | | | | **{total_pass}/{total_runs}** | **{total_pass / total_runs:.0%}** | | |"
        )
    return "\n".join(lines)


def build_failures(runs: list[dict], last_n: int) -> str:
    rows = []
    per_case: dict[str, list[dict]] = {}
    for record in sorted(runs, key=lambda r: (r["case_id"], r["started_at"])):
        per_case.setdefault(record["case_id"], []).append(record)
    for case_id, records in per_case.items():
        for record in records[-last_n:] if last_n > 0 else records:
            if record["passed"]:
                continue
            reason = record.get("failed_step") or record.get("error") or record.get("evidence") or ""
            rows.append(
                f"- **{case_id} run#{record['run_index']}** (status `{record['status']}`, "
                f"verdict `{record.get('verdict')}`, trace `{record.get('task_id')}`): {reason}"
            )
    return "\n".join(rows) if rows else "_Không có lần chạy thất bại._"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", default=None, help="Lọc theo profile (flash/pro).")
    parser.add_argument("--last", type=int, default=3, help="Chỉ lấy N lần chạy gần nhất mỗi TC (0 = tất cả).")
    parser.add_argument("--out", default=str(REPORTS_DIR / "pass_rate.md"))
    args = parser.parse_args()

    runs = load_runs(RUNS_LOG, args.profile)
    content = (
        "## Bảng tỷ lệ vượt qua (Pass rate)\n\n"
        + build_table(runs, args.last)
        + "\n\n## Chi tiết các lần chạy thất bại\n\n"
        + build_failures(runs, args.last)
        + "\n"
    )
    Path(args.out).parent.mkdir(parents=True, exist_ok=True)
    Path(args.out).write_text(content, encoding="utf-8")
    print(content)
