# Bảng tỷ lệ vượt qua (Pass rate) & Báo cáo test case chập chờn (Flaky)

Phạm vi: 15 test case E2E trong `e2e_test/tests/`, chạy bằng Google ARTEMIS trên Android emulator. Mỗi test case chạy **3 lần**.

## 1. Tóm tắt kết quả

> Số liệu chạy thật ngày **09/11/2026 (22:09 – 23:48)**, lấy **3 lần chạy gần nhất** của mỗi TC
> (`uv run e2e-report --last 3`, bản sinh tự động: `reports/pass_rate.md`, dữ liệu gốc: `reports/runs.jsonl`).

| Chỉ số | Giá trị |
| :--- | :--- |
| Tổng số lần chạy hợp lệ | **45** (15 TC × 3 lần) |
| Pass | **41/45 (91%)** |
| TC ổn định (3/3) | **12** |
| TC flaky (1–2/3) | **3**: TC08, TC11, TC14 |
| TC lỗi (0/3) | **0** |
| Lỗi app phát hiện được | **0**: cả 4 lần fail đều do thời gian quan sát của agent hoặc goal cũ không khớp dữ liệu backend (mục 4) |

## 2. Môi trường & quy trình

| Thành phần | Giá trị |
| :--- | :--- |
| Thiết bị | Emulator `emulator-5554`, Android 14 (API 34), 1080×2400, tắt animation |
| App | Debug APK `com.example.prm393_lab03_se192947`, backend thật (Spring Boot qua Cloudflare tunnel) |
| Artemis | Profile **Flash**, daemon `http://127.0.0.1:8000` |
| LLM | `gemini-3.5-flash-lite` (dự phòng `gemini-3.1-flash-lite`), cấu hình `artemis.gemini.jsonc` |

```powershell
uv run pytest --repeat 3          # 15 TC x 3 lần, ghi reports/runs.jsonl
uv run e2e-report --last 3        # sinh reports/pass_rate.md
```

Quy tắc chấm (`src/e2e_test/runner.py`): một lần chạy **PASS** khi task `completed` **và** verdict = `PASS` **và** Checker không có assertion fail.
Ở profile Flash, verdict lấy từ JSON của Outputter, hoặc từ bước `report_task_status` cuối cùng của agent nếu không có JSON.

Quy tắc phân loại (`src/e2e_test/report.py`, hàm `classify`):

| Kết quả N lần | Đánh giá |
| :---: | :--- |
| N/N pass | **Ổn định** |
| 1 … N−1 pass | **Flaky** |
| 0/N pass | **Lỗi (fail ổn định)**, nghĩa là lỗi app hoặc goal sai, không phải flaky |

## 3. Bảng tỷ lệ vượt qua

### 3.1. Profile Flash

Ký hiệu: ✅ pass, ❌ fail. Thứ tự lần 1 → 3 theo thời gian chạy.

| Mã TC | Nhóm | Test case | Lần 1 | Lần 2 | Lần 3 | Pass / Tổng | Pass rate | Thời gian TB | Đánh giá |
| :--- | :--- | :--- | :-: | :-: | :-: | :-: | :-: | :-: | :--- |
| TC01 | Luồng chính | Đăng nhập bằng tài khoản mẫu Sinh viên | ✅ | ✅ | ✅ | 3/3 | 100% | 38s | Ổn định |
| TC02 | Luồng chính | Thêm 1 phần món đầu tiên vào giỏ, thanh giỏ hàng nổi cập nhật | ✅ | ✅ | ✅ | 3/3 | 100% | 45s | Ổn định |
| TC03 | Luồng chính | Tùy biến món (lựa chọn thứ 2, SL 2) rồi thêm vào giỏ | ✅ | ✅ | ✅ | 3/3 | 100% | 81s | Ổn định |
| TC04 | Luồng chính | Tăng số lượng món trong giỏ, thành tiền cập nhật đúng | ✅ | ✅ | ✅ | 3/3 | 100% | 43s | Ổn định |
| TC05 | Luồng chính | Đặt đơn gom KTX bằng COD | ✅ | ✅ | ✅ | 3/3 | 100% | 105s | Ổn định |
| TC06 | Luồng chính | Đăng xuất về màn hình đăng nhập | ✅ | ✅ | ✅ | 3/3 | 100% | 55s | Ổn định |
| TC07 | Luồng lỗi | Đăng nhập bỏ trống email | ✅ | ✅ | ✅ | 3/3 | 100% | 76s | Ổn định |
| TC08 | Luồng lỗi | Đăng nhập bỏ trống mật khẩu | ❌ | ✅ | ✅ | 2/3 | 67% | 101s | **Flaky** |
| TC09 | Luồng lỗi | Đăng ký sinh viên thiếu họ tên | ✅ | ✅ | ✅ | 3/3 | 100% | 41s | Ổn định |
| TC10 | Luồng lỗi | Giỏ trống + nút "Khám phá thực đơn ngay" | ✅ | ✅ | ✅ | 3/3 | 100% | 35s | Ổn định |
| TC11 | Luồng lỗi | Bỏ chọn tất cả rồi bấm Thanh toán | ✅ | ✅ | ❌ | 2/3 | 67% | 82s | **Flaky** |
| TC12 | Tương tác hệ thống | Hộp thoại quyền thông báo (Android 13+) | ✅ | ✅ | ✅ | 3/3 | 100% | 38s | Ổn định |
| TC13 | Tương tác hệ thống | Nút Back hệ thống từ "Quên mật khẩu?" | ✅ | ✅ | ✅ | 3/3 | 100% | 26s | Ổn định |
| TC14 | Tương tác hệ thống | HOME rồi mở lại vẫn giữ phiên và giỏ | ✅ | ❌ | ❌ | 1/3 | 33% | 99s | **Flaky** |
| TC15 | Tương tác hệ thống | Cold start khôi phục phiên đã lưu | ✅ | ✅ | ✅ | 3/3 | 100% | 26s | Ổn định |
| **Tổng** | | | | | | **41/45** | **91%** | | |

