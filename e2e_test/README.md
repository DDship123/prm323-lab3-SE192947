# E2E test – KTX Food Ordering với Google ARTEMIS

Bộ kiểm thử E2E viết bằng ngôn ngữ tự nhiên, chạy qua `ArtemisClient` + pytest trên emulator Android.
Kế hoạch và kết quả chi tiết: [`docs/test-plan.md`](../docs/test-plan.md) (mục 4 trở đi).

## Chuẩn bị

1. Python 3.12+, `uv`, Android SDK (`adb` trong PATH), emulator đang chạy (`adb devices` thấy `device`).
2. Cài bản **debug** của app (cần `run-as` để nạp sẵn phiên đăng nhập):
   `flutter build apk --debug` rồi `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.
3. Tạo `e2e_test/.env` từ `.env.example` và điền `GEMINI_API_KEY` (project AI Studio phải còn credit / bật billing).
4. `cd e2e_test && uv sync`

## Chạy

```powershell
# Toàn bộ 15 test case, mỗi case 3 lần (Flash profile)
uv run pytest --repeat 3

# Theo nhóm
uv run pytest -m main_flow --repeat 3
uv run pytest -m error_flow
uv run pytest -m system

# Bảng pass rate (đọc reports/runs.jsonl, lấy 3 lần gần nhất mỗi TC) -> reports/pass_rate.md
uv run e2e-report --last 3

# Phiên khám phá tự do bằng Pro profile (mặc định 25 phút) -> reports/exploratory_*.json
uv run e2e-explore --minutes 25
```

Daemon Artemis được tự khởi động ở cổng 8000 khi chạy test. Trace từng lần chạy xem bằng `uv run artemis ui`
(mã trace = `task_id` trong `reports/runs.jsonl`). Ảnh màn hình lúc fail nằm ở `reports/screens/`.

## Cấu trúc

| Đường dẫn | Vai trò |
| :--- | :--- |
| `tests/test_main_flows.py` | TC01–TC06: luồng chính |
| `tests/test_error_flows.py` | TC07–TC11: luồng lỗi / validate |
| `tests/test_system_interactions.py` | TC12–TC15: quyền hệ thống, nút Back, nền/khởi động lại |
| `tests/conftest.py` | Preflight Gemini, khởi động daemon, reset app, `--repeat`, chụp màn hình khi fail |
| `src/e2e_test/device.py` | ADB: tắt animation, `pm clear`, cấp/thu hồi quyền, seed phiên đăng nhập |
| `src/e2e_test/runner.py` | Gửi goal qua `ArtemisClient`, phân tích verdict JSON + Checker, ghi `runs.jsonl` |
| `src/e2e_test/report.py` | Sinh bảng pass rate |
| `src/e2e_test/exploratory.py` | Phiên khám phá Pro profile |
| `unit_tests/` | Unit test cho bộ phân tích verdict (`uv run pytest unit_tests`) |

Một test case **PASS** khi đồng thời: task Artemis kết thúc `completed`, Outputter trả `{"verdict": "PASS"}`,
và (với Pro profile) Checker không có assertion nào fail.
