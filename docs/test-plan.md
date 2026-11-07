# Kế hoạch & Kết quả Kiểm thử (Test Plan & Execution Report)

- **Dự án:** Food Ordering App – Ứng dụng Đặt món & Gom đơn KTX
- **Môn học:** PRM393 / PRM323 – Lab 3
- **Thực hiện:** Ngô Hoàng Trường Đạt - SE192964 (Frontend Mobile) & Trần Sanh Điền (Backend)
- **Ngày kiểm thử:** 03/11/2026

---

## 1. Mục tiêu Kiểm thử
Xác minh tính đúng đắn và độ ổn định của phân hệ **Bước 4: Features & Tải file lên Đám mây (Cloud Storage)**, bao gồm:
1. Mô hình dữ liệu và DTO mapping cho phân hệ Khiếu nại (Dispute).
2. Ràng buộc nghiệp vụ bắt buộc phải có ảnh bằng chứng thực tế trước khi gửi khiếu nại.
3. Cơ chế giao tiếp và xử lý lỗi mạng / Cloud Storage.
4. Độ ổn định và vùng chạm tương tác (Accessibility) của các thành phần giao diện Design System.

---

## 2. Kết quả Chạy Test Tự động (Automated Test Execution)

Tất cả các bài test được thực thi thông qua lệnh `flutter test`:

| File Kiểm thử | Số lượng Test Case | Kết quả | Ghi chú |
| :--- | :---: | :---: | :--- |
| `test/dispute_model_test.dart` | 3 | **PASSED (100%)** | Parse JSON, enum DisputeStatus mapping và schema DTO gửi Backend. |
| `test/dispute_vm_validation_test.dart` | 4 | **PASSED (100%)** | Khởi tạo StateInitial, chặn gửi khi thiếu đơn hàng, chặn gửi khi thiếu ảnh, cập nhật lý do khiếu nại. |
| `test/widget_test.dart` | 4 | **PASSED (100%)** | Kiểm thử tương tác KtxButton (touch target 48dp), KtxLoadingState, KtxEmptyState và KtxErrorState (nút Thử lại). |
| **Tổng cộng** | **11** | **11/11 PASSED (100%)** | Thời gian thực thi: ~2.5s |

---

## 3. Danh sách Test Case Chi tiết

### 3.1. DisputeModel & DTO Tests
* `TC-MODEL-01`: Parse DisputeModel từ JSON Backend đầy đủ các trường (id, storeName, status, refundAmount, evidenceImageUrl).
* `TC-MODEL-02`: DisputeStatus.fromCode nhận diện chính xác các mã trạng thái `PENDING`, `APPROVED`, `REJECTED`, `REFUNDED` và fallback về `PENDING`.
* `TC-MODEL-03`: CreateDisputeDto chuyển đổi sang JSON đúng hợp đồng API của Spring Boot.

### 3.2. DisputeViewModel Form & Business Validation Tests
* `TC-VM-01`: Trạng thái ban đầu của ViewModel luôn là `StateInitial`.
* `TC-VM-02`: Từ chối gửi khiếu nại khi chưa chọn đơn hàng (chuyển sang `StateError`).
* `TC-VM-03`: **Ràng buộc bắt buộc ảnh bằng chứng:** Từ chối gửi khiếu nại nếu `selectedImageFile == null` (chuyển sang `StateError`).
* `TC-VM-04`: Lựa chọn lý do khiếu nại cập nhật tức thì `selectedReason` và thông báo cho UI lắng nghe.

### 3.3. Design System Widgets Smoke Tests
* `TC-WIDGET-01`: KtxButton hiển thị đúng nhãn và nhận diện sự kiện tap của người dùng.
* `TC-WIDGET-02`: KtxLoadingState hiển thị đúng nội dung thông báo và con quay tiến trình.
* `TC-WIDGET-03`: KtxEmptyState hiển thị giao diện rỗng và phản hồi khi nhấn nút CTA.
* `TC-WIDGET-04`: KtxErrorState hiển thị lỗi và kích hoạt callback Thử lại (Retry).

---

## 4. Bước 6 – Kiểm thử E2E tự động với Google ARTEMIS

