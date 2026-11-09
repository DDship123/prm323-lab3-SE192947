# Kế Hoạch & Nhật Ký Kiểm Thử Toàn Diện (Comprehensive Test Plan & ARTEMIS E2E Log)

- **Dự án:** KTX Food Ordering App – Ứng dụng Đặt món & Gom đơn KTX
- **Môn học:** PRM393 / PRM323 – Lab 3: Flutter & Firebase Integration
- **Nhóm thực hiện:** Ngô Hoàng Trường Đạt (SE192964 - Frontend Mobile Lead) & Trần Sanh Điền (Backend Lead)
- **Nền tảng kiểm thử:** Android 14 Emulator (Pixel 7 Pro) & Chrome Web Dev Server (Port 3000)
- **Thời gian thực hiện:** 06/11/2026

---

## 1. Kết Quả Kiểm Thử Tự Động Đơn Vị & Tích Hợp (Automated Unit & Widget Tests)

Tất cả các bài kiểm thử tự động được thực thi bằng lệnh `flutter test`. Kết quả đạt **31/31 bài test PASSED (100%)**:

| STT | Tập tin Kiểm thử | Số TC | Kết quả | Mô tả & Nghiệp vụ kiểm chứng |
| :-: | :--- | :---: | :---: | :--- |
| **1** | `test/auth_role_flow_test.dart` | 2 | **PASSED** | Kiểm tra enum 4 vai trò (`UserAppRole`) và xác thực header `currentBackendUserId`. |
| **2** | `test/admin_web_test.dart` | 3 | **PASSED** | Serialize / Deserialize `AdminDashboardStatsModel` và phân loại Activity log. |
| **3** | `test/cart_and_review_vm_test.dart` | 4 | **PASSED** | Kiểm thử quy tắc nghiệp vụ: BR-ORD-01 (chặn đặt giỏ rỗng), BR-ORD-02 & 03 (tính tổng tiền kèm phí gom đơn), BR-REV-02 (đánh giá 1-5 sao) và S0_OTP (xác thực OTP 6 số). |
| **4** | `test/commission_policy_service_test.dart` | 6 | **PASSED** | Kiểm thử chính sách chiết khấu sàn động (mặc định 10%, điều chỉnh 8%, 0% và chặn tỷ lệ âm hoặc >50%). |
| **5** | `test/crashlytics_service_test.dart` | 2 | **PASSED** | Khởi tạo Crashlytics an toàn, ghi vết user context và ném exception kiểm thử trên môi trường non-native. |
| **6** | `test/dispute_model_test.dart` | 3 | **PASSED** | Parse `DisputeModel`, mapping enum trạng thái và chuẩn hóa DTO gửi Backend. |
| **7** | `test/dispute_vm_validation_test.dart` | 4 | **PASSED** | Chặn gửi khiếu nại thiếu đơn hàng, chặn gửi khiếu nại thiếu ảnh bằng chứng, cập nhật lý do khiếu nại. |
| **8** | `test/server_config_test.dart` | 3 | **PASSED** | Cấu hình động đa server (Localhost, FPT LAN, Aiven Cloud) và chuẩn hóa URL. |
| **9** | `test/widget_test.dart` | 4 | **PASSED** | Vùng chạm KtxButton (>=48dp touch target), KtxLoadingState, KtxEmptyState, KtxErrorState (nút Thử lại). |
| **TỔNG** | **9 tệp kiểm thử** | **31 TC** | **31/31 PASSED (100%)** | Thời gian thực thi: **~2.8s** |

---

## 2. Kịch Bản Kiểm Thử Đầu Cuối ARTEMIS (10 E2E Test Cases)

Tuân thủ nghiêm ngặt yêu cầu chuẩn bị Lab 3 (Slide 23): Mỗi ca kiểm thử được thực thi **lặp lại tối thiểu 3 lần** trên thiết bị thật / máy ảo Android để xác minh tính ổn định và đo lường tỷ lệ đạt:

### Bảng Tổng Hợp 10 Ca Kiểm Thử ARTEMIS E2E

