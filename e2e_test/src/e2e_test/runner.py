"""Runs natural-language test cases through ArtemisClient and turns the result into a verdict."""

from __future__ import annotations

import asyncio
import json
import os
import re
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

from artemis_client import ArtemisClient, JsonTransport, TaskResult, TaskTimeoutError

from e2e_test.device import APP_PACKAGE

REPORTS_DIR = Path(__file__).resolve().parents[2] / "reports"
RUNS_LOG = REPORTS_DIR / "runs.jsonl"

VERDICT_SCHEMA = (
    "Return ONLY a JSON object with exactly these keys: "
    '"verdict" (string, "PASS" if every expected result in the goal was observed on screen, otherwise "FAIL"), '
    '"evidence" (string, one short sentence quoting the on-screen text that proves the verdict), '
    '"failed_step" (string, the first expected result that was NOT observed, or "" when PASS).'
)

GOAL_RULES = (
    "Quy tắc chung: chỉ thao tác bên trong ứng dụng KTX Food Ordering đang mở. "
    "Không đăng nhập Google, không mở trình duyệt, không đổi cấu hình máy chủ. "
    "Nếu một kết quả mong đợi không xuất hiện sau tối đa 2 lần thử thì dừng lại và báo FAIL, "
    "tuyệt đối không tự sửa dữ liệu để test qua."
)


@dataclass
class CaseOutcome:
    case_id: str
    title: str
    category: str
    run_index: int
    profile: str
    passed: bool
    status: str
    verdict: str | None
    evidence: str | None
    failed_step: str | None
    checker_failed: int
    duration_s: float
    task_id: str | None
    error: str | None = None
    started_at: str = field(default_factory=lambda: time.strftime("%Y-%m-%d %H:%M:%S"))

    def summary(self) -> str:
        return (
            f"[{self.case_id} run#{self.run_index}] status={self.status} verdict={self.verdict} "
            f"checker_failed={self.checker_failed} duration={self.duration_s:.0f}s\n"
            f"  evidence: {self.evidence}\n  failed_step: {self.failed_step}\n  error: {self.error}\n"
            f"  trace: {self.task_id}"
        )


def _extract_json_object(text: str) -> dict[str, Any] | None:
    fenced = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    candidates = [fenced.group(1)] if fenced else []
    start, end = text.find("{"), text.rfind("}")
    if start != -1 and end > start:
        candidates.append(text[start : end + 1])
    for candidate in candidates:
        try:
            parsed = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(parsed, dict):
            return parsed
    return None


def parse_verdict(output: Any) -> dict[str, Any]:
    """Find the verdict object in whatever shape the Outputter returned (dict, JSON string, prose)."""
    if isinstance(output, dict):
        if "verdict" in output:
            return output
        for key in ("result", "output", "structured_output", "data"):
            nested = output.get(key)
            if nested is not None:
                found = parse_verdict(nested)
                if found:
                    return found
        return {}
    if isinstance(output, str):
        parsed = _extract_json_object(output)
        if parsed:
            return parse_verdict(parsed)
        match = re.search(r"\bverdict\b\W+(PASS|FAIL)", output, re.IGNORECASE)
        if match:
            return {"verdict": match.group(1).upper(), "evidence": output[:300]}
    return {}


def _checker_failures(raw_checks: Any, output: Any) -> int:
    tests: dict[str, Any] = {}
    if isinstance(raw_checks, dict):
        tests = (raw_checks.get("run_outcome") or {}).get("tests") or {}
    if not tests and isinstance(output, dict):
        tests = output.get("test_summary") or {}
    try:
        return int(tests.get("failed", 0))
    except (TypeError, ValueError):
        return 0


class ArtemisCaseRunner:
    def __init__(self, client: ArtemisClient, device_serial: str) -> None:
        self.client = client
        self.device_serial = device_serial
        self._transport = JsonTransport(client.base_url)
        self.profile = os.environ.get("E2E_PROFILE", "flash").strip().lower()
        self.timeout_s = float(os.environ.get("E2E_TASK_TIMEOUT", "900"))

    def run_case(
        self,
        *,
        case_id: str,
        title: str,
        category: str,
        goal: str,
        run_index: int,
    ) -> CaseOutcome:
        started = time.monotonic()
        task_id, result, raw_checks, error = asyncio.run(self._execute(goal))

        output = result.output if result else None
        verdict = parse_verdict(output)
        checker_failed = _checker_failures(raw_checks, output)
        verdict_value = str(verdict.get("verdict", "")).upper() or None
        passed = bool(
            result is not None
            and result.succeeded
            and verdict_value == "PASS"
            and checker_failed == 0
        )
        outcome = CaseOutcome(
            case_id=case_id,
            title=title,
            category=category,
            run_index=run_index,
            profile=self.profile,
            passed=passed,
            status=result.status if result else "error",
            verdict=verdict_value,
            evidence=verdict.get("evidence"),
            failed_step=verdict.get("failed_step"),
            checker_failed=checker_failed,
            duration_s=time.monotonic() - started,
            task_id=task_id,
            error=error or (result.error if result else None),
        )
        _append_run_log(outcome)
        return outcome

    async def _execute(
        self, goal: str
    ) -> tuple[str | None, TaskResult | None, Any, str | None]:
        options: dict[str, Any] = {}
        if self.profile == "pro":
            options = {"verification_level": "final", "explorer_mode": "pro"}
        task_id: str | None = None
        try:
            handle = await self.client.submit(
                f"{goal.strip()}\n\n{GOAL_RULES}",
                profile=self.profile,  # type: ignore[arg-type]
                device_serial=self.device_serial,
                locked_app_package=APP_PACKAGE,
                expected_output=VERDICT_SCHEMA,
                enable_outputter=True,
                **options,
            )
            task_id = handle.task_id
            result = await self.client.wait_for_task(
                task_id, timeout=self.timeout_s, poll_interval=3.0
            )
        except TaskTimeoutError as exc:
            # A stuck task keeps the device locked for the next test, so cancel it explicitly.
            if task_id:
                await self.client.stop(task_id)
            return task_id, None, None, f"timeout: {exc}"
        except Exception as exc:  # noqa: BLE001 - every infrastructure error must be recorded, not hidden
            return task_id, None, None, f"{type(exc).__name__}: {exc}"
        return task_id, result, await self._checks(task_id), None

    async def _checks(self, task_id: str) -> Any:
        try:
            return await asyncio.to_thread(
                self._transport.request, "GET", f"/api/sessions/{task_id}/checks"
            )
        except Exception:  # noqa: BLE001 - checks only exist for Pro runs
            return None


def _append_run_log(outcome: CaseOutcome) -> None:
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    with RUNS_LOG.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(asdict(outcome), ensure_ascii=False) + "\n")