### 4.1. Môi trường

| Thành phần | Giá trị |
| :--- | :--- |
| Framework | Google ARTEMIS (`artemis` 1.0, `artemis_client` 0.1.0), pytest 9.2 |
| Python / công cụ | Python 3.12.16, `uv`, ADB |
| LLM | Gemini (`gemini-3.8-flash`, key đặt trong `e2e_test/.env` – đã gitignore) |
| Thiết bị | Emulator `sdk gphone64 x86_64`, Android 14 (API 34), 1080×2400 |
| Bản app | Debug APK `com.example.prm393_lab03_se192947` |
| Profile | Test case: **Flash** (`E2E_PROFILE=flash`); phiên khám phá: **Pro** (`explorer_mode=pro`) |

Mã nguồn và cách chạy: [`e2e_test/README.md`](../e2e_test/README.md).

### 4.2. Chiến lược

- Mỗi test case là một **goal ngôn ngữ tự nhiên** (tiếng Việt, trích đúng nhãn UI) gồm *Các bước* + *Kết quả mong đợi*, gửi qua `ArtemisClient.submit()` với `locked_app_package` để agent không rời khỏi app.
- **Verdict có cấu trúc:** `expected_output` yêu cầu Outputter trả JSON `{verdict, evidence, failed_step}`. Test PASS khi task `completed` + `verdict == PASS` + Checker (Pro) không có assertion fail.
- **Trạng thái đầu xác định:** trước mỗi lần chạy, fixture `pm clear` app, cấp quyền thông báo, và với các case cần đăng nhập thì **nạp sẵn phiên** (ghi `FlutterSharedPreferences.xml` qua `run-as`) thay vì bắt agent đăng nhập lại → giảm số bước và độ chập chờn. TC01 vẫn kiểm thử đăng nhập qua UI.
- **Ổn định thiết bị:** tắt 3 loại animation, giữ màn hình sáng, mở khoá màn hình.
- **Fail nhanh:** preflight gọi Gemini một lần trước khi chạy; timeout 900 s/case, quá hạn thì `stop()` task để không khoá thiết bị cho case sau. Lúc fail tự chụp màn hình vào `reports/screens/`.

### 4.3. Danh sách test case (15 TC)

| Mã | Nhóm | Test case | Tiền điều kiện | Kết quả mong đợi chính |
| :--- | :--- | :--- | :--- | :--- |
| TC01 | Luồng chính | Đăng nhập bằng tài khoản mẫu Sinh viên | Chưa đăng nhập | Vào màn hình chính, đủ 5 tab |
| TC02 | Luồng chính | Thêm món không tùy biến, thanh giỏ hàng nổi cập nhật | Đã đăng nhập | Bộ đếm "1", thanh nổi "1 món" + đúng giá |
| TC03 | Luồng chính | Tùy biến món (nước mắm không cay, SL 2) rồi thêm vào giỏ | Đã đăng nhập | Giỏ có món SL "2" + nhãn tùy chọn |
| TC04 | Luồng chính | Tăng số lượng trong giỏ, thành tiền cập nhật | Đã đăng nhập | SL "2", thành tiền = 2 × đơn giá, "Thanh toán (2)" |
| TC05 | Luồng chính | Đặt đơn gom KTX bằng COD | Đã đăng nhập | Hộp thoại "Đặt đơn thành công!" |
| TC06 | Luồng chính | Đăng xuất | Đã đăng nhập | Quay về "Đăng nhập tài khoản" |
| TC07 | Luồng lỗi | Đăng nhập bỏ trống email | Chưa đăng nhập | Snackbar "Vui lòng nhập Email hoặc Số điện thoại" |
| TC08 | Luồng lỗi | Đăng nhập bỏ trống mật khẩu | Chưa đăng nhập | Snackbar "Vui lòng nhập Mật khẩu" |
| TC09 | Luồng lỗi | Đăng ký sinh viên thiếu họ tên | Chưa đăng nhập | Báo lỗi, không sang màn OTP |
| TC10 | Luồng lỗi | Giỏ hàng trống + nút "Khám phá thực đơn ngay" | Đã đăng nhập | Empty state, chuyển sang tab "Đặt món" |
| TC11 | Luồng lỗi | Bỏ chọn tất cả rồi bấm Thanh toán | Đã đăng nhập | Snackbar "Vui lòng tích chọn ít nhất 1 món…" |
| TC12 | Tương tác hệ thống | Hộp thoại quyền POST_NOTIFICATIONS (Android 13+) sau đăng nhập | Chưa đăng nhập, quyền bị thu hồi | Hộp thoại hệ thống xuất hiện, cho phép xong vào app |
| TC13 | Tương tác hệ thống | Nút Back hệ thống từ "Quên mật khẩu?" | Chưa đăng nhập | Về màn đăng nhập, không thoát app |
| TC14 | Tương tác hệ thống | Đưa app xuống nền (HOME) rồi mở lại | Đã đăng nhập | Giữ phiên và giỏ "1 món" |
| TC15 | Tương tác hệ thống | Cold start khôi phục phiên đã lưu | Phiên đã lưu | Vào thẳng app, có nút "Đăng xuất tài khoản" |