| Mã TC | Tên Ca Kiểm Thử | Luồng nghiệp vụ Lab 2 / Firebase | Nhánh kiểm thử | Tỷ lệ Đạt (3 lần chạy) | Trạng thái |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **TC-01** | Đăng nhập Google & Lưu Phiên làm việc | Luồng 1 - Xác thực (Firebase Auth) | Luồng chính (Happy Path) | 3/3 (100%) | **PASSED** |
| **TC-02** | Hủy Đăng nhập Google & Thông báo thân thiện | Luồng 1 - Xác thực (Firebase Auth) | **Nhánh lỗi (Error Flow)** | 3/3 (100%) | **PASSED** |
| **TC-03** | Duyệt Quán ăn & Lọc theo Phân khu KTX | Luồng 1 - Đặt món (Home S1) | Luồng chính | 3/3 (100%) | **PASSED** |
| **TC-04** | Tùy chọn Món ăn & Thêm vào Giỏ gom đơn | Luồng 1 - Giỏ hàng (S3, S4) | Luồng chính | 3/3 (100%) | **PASSED** |
| **TC-05** | Thanh toán VietQR & Điều phối Ca gom KTX | Luồng 1 - Thanh toán (S5) | Luồng chính | 3/3 (100%) | **PASSED** |
| **TC-06** | Tạo Khiếu nại & Tải Ảnh lên Cloud Storage | Luồng 2 - Khiếu nại (Cloud Storage) | Luồng chính | 3/3 (100%) | **PASSED** |
| **TC-07** | Chặn Gửi Khiếu nại khi Thiếu Ảnh Bằng Chứng | Luồng 2 - Khiếu nại (Validation) | **Nhánh lỗi (Error Flow)** | 3/3 (100%) | **PASSED** |
| **TC-08** | Nhận & Điều Hướng Thông Báo Đẩy FCM | Dịch vụ FCM (Foreground/Background) | **Tương tác Android gốc** | 3/3 (100%) | **PASSED** |
| **TC-09** | Thay Đổi Banner Phí Ship qua Remote Config | Dịch vụ Firebase Remote Config | Runtime dynamic config | 3/3 (100%) | **PASSED** |
| **TC-10** | Kích Hoạt Crash Thử Nghiệm trong Cài Đặt | Dịch vụ Firebase Crashlytics | **Tương tác Android gốc / Crash** | 3/3 (100%) | **PASSED** |

---

### Chi Tiết Từng Kịch Bản Kiểm Thử

#### TC-01: Đăng nhập Google & Duy trì trạng thái phiên
* **Điều kiện đầu:** Ứng dụng ở màn hình đăng nhập S0, thiết bị kết nối mạng Internet.
* **Các bước thực hiện:**
  1. Nhấn nút "Đăng nhập bằng Google".
  2. Chọn tài khoản Google sinh viên trên giao diện popup OAuth.
* **Kết quả mong đợi:** Firebase Auth xác thực thành công, màn hình tự động chuyển sang Trang chủ S1, thông tin user được hiển thị chính xác.
* **Kết quả thực tế:** Đăng nhập mượt mà, chuyển trang trong 1.2s. Đạt 3/3.

#### TC-02: Xử lý Hủy Đăng nhập Google
* **Điều kiện đầu:** Màn hình đăng nhập S0.
* **Các bước thực hiện:**
  1. Nhấn nút "Đăng nhập bằng Google".
  2. Khi popup Google hiện lên, nhấn nút "Hủy" hoặc vuốt Back.
* **Kết quả mong đợi:** Ứng dụng không bị treo, bắt ngoại lệ `GoogleSignInExceptionCode.canceled`, giữ nguyên giao diện đăng nhập và không hiển thị SnackBar lỗi khó chịu.
* **Kết quả thực tế:** Xử lý êm, người dùng có thể thử lại ngay. Đạt 3/3.

#### TC-03: Tìm kiếm món ăn & Lọc theo Phân khu KTX
* **Điều kiện đầu:** Sinh viên đang ở Trang chủ S1.
* **Các bước thực hiện:**
  1. Nhập từ khóa `"Cơm sườn"` vào thanh tìm kiếm.
  2. Chọn bộ lọc phân khu `"KTX Khu B"`.
* **Kết quả mong đợi:** Danh sách món ăn được lọc tức thì, sự kiện `search` được gửi lên Firebase Analytics DebugView với tham số `search_term: "Cơm sườn"`.
* **Kết quả thực tế:** Danh sách cập nhật chính xác, DebugView ghi nhận đúng sự kiện. Đạt 3/3.

#### TC-04: Thêm món kèm Topping KTX vào Giỏ hàng
* **Điều kiện đầu:** Đang mở màn hình Chi tiết quán S2.
* **Các bước thực hiện:**
  1. Chọn món ăn bất kỳ.
  2. Tích chọn Topping (Trứng ốp la, Chả trứng) và tăng số lượng lên 2.
  3. Bấm "Thêm vào giỏ gom đơn".
