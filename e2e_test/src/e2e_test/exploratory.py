"""Time-boxed exploratory session with the Artemis Pro profile; saves the incident list to reports/."""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import time
from pathlib import Path

from dotenv import load_dotenv

E2E_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(E2E_ROOT / ".env", override=False)

from artemis_client import ArtemisClient, TaskTimeoutError  # noqa: E402

from e2e_test.device import APP_PACKAGE, ROLE_STUDENT, Device, first_connected_serial  # noqa: E402
from e2e_test.runner import REPORTS_DIR  # noqa: E402

CHARTER = """
Bạn là tester khám phá (exploratory tester) cho ứng dụng Android "KTX Food Ordering" (đặt món & gom đơn ký túc xá).
Ứng dụng đang mở sẵn với tài khoản Sinh viên đã đăng nhập.

Charter: Khám phá tự do luồng của Sinh viên trong khoảng {minutes} phút để tìm sự cố. Ưu tiên:
1. Tab "Khám phá": tìm kiếm quán (thử chuỗi rỗng, ký tự đặc biệt, chuỗi rất dài), lọc khu vực, các banner/thẻ quán.
2. Tab "Đặt món": thêm/bớt món, mở "Tùy biến", đổi topping, ghi chú; đối chiếu giá hiển thị với tổng tiền.
3. Tab "Giỏ hàng": tăng/giảm/xóa món, bỏ chọn, "Xóa toàn bộ giỏ hàng", thanh toán VietQR và COD.
4. Tab "Lịch sử" và "Tài khoản": mở chi tiết đơn, khiếu nại (S8), thông báo, các nút demo Firebase.
5. Tương tác hệ thống: nút Back ở mọi màn hình, đưa app xuống nền rồi mở lại.

Coi là SỰ CỐ nếu gặp: app crash/đóng đột ngột, màn hình trắng/đỏ (lỗi Flutter), chữ bị tràn/cắt (overflow),
nút bấm không phản hồi, số liệu/giá tiền mâu thuẫn, điều hướng sai, văn bản lẫn tiếng Anh/placeholder, thông báo lỗi khó hiểu.
Không đăng nhập Google, không mở trình duyệt, không đổi cấu hình máy chủ, không thanh toán thật.
Ghi chú lại từng sự cố ngay khi gặp (màn hình, các bước tái hiện, kết quả thực tế, kết quả mong đợi).
"""

INCIDENT_SCHEMA = (
    "Return ONLY a JSON object: "
    '{"explored_areas": [string], "incidents": [{"id": "EXP-01", "screen": string, "severity": "Cao|Trung bình|Thấp", '
    '"steps": string, "actual": string, "expected": string}], "notes": string}. '
    "Use Vietnamese for all values. Use an empty incidents list if nothing was found."
)


async def run_session(minutes: int, serial: str) -> dict:
    from artemis.runtime.daemon_client import ensure_daemon_running

    ok, base_url = ensure_daemon_running(timeout=120.0, wait_ready=True)
    if not ok or not base_url:
        raise SystemExit("Không khởi động được Artemis daemon.")
    client = ArtemisClient(base_url, device_serial=serial, request_timeout=60.0)

    started = time.monotonic()
    handle = await client.submit(
        CHARTER.format(minutes=minutes),
        profile="pro",
        device_serial=serial,
        locked_app_package=APP_PACKAGE,
        expected_output=INCIDENT_SCHEMA,
        enable_outputter=True,
        verification_level="off",
        explorer_mode="pro",
    )
    print(f"Đã gửi phiên khám phá, trace/session id = {handle.task_id}")
    timed_out = False
    try:
        result = await client.wait_for_task(handle.task_id, timeout=minutes * 60 + 300, poll_interval=10)
    except TaskTimeoutError:
        timed_out = True
        await client.stop(handle.task_id)
        await asyncio.sleep(15)
        result = await client.get_task(handle.task_id)

    return {
        "task_id": handle.task_id,
        "status": result.status,
        "timed_out": timed_out,
        "duration_min": round((time.monotonic() - started) / 60, 1),
        "turns": result.turns,
        "output": result.output,
        "error": result.error,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--minutes", type=int, default=int(os.environ.get("E2E_EXPLORE_MINUTES", "25")))
    args = parser.parse_args()

    serial = os.environ.get("ANDROID_SERIAL") or first_connected_serial()
    device = Device(serial)
    device.prepare_for_testing()
    device.reset_app(logged_in_role=ROLE_STUDENT)
    device.launch_app()

    report = asyncio.run(run_session(args.minutes, serial))
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    out = REPORTS_DIR / f"exploratory_{time.strftime('%Y%m%d_%H%M%S')}.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    print(f"\nĐã lưu báo cáo phiên khám phá: {out}")