### 4.4. Gắn nhãn Semantics cho widget quan trọng

`identifier` được Flutter ánh xạ thành `resource-id` trong cây UI Android (đã xác minh bằng `uiautomator dump` trên emulator), `label` thành `content-desc`.

| Widget / màn hình | identifier | label (content-desc) | Lý do |
| :--- | :--- | :--- | :--- |
| `KtxBottomNavBar` (5 tab) | `nav_tab_0` … `nav_tab_4` | "Tab Khám phá", … + số badge, `selected` | Agent biết tab nào đang chọn |
| `KtxButton` | tham số `semanticsId` | nhãn nút, "(đang xử lý)" khi loading, `enabled` | Phân biệt trạng thái loading |
| Login: ô nhập, nút | `input_login_email`, `input_login_password`, `btn_login_submit`, `btn_login_google` | – | Định vị ổn định |
| Login: chip tài khoản mẫu | `chip_role_student/owner/shipper/admin` | "Tài khoản mẫu Sinh viên"… | Nhãn gốc chứa emoji |
| Thực đơn: nút + / Tùy biến / − | `btn_add_item_<id>`, `btn_customize_item_<id>`, `btn_increase_item_<id>`, `btn_decrease_item_<id>`, `text_qty_item_<id>` | "Thêm <tên món> vào giỏ"… | Trước đây là icon **không nhãn** |
| Thực đơn: yêu thích / chia sẻ / quay lại | `btn_store_favorite` | có `toggled` | Icon không nhãn |
| `KtxFoodItemCard` | `card_food_item` | "Món <tên>" (+ "hết món") | Nhãn cũ `card_food_item` giống nhau ở mọi thẻ |
| `KtxStickyCartBar` | `bar_sticky_cart` | "Giỏ hàng: N món, tổng …" | Đọc số món/tổng tiền trong 1 node |
| Giỏ hàng | `checkbox_cart_item_<i>`, `btn_cart_increase/decrease_<i>`, `text_cart_qty_<i>`, `btn_cart_checkout` | "Tăng số lượng <tên món>"… | Nút +/− là icon không nhãn |
| Tùy biến món | `text_customize_qty`, `btn_customize_add_to_cart` + tooltip các icon | – | |
| Thanh toán | `btn_place_order`, `radio_payment_vietqr`, `radio_payment_cod` (`checked`, nhóm loại trừ) | – | Trạng thái chọn trước đây chỉ thể hiện bằng icon |
| Trang chủ / Hồ sơ | `input_home_search`, `btn_sign_out` | – | |

### 4.5. Bảng tỷ lệ vượt qua (Pass rate)