### 3.2. Tổng hợp theo nhóm

| Nhóm | Số TC | Pass / Tổng lần chạy | Pass rate | Số TC ổn định | Số TC flaky | Số TC lỗi |
| :--- | :-: | :-: | :-: | :-: | :-: | :-: |
| Luồng chính | 6 | 18/18 | 100% | 6 | 0 | 0 |
| Luồng lỗi | 5 | 13/15 | 87% | 3 | 2 (TC08, TC11) | 0 |
| Tương tác hệ thống | 4 | 10/12 | 83% | 3 | 1 (TC14) | 0 |
| **Toàn bộ** | **15** | **41/45** | **91%** | **12** | **3** | **0** |

### 3.3. Chi tiết các lần chạy thất bại (trong 45 lần hợp lệ)

| TC | Lần | Thời điểm | Trace (`task_id`) | Ảnh | Bước fail theo agent |
| :--- | :-: | :--- | :--- | :--- | :--- |
| TC08 | 1 | 23:04:38 | `f6e83885-ae25-414e-b3ea-32735e807804` | `reports/screens/TC08_run1.png` | Đã nhập email, để trống mật khẩu, bấm "Đăng nhập ngay"; app vẫn ở màn đăng nhập nhưng **không thấy** snackbar "Vui lòng nhập Mật khẩu" |
| TC11 | 3 | 23:36:52 | `e3bfdedf-b204-4f4d-8860-70fc50b6307e` | `reports/screens/TC11_run3.png` | Mọi món đều yêu cầu "Tùy biến", không thêm được món nào **không cần tùy biến** nên dừng ở bước 1 |
| TC14 | 2 | 23:45:19 | `c20a0302-78f2-490c-9814-5a8df811b175` | `reports/screens/TC14_run2.png` | Không thêm được món không tùy biến, giỏ vẫn trống, bước 1 không hoàn thành |
| TC14 | 3 | 23:46:41 | `c32f3c27-de96-43a0-a0ff-a7e3e21d4986` | `reports/screens/TC14_run3.png` | Như lần 2: mọi món đều yêu cầu tùy biến, không có thanh giỏ hàng nổi "1 món" |

### 3.4. Các lần chạy bị loại do lỗi hạ tầng (không tính vào bảng 3.1)

Những lần này fail **trước khi agent thao tác** (không có verdict) và đã được chạy lại. Tách riêng để pass rate phản ánh app, không phản ánh LLM.

| Thời điểm | TC (số lần) | Lỗi | Nguyên nhân | Xử lý |
| :--- | :--- | :--- | :--- | :--- |
| 22:22 – 22:38 | TC09 (3), TC10 (2) | `LLM call timed out after 180 seconds` | Gemini quá tải, lượt gọi đầu tiên vượt giới hạn 180 s | Chạy lại lúc 23:10 – 23:14: TC09 3/3, TC10 3/3 |
| 23:22 – 23:31 | TC11 (5), TC12 (5), TC13 (3), TC14 (2) | `401 UNAUTHENTICATED – The bound service account is deleted or disabled` | API key Gemini bị vô hiệu hoá giữa chừng | Đổi key mới, chạy lại từ 23:33: TC12 3/3, TC13 3/3; TC11, TC14 xem bảng 3.1 |