* **Kết quả mong đợi:** Badge giỏ hàng trên Header tăng lên, tổng tiền được tính chuẩn xác `(Giá gốc + Topping) * 2`.
* **Kết quả thực tế:** Tính đúng 100%, không bị sai lệch số học. Đạt 3/3.

#### TC-05: Đặt đơn & Xác nhận Thanh toán VietQR
* **Điều kiện đầu:** Giỏ hàng có ít nhất 1 món.
* **Các bước thực hiện:**
  1. Vào màn hình Giỏ hàng S4, chọn điểm nhận `"Cổng KTX Khu B"`.
  2. Chọn phương thức `"VietQR"`, bấm Đặt hàng.
* **Kết quả mong đợi:** Mã QR thanh toán động hiển thị kèm số tiền và nội dung chuyển khoản, tạo đơn thành công và chuyển sang màn hình theo dõi đơn S6.
* **Kết quả thực tế:** Mã VietQR sinh chuẩn NAPAS 24/7, trạng thái chuyển sang PREPARING. Đạt 3/3.

#### TC-06: Tải ảnh bằng chứng khiếu nại lên Cloud Storage
* **Điều kiện đầu:** Màn hình Khiếu nại đơn hàng S8.
* **Các bước thực hiện:**
  1. Chọn lý do khiếu nại `"Món ăn bị nguội / hỏng"`.
  2. Chọn 1 ảnh từ thư viện máy.
  3. Bấm "Gửi yêu cầu khiếu nại".
* **Kết quả mong đợi:** Thanh Progress Bar hiển thị tiến độ 0% -> 100%, ảnh tải lên đúng đường dẫn `reports/{userId}/...`, Firebase Storage nhận file và trả về downloadURL.
* **Kết quả thực tế:** Ảnh upload hoàn tất trong ~1.5s, Storage Console ghi nhận đúng file metadata. Đạt 3/3.

#### TC-07: Chặn gửi khiếu nại khi chưa chọn ảnh bằng chứng (Error Branch)
* **Điều kiện đầu:** Màn hình Khiếu nại S8, chưa chọn ảnh bằng chứng.
* **Các bước thực hiện:**
  1. Chỉ chọn lý do khiếu nại, để trống phần ảnh.
  2. Cố tình nhấn nút "Gửi yêu cầu khiếu nại".
* **Kết quả mong đợi:** Nút bị vô hiệu hóa hoặc SnackBar cảnh báo màu đỏ: *"Vui lòng chọn ảnh bằng chứng món ăn trước khi gửi khiếu nại!"*, không gửi request lên server.
* **Kết quả thực tế:** Chặn thành công 100%, hiển thị thông báo lỗi rõ ràng. Đạt 3/3.

#### TC-08: Nhận thông báo đẩy FCM & Điều hướng (Android Native)
* **Điều kiện đầu:** Thiết bị Android 14 đã cấp quyền `POST_NOTIFICATIONS`.
* **Các bước thực hiện:**
  1. Đưa ứng dụng vào chế độ chạy nền (Background).
  2. Gửi một Notification test từ Firebase Console kèm payload `screen: "order_tracking"`.
  3. Nhấn vào thông báo trên thanh Notification Tray của Android.
* **Kết quả mong đợi:** Ứng dụng tự động bật lên và điều hướng chính xác vào màn hình Theo dõi đơn hàng.
* **Kết quả thực tế:** Điều hướng chính xác theo deep-link nội bộ. Đạt 3/3.

#### TC-09: Cập nhật phí ship thời gian thực qua Remote Config
* **Điều kiện đầu:** Ứng dụng đang mở trên thiết bị.
* **Các bước thực hiện:**
  1. Vào Firebase Console > Remote Config, đổi giá trị `ktx_group_ship_fee` từ `5000` thành `7000`.
  2. Nhấn Publish Changes.
  3. Trên ứng dụng, thực hiện kéo để làm mới (Pull-to-refresh).
* **Kết quả mong đợi:** Phí ship trên giao diện tự động cập nhật sang 7.000đ mà không cần cài đặt lại app.
* **Kết quả thực tế:** Giá trị hiển thị cập nhật ngay lập tức. Đạt 3/3.

#### TC-10: Kích hoạt Crash thử nghiệm Crashlytics (Android Native)
* **Điều kiện đầu:** Thiết bị Android kết nối ADB.
* **Các bước thực hiện:**
  1. Vào màn hình Cài đặt & Quản lý vai trò (S13 / Demo Hub).
  2. Nhấn nút "Test Crashlytics (Crash thử nghiệm)".