> **Trạng thái 07/11/2026: CHƯA THỰC THI ĐƯỢC.** Lần chạy thử đầu tiên (TC02) bị Gemini từ chối với
> `402 RESOURCE_EXHAUSTED – "Your prepayment credits are depleted"`; preflight xác nhận lỗi này xảy ra với mọi model
> (`gemini-3.8-flash`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`). Cần nạp credit / bật billing cho project AI Studio
> của key rồi chạy `uv run pytest --repeat 3` và `uv run e2e-report --last 3` để điền bảng dưới (file sinh tự động: `e2e_test/reports/pass_rate.md`).

| Mã TC | Lần 1 | Lần 2 | Lần 3 | Pass rate | Đánh giá |
| :--- | :---: | :---: | :---: | :---: | :--- |
| TC01 – TC15 | – | – | – | – | Chưa chạy |

### 4.6. Test case chập chờn (Flaky): nguyên nhân & cách khắc phục

Phần này cần được cập nhật theo kết quả 3 lần chạy thực tế. Các nguồn chập chờn **đã nhận diện khi thiết kế** và biện pháp đã áp dụng sẵn:

| Nguy cơ | Test case bị ảnh hưởng | Nguyên nhân | Khắc phục đã áp dụng |
| :--- | :--- | :--- | :--- |
| Snackbar biến mất trước khi agent chụp màn hình | TC07, TC08, TC11 (snackbar 2–4 s) | Agent mất vài giây suy luận giữa thao tác và quan sát | Goal nhắc "quan sát NGAY"; đề xuất tăng `duration` snackbar lỗi lên ≥ 4 s trong app |
| Backend Cloudflare tunnel không phản hồi | TC01, TC05, TC12 | Gọi API timeout 6–8 s rồi mới fallback dữ liệu mẫu | Goal cho phép chờ tối đa 20 s; app có fallback nên kết quả không đổi |
| Nút icon không nhãn / nhãn trùng nhau | TC02–TC05, TC11, TC14 | Agent phải đoán bằng hình ảnh | Gắn Semantics (mục 4.4) |
| Dữ liệu thực đơn khác nhau (backend vs fallback) | TC02–TC05 | Tên/giá món phụ thuộc nguồn dữ liệu | Goal không cứng tên món: "món đầu tiên có nút Thêm/Tùy biến", so sánh tương đối với giá đã ghi nhớ |
| Trạng thái rò rỉ giữa các lần chạy | Tất cả | Phiên/giỏ hàng/quyền từ lần trước | `pm clear` + seed phiên + cấp/thu hồi quyền mỗi lần chạy |
| Animation chuyển màn hình | Tất cả | Chụp màn hình giữa lúc chuyển cảnh | Tắt animation hệ thống |
| Hộp thoại quyền hiện chậm/không hiện | TC12 | Quyền đã được cấp từ lần trước | Thu hồi quyền + xoá cờ `user-set/user-fixed` trước khi chạy |
| Task treo khi LLM lỗi (402/429) | Tất cả | Artemis tạm dừng chờ "resume" vô thời hạn | Preflight Gemini + timeout + `stop()` task |

### 4.7. Phiên khám phá tự do (Exploratory Session – Pro profile)

- **Charter:** khám phá luồng Sinh viên 25 phút (tìm kiếm, thực đơn/tùy biến, giỏ hàng, thanh toán, lịch sử, khiếu nại, nút Back, nền/khôi phục). Chạy: `uv run e2e-explore --minutes 25`, kết quả JSON ở `e2e_test/reports/exploratory_*.json`.
- **Trạng thái:** chưa chạy được vì cùng lỗi 402 của Gemini.

Sự cố ghi nhận thủ công trong quá trình chuẩn bị (chưa phải kết quả của phiên Pro):

| Mã | Màn hình | Mức độ | Mô tả | Mong đợi |
| :--- | :--- | :--- | :--- | :--- |
| EXP-M01 | Tab "Khám phá" | Trung bình | Khi backend mất kết nối, mục "Quán quen được yêu thích" hiện lỗi "Không thể tải danh sách quán ăn: Exception: Mất kết nối máy chủ…" (lộ chuỗi `Exception:`), trong khi tab "Đặt món" vẫn dùng dữ liệu dự phòng | Thông báo thân thiện, không lộ exception; hành vi fallback nhất quán giữa các tab |
| EXP-M02 | Thực đơn, giỏ hàng, thanh toán | Trung bình (Accessibility) | Nút +/−/Tùy biến, yêu thích, chia sẻ và lựa chọn thanh toán không có nhãn trợ năng | Đã khắc phục bằng Semantics (mục 4.4) |