Tổng cộng **20 lần** bị loại. Trước ngày 09/11 còn có các lần fail do OpenRouter `:free` hết hạn mức (429) và do `gemini-3.8-flash` quá tải (503/504), cùng loại hạ tầng.

## 4. Báo cáo test case chập chờn (Flaky)

### 4.1. Cách xác định nguyên nhân một case flaky

1. Lọc các dòng của case trong `reports/runs.jsonl` và so sánh `failed_step` giữa các lần fail.
   - **Cùng một bước** fail lặp lại: nhiều khả năng là lỗi app hoặc goal mô tả sai. Case thuộc loại "Lỗi", không phải flaky.
   - **Bước khác nhau** hoặc lúc pass lúc fail: do thời gian chờ, agent hoặc môi trường. Đây là flaky thật.
2. Xem trường `error`:
   - `timeout`, `401`, `402`, `429`, `503/504`, `llm_paused` hoặc lỗi kết nối: lỗi **hạ tầng** (LLM/daemon), không tính là lỗi app.
3. Mở ảnh fail và trace theo `task_id` (log ở `%LOCALAPPDATA%\Artemis\traces\<task_id>\stdout.log`) để xem agent đã làm gì ở từng lượt.
4. Phân loại theo bảng 4.3, áp dụng cách khắc phục, rồi chạy lại case đó thêm 5 lần để xác nhận.

### 4.2. Kết luận flaky theo số liệu thật