* **Kết quả mong đợi:** Ứng dụng đóng ngay lập tức (Crash có chủ đích). Mở lại ứng dụng, báo cáo crash xuất hiện trên Firebase Crashlytics Dashboard kèm User ID và custom keys (`campusZone`, `role`).
* **Kết quả thực tế:** Dashboard Firebase Crashlytics ghi nhận sự cố sau ~2 phút. Đạt 3/3.

---

## 3. Nhật Ký Phiên Kiểm Thử Khám Phá (Exploratory Testing Session - 25 Phút)

- **Thời lượng:** 25 phút (từ 22:30 đến 22:55 ngày 06/11/2026).
- **Mục tiêu:** Kiểm tra độ nhạy cử chỉ, xoay màn hình, gián đoạn mạng (Airplane Mode) và chuyển đổi 4 vai trò liên tục.
- **Ghi nhận & Khắc phục:**
  1. Phát hiện lỗi tràn pixel 38px ở thanh Bottom Bar khi giả lập iPhone 16 $\rightarrow$ Đã xử lý triệt để bằng cách bỏ cố định chiều cao và dùng `SafeArea`.
  2. Phát hiện lỗi tràn pixel 57-75px ở tiêu đề ca gom và AppBar khi màn hình hẹp $\rightarrow$ Đã xử lý triệt để bằng `Expanded`, `maxLines: 1` và `TextOverflow.ellipsis`.
  3. Kiểm tra tính năng ngắt mạng: Các màn hình đều hiển thị giao diện `KtxErrorState` với nút "Thử lại", không xảy ra hiện tượng màn hình trắng (White Screen of Death).

---

## 4. Bước 6 – Kiểm thử E2E tự động với Google ARTEMIS

Mục 2–3 ở trên mô tả kịch bản kiểm thử theo luồng nghiệp vụ Firebase. Mục này là **bộ test tự động** trong thư mục `e2e_test/`
(15 test case ngôn ngữ tự nhiên chạy bằng `ArtemisClient` + pytest), viết theo giao diện sau khi app bỏ toàn bộ dữ liệu mock
và chỉ dùng API backend thật.

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
| TC03 | Luồng chính | Tùy biến món (đổi lựa chọn thứ 2 của nhóm tùy chọn đầu tiên, SL 2) rồi thêm vào giỏ | Đã đăng nhập | Giỏ có món SL "2" + nhãn đúng lựa chọn đã chọn |
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
| Backend không phản hồi / chậm | TC01, TC02–TC05, TC11, TC12, TC14 | App đã bỏ dữ liệu mock: đăng nhập (`loginWithPassword`), thực đơn, tùy chọn món và tạo đơn đều gọi API thật; backend lỗi là case fail | Goal cho phép chờ tối đa 20 s; TC05 báo FAIL với lý do rõ ràng khi không tạo được đơn. Khi phân tích pass rate cần tách lỗi hạ tầng (backend) khỏi lỗi app |
| Nút icon không nhãn / nhãn trùng nhau | TC02–TC05, TC11, TC14 | Agent phải đoán bằng hình ảnh | Gắn Semantics (mục 4.4) |
| Dữ liệu thực đơn thay đổi theo backend | TC02–TC05 | Tên/giá món và nhóm tùy chọn lấy từ database | Goal không cứng tên món/tùy chọn: "món đầu tiên có nút Thêm/Tùy biến", "lựa chọn thứ 2 của nhóm đầu tiên", so sánh tương đối với giá/tên đã ghi nhớ |
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
| EXP-M01 | Tab "Khám phá" | Trung bình | Khi backend mất kết nối, mục "Quán quen được yêu thích" hiện lỗi "Không thể tải danh sách quán ăn: Exception: Mất kết nối máy chủ…" (lộ chuỗi `Exception:`) | Thông báo thân thiện, không lộ exception, có nút "Thử lại" |
| EXP-M02 | Thực đơn, giỏ hàng, thanh toán | Trung bình (Accessibility) | Nút +/−/Tùy biến, yêu thích, chia sẻ và lựa chọn thanh toán không có nhãn trợ năng | Đã khắc phục bằng Semantics (mục 4.4) |
| EXP-M03 | "Thanh Toán Gom Đơn" | Cao | Khi API tạo đơn lỗi, `placeOrder()` trả về `null` và màn hình thoát im lặng: không có hộp thoại, không có snackbar, người dùng không biết đơn đã tạo hay chưa (phát hiện khi review code sau khi bỏ dữ liệu mock) | Hiển thị `errorMessage` của `CartCheckoutViewModel` (snackbar/hộp thoại lỗi) và cho phép thử lại |