| Mã TC | Pass rate | Bước fail (`failed_step`) | Nguyên nhân (mã F#) | Phân tích | Cách khắc phục đề xuất | Trạng thái |
| :--- | :-: | :--- | :--- | :--- | :--- | :--- |
| TC08 | 2/3 (cả ngày: 5/6) | Không thấy snackbar "Vui lòng nhập Mật khẩu" | **F1** | Trace: agent bấm "Đăng nhập ngay" ở lượt 7, đến lượt 8 mới chụp màn hình. Snackbar dùng thời lượng mặc định **4 s** (`lib/main.dart`) và đã tắt trước khi agent quan sát; ảnh fail không còn snackbar. App vẫn đúng: không đăng nhập được, vẫn ở màn đăng nhập. Lỗi do **thời gian quan sát**, không phải lỗi app | Chạy TC08 bằng profile Pro, hoặc (nếu được sửa app) tăng `duration` snackbar lỗi lên 6–8 s | Chưa áp dụng |
| TC11 | 2/3 (từ 23:19: 3/4) | Không thêm được món "không cần tùy biến" ở bước 1 | **F4** | Goal TC11 vẫn là bản cũ: *"món đầu tiên không cần tùy biến"* (nút "+"). Backend hiện **không có** món nào như vậy (5/5 món đều có nhóm tùy chọn). Lần pass là khi agent linh hoạt dùng "Tùy biến"; lần fail là khi agent tuân thủ đúng câu chữ. Đây là **goal không khớp dữ liệu**, cùng lỗi TC02 đã sửa | Viết lại bước 1 giống TC02/TC04/TC05: "món đầu tiên; nút + nếu có, nếu không thì Tùy biến giữ lựa chọn mặc định, SL 1" | Chưa áp dụng |
| TC14 | 1/3 | Không thêm được món không tùy biến, giỏ trống | **F4** | Cùng nguyên nhân với TC11 (bước 1 của TC14 cũng là bản cũ). Phần cần kiểm thử thật (HOME → mở lại giữ phiên/giỏ) chưa được thực hiện ở 2 lần fail; lần pass cho thấy chức năng này hoạt động | Như TC11 | Chưa áp dụng |

Sau khi sửa goal TC11 và TC14, chạy lại để xác nhận:

```powershell
uv run pytest -k "tc08 or tc11 or tc14" --repeat 5
uv run e2e-report --last 5
```

### 4.3. Nguy cơ flaky đã nhận diện & cách khắc phục

Cột "Quan sát 09/11" ghi lại nguy cơ nào thực sự xảy ra trong đợt chạy.

| # | Nguy cơ | TC bị ảnh hưởng | Nguyên nhân gốc | Đã áp dụng | Quan sát 09/11 | Đề xuất thêm |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| F1 | Snackbar biến mất trước khi agent quan sát | TC07, TC08 (4 s), TC11 (2 s) | Agent mất vài giây suy luận giữa lúc bấm và lúc chụp màn hình tiếp theo | Goal ghi "quan sát NGAY", trích nguyên văn nội dung snackbar | **Xảy ra 1 lần** (TC08 lần 1). TC07 3/3 | Profile Pro cho các case snackbar; tăng `duration` snackbar lỗi |
| F2 | Backend chậm hoặc lỗi | TC01–TC05, TC11, TC12, TC14 | App gọi API thật cho đăng nhập, thực đơn, tùy chọn món, tạo đơn | Goal cho chờ tối đa 20 s; TC05 báo FAIL kèm lý do cụ thể | Không xảy ra. TC05 tạo đơn thật 3/3 | Kiểm tra backend sống trong preflight |
| F3 | Nút chỉ có icon, không có nhãn / nhãn trùng | TC02–TC05, TC11, TC14 | Agent phải đoán theo hình | Gắn Semantics `identifier` + `label` | Không xảy ra | Bổ sung nhãn cho widget mới |
| F4 | Dữ liệu thực đơn thay đổi theo backend | TC02–TC05, TC11, TC14 | Tên món, giá, nhóm tùy chọn lấy từ database; hiện **mọi món đều có tùy chọn** | TC02, TC04, TC05 đã viết lại: "món đầu tiên", thêm bằng "+" hoặc "Tùy biến" giữ mặc định | **Xảy ra 3 lần** (TC11 lần 3, TC14 lần 2–3): 2 TC này còn goal cũ | Áp dụng cách viết của TC02 cho TC11, TC14 |
| F5 | Không có món nào có tùy chọn | TC03 | Quán đầu tiên có thể không có món có `customizationOptions` | Goal báo FAIL rõ "không có món có tùy chọn" | Không xảy ra. TC03 3/3 | – |
| F6 | Trạng thái rò rỉ giữa các lần chạy | Tất cả | Phiên, giỏ hàng, quyền còn lại từ lần trước | `pm clear` + seed phiên + cấp/thu hồi quyền trước **mỗi** lần chạy | Không xảy ra | – |
| F7 | Chụp màn hình giữa lúc chuyển cảnh | Tất cả | Animation Android/Flutter | Tắt 3 loại animation hệ thống, giữ màn hình sáng | Không xảy ra | – |
| F8 | Hộp thoại quyền không hiện | TC12 | Android nhớ cờ `user-set/user-fixed` | `pm revoke` + `clear-permission-flags` | Không xảy ra. TC12 3/3 | – |
| F9 | Bàn phím ảo che nút | TC07–TC09 | Ô nhập mở bàn phím, che nút | Goal TC09 nhắc ẩn bàn phím | Không gây fail (TC08 lần 1 agent tự bấm BACK để ẩn bàn phím) | – |
| F10 | Task treo khi LLM lỗi (402/429) | Tất cả | Artemis tạm dừng chờ "resume" tới 900 s | Preflight; runner phát hiện `.artemis_paused` rồi `stop()` task ngay | Không xảy ra trong đợt này | – |
| F11 | Agent tự "sửa" để test qua | Tất cả | LLM có xu hướng cố hoàn thành mục tiêu | `GOAL_RULES`: thử tối đa 2 lần rồi báo FAIL, cấm tự sửa dữ liệu | Không thấy. Ngược lại, agent tuân thủ đúng câu chữ nên lộ ra F4 | – |
| F12 | LLM quá tải hoặc key bị vô hiệu | Tất cả | Gemini 503/504 (vượt 180 s); key bị thu hồi (401) | Dùng `gemini-3.5-flash-lite`; tách lần fail hạ tầng khỏi pass rate (mục 3.4) | **Xảy ra 20 lần**, đã loại và chạy lại | Preflight gọi đúng model của agent; dự phòng nhiều key |

## 5. Liên kết

- Kế hoạch kiểm thử tổng: [`../docs/test-plan.md`](../docs/test-plan.md) mục 4.5–4.6 (tóm tắt của file này).
- Cách chạy chi tiết: [`HUONG_DAN_CHAY_TEST.md`](HUONG_DAN_CHAY_TEST.md).
- Hướng dẫn lên slide: [`HUONG_DAN_LEN_SLIDE_TESTING.md`](HUONG_DAN_LEN_SLIDE_TESTING.md).
