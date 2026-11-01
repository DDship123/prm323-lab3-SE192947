# Ma trận Vết Thiết kế & Ánh xạ Mã nguồn (Design Traceability Matrix)

- **Dự án:** Food Ordering App (Ứng dụng Đặt món & Gom đơn KTX)
- **Mã môn học:** PRM393 - Lab 3 
- **Thành viên nhóm thực hiện:**
  - Bùi Bảo Dương - SE192947
  - Ngô Hoàng Trường Đạt - SE192964
  - Trần Sanh Điền - SE192850
  - Quách Ngọc Vinh - SE194159
- **Liên kết Figma Prototype (Lab 2):** [Figma Prototype](https://www.figma.com/design/ALDYFWUZ72BaeyulpVi7uY/Lab-2-Food-Ordering-App?t=hPq3TpDGOcADKey4-1)

---

## 1. Mục đích & Phạm vi

Tài liệu này đóng vai trò làm bằng chứng theo vết (traceability) cho Stage 1, chứng minh rằng 100% các yêu cầu UI/UX, thông tin màn hình, luồng người dùng và hệ thống component đã thiết kế từ Lab 2 được chuyển giao chính xác sang mã nguồn Flutter (MVVM) và cơ sở dữ liệu Cloud Firestore. 

Mọi điều chỉnh về mặt thiết kế so với bản Figma ban đầu (do ràng buộc kỹ thuật, API hoặc chuẩn truy cập) đều được ghi nhận công khai kèm lý do ở Mục 5 để giữ sự thống nhất giữa Design và Code.

---

## 2. Ma trận Ánh xạ Màn hình

| Mã Màn | Tên Màn hình (Figma) | Route Path (Flutter) | Widget Class (`lib/screens/`) | ViewModel (`lib/viewmodels/`) | Nguồn dữ liệu (Firestore / REST API / SDK) | Trạng thái (Status) |
| :---: | :--- | :--- | :--- | :--- | :--- | :---: |
| **S0** | Đăng nhập & Chọn vai trò | `/login` | `StudentLoginScreen` | `AuthViewModel` | Firebase Auth (Google Sign-In) | `DONE` |
| **S0_Reg** | Đăng ký tài khoản | `/register` | `StudentRegisterScreen` | `AuthViewModel` | Firebase Auth, Firestore `users` | `DONE` |
| **S0_OTP** | Xác thực mã OTP | `/otp-verify` | `OtpVerificationScreen` | `AuthViewModel` | Firebase Auth (Phone/Email) | `DONE` |
| **S1** | Trang chủ & Tìm kiếm | `/home` | `HomeScreen` | `HomeViewModel` | Firestore `stores`, `menu_items`, Remote Config | `DONE` |
| **S2** | Chi tiết Quán & Thực đơn | `/store-detail` | `StoreDetailScreen` | `StoreDetailViewModel` | Firestore `stores/{id}/menus` | `DONE` |
| **S3** | Modal Tùy biến món ăn | *(Bottom Sheet)* | `FoodCustomizationSheet` | `StoreDetailViewModel` | Local Draft Cart State | `DONE` |
| **S4** | Giỏ hàng & Chọn ca gom | `/checkout` | `GroupCartCheckoutScreen` | `CartCheckoutViewModel` | Firestore `orders`, Remote Config | `DONE` |
| **S5** | Thanh toán VietQR / COD | `/payment` | `OnlinePaymentScreen` | `CartCheckoutViewModel` | VietQR Generator Service, Firestore `orders` | `DONE` |
| **S6** | Theo dõi đơn hàng Live | `/order-tracking` | `LiveOrderTrackingScreen` | `OrderTrackingViewModel` | Firestore `orders/{id}` (Snapshots) | `DONE` |
| **S7** | Mã QR Nhận hàng tại cổng | `/pickup-qr` | `PickupQrCodeScreen` | `OrderTrackingViewModel` | Firestore `orders/{id}`, System Brightness API | `DONE` |
| **S8** | Khiếu nại & Hoàn tiền | `/dispute` | `DisputeRefundScreen` | `DisputeViewModel` | Cloud Storage (`reports/{uid}/`), Firestore `disputes` | `DONE` |
| **S8b** | Lịch sử khiếu nại | `/dispute-history` | `DisputeHistoryScreen` | `DisputeViewModel` | Firestore `disputes` | `DONE` |
| **S9** | Đánh giá Quán & Shipper | `/review` | `ReviewFeedbackScreen` | `ReviewViewModel` | Firestore `reviews` | `DONE` |
| **S10** | Lịch sử đơn hàng | `/order-history` | `OrderHistoryScreen` | `OrderTrackingViewModel` | Firestore `orders` (Where `uid == currentUser`) | `DONE` |
| **S12** | Bảng thông báo (FCM) | `/notifications` | `NotificationBoardScreen` | `ProfileDemoViewModel` | Local FCM Message Store, Firestore `notifications` | `DONE` |
| **S13** | Hồ sơ & Firebase Demo Area | `/profile` | `ProfileSettingsScreen` | `ProfileDemoViewModel` | Remote Config, Crashlytics, Cloud Storage | `DONE` |

---

## 3. Ma trận Ánh xạ Luồng Người dùng

### 3.1. Flow 0: Xác thực & Điều hướng Trạng thái 
* **Luồng chính (Happy Path):** `S0 (Sign-In)` $\rightarrow$ Chọn Google Sign-In / Nhập SĐT $\rightarrow$ [Thành công] $\rightarrow$ Mở `S1 (Home)`.
* **Luồng phụ (Alternative Path):** `S0` $\rightarrow$ Chưa có tài khoản $\rightarrow$ `S0_Reg` $\rightarrow$ `S0_OTP` $\rightarrow$ `S1`.
* **Luồng xử lý lỗi (Error Path):** `S0` $\rightarrow$ Bấm hủy Google Sign-In hoặc nhập sai OTP $\rightarrow$ Bắt Exception, hiển thị SnackBar thông báo lỗi trực quan mà không văng app.

### 3.2. Flow 1: Tra cứu, Đặt món & Thanh toán Gom đơn Ca Trưa 
* **Luồng chính (Happy Path):** `S1` (Tra cứu/Lọc khu vực) $\rightarrow$ `S2` (Xem quán & chọn món) $\rightarrow$ `S3` (Chọn size/topping $\rightarrow$ Thêm vào giỏ) $\rightarrow$ Bấm Sticky Cart Bar $\rightarrow$ `S4` (Chọn điểm nhận, chọn ca, áp mã giảm giá, chọn VietQR) $\rightarrow$ `S5` (Quét VietQR & bấm hoàn tất) $\rightarrow$ `S5_OrderSuccessDialog` $\rightarrow$ `S6`.
* **Luồng phụ (Alternative Path):** Tại `S5`, ứng dụng ngân hàng bị lỗi $\rightarrow$ Bấm *"Đổi sang Tiền mặt (COD)"* $\rightarrow$ Quay về `S4` (tự động chọn COD) $\rightarrow$ Bấm *"Xác nhận đặt đơn"* $\rightarrow$ `S5_OrderSuccessDialog` $\rightarrow$ `S6`.
* **Luồng xử lý lỗi (Error Path):** Tìm kiếm từ khóa không tồn tại tại `S1` $\rightarrow$ Hiển thị `KtxEmptyState` (C08); Mở `S4` khi giỏ hàng rỗng $\rightarrow$ Hiển thị `S4_EmptyState`.

### 3.3. Flow 2: Nhận hàng tại Cổng KTX & Gửi Đánh giá 
* **Luồng chính (Happy Path):** Nhận FCM Push Notification *"Shipper đã tới cổng"* $\rightarrow$ Mở `S6` $\rightarrow$ Bấm *"Mở Mã QR Nhận Hàng"* $\rightarrow$ Mở `S7` $\rightarrow$ Bấm *"Tăng độ sáng"* xuất trình mã QR $\rightarrow$ Xác nhận nhận món $\rightarrow$ `S9` (Chấm sao Quán & Shipper) $\rightarrow$ `S1`.
* **Luồng phụ (Alternative Path):** Màn hình bị chói nắng camera không quét được $\rightarrow$ Sinh viên đọc **Mã PIN / 4 số cuối SĐT** hiển thị kích thước lớn trên `S7` để shipper đối soát thủ công.

### 3.4. Flow 3: Báo cáo Sự cố, Khiếu nại & Hoàn tiền 
* **Luồng phục hồi lỗi (Error & Recovery Path):** Từ `S6` hoặc `S10` $\rightarrow$ Bấm *"Báo cáo sự cố"* $\rightarrow$ `S8` (Tích chọn lý do & món hỏng $\rightarrow$ Tự động tính tiền hoàn $\rightarrow$ Tải ảnh thực tế) $\rightarrow$ Bấm *"Gửi khiếu nại"* $\rightarrow$ Mở `S8b` & `S8c` (Theo dõi tiến trình thẩm định).
* **Luồng lỗi ràng buộc (Validation Error Path):** Bấm gửi tại `S8` nhưng chưa tải ảnh thực tế $\rightarrow$ Hiển thị `KtxErrorState` (C09 Inline Banner) yêu cầu đính kèm ảnh bằng chứng.

---

## 4. Ma trận Ánh xạ Thành phần Giao diện

| Mã Cpt | Tên Thành phần (Figma) | Flutter Widget Class (`lib/widgets/`) | Các biến thể & Trạng thái hỗ trợ (Variants & States) | Nhãn Trợ năng (Semantics Label for ARTEMIS) |
| :---: | :--- | :--- | :--- | :--- |
| **C01** | KtxButton | `KtxButton` | Primary, Secondary, Outline, Danger; Default, Pressed, Disabled, Loading. | `Semantics(button: true, label: ...)` |
| **C02** | KtxTextField | `KtxTextField` | Default, Focused (viền cam), Filled, Error (viền đỏ), Disabled. | `Semantics(textField: true, label: ...)` |
| **C03** | KtxFoodItemCard | `KtxFoodItemCard` | Layout Vertical, Layout Horizontal; State Available, SoldOut (phủ xám). | `Semantics(label: 'card_food_item')` |
| **C04** | KtxBottomNavBar | `KtxBottomNavBar` | 4 Tabs: Home, Explore, Orders (có Badge số lượng), Profile. | `Semantics(container: true)` |
| **C05** | KtxAppBar | `KtxAppBar` | HomeHeader (Location selector + Badges), DetailHeader, TrackingHeader. | `Semantics(header: true)` |
| **C06** | KtxDialog | `KtxDialog` | OrderSuccessDialog, DangerConfirmDialog. | `Semantics(namesRoute: true)` |
| **C07** | KtxLoadingState | `KtxLoadingState` | ShimmerCardList (Skeleton UI), CircularOverlay. | `Semantics(label: 'loading_indicator')` |
| **C08** | KtxEmptyState | `KtxEmptyState` | EmptyCart, SearchNotFound, NoOrderHistory (gồm Icon, Text, CTA). | `Semantics(label: 'empty_state_view')` |
| **C09** | KtxErrorState | `KtxErrorState` | FullScreenNetworkError (có nút Retry), InlineErrorBanner, CutoffWarning. | `Semantics(label: 'error_state_view')` |
| **Extra**| KtxStickyCartBar | `KtxStickyCartBar` | Bar nổi bám đáy tại S2: Tổng món, Tạm tính, Nút "Xem giỏ hàng". | `Semantics(label: 'bar_sticky_cart')` |

---

## 5. Bảng Ghi nhận Thay đổi Thiết kế & Giải trình

| STT | Vị trí / Màn hình | Thiết kế ban đầu (Figma Lab 2) | Thực tế cài đặt (Flutter App Lab 3) | Lý do Kỹ thuật & Giải trình |
| :---: | :--- | :--- | :--- | :--- |
| **1** | **S4 & S7 (Điểm giao nhận KTX)** | Màn S4 ghi *"Trụ A1–A2"*, nhưng màn S7 ghi *"Cổng Đón B2 / Bàn số 2"*. | Chuẩn hóa thống nhất dữ liệu thành tên địa điểm chung: **"KTX Khu B – Trụ A1–A2 (Cổng B2)"**. | Đảm bảo tính nhất quán dữ liệu khi lưu vào Cloud Firestore và truyền qua các ViewModel, tránh lệch thông tin giữa luồng Đặt hàng (S4) và Nhận hàng (S7). |
| **2** | **S7 (Xác nhận nhận hàng)** | Sử dụng trigger `After delay` tự động chuyển màn hình (giả lập WebSocket). | Bổ sung nút bấm trực tiếp **"Đã nhận được hàng"** (hoặc lắng nghe sự kiện Firestore status đổi sang `delivered`). | Phục vụ việc chạy kịch bản kiểm thử tự động E2E bằng **Google ARTEMIS** và demo trực tiếp trên 1 thiết bị Android độc lập. |
| **3** | **S0 & S13 (Firebase Integration)** | Chưa có nút Google Sign-In chuẩn ở S0 và khu vực Demo Firebase ở S13. | Bổ sung nút **"Đăng nhập bằng Google"** ở S0 và **Firebase Demo Area** ở S13 (PDF Export/Upload, Remote Config, Crashlytics Test). | Đáp ứng các yêu cầu bắt buộc về tích hợp Cloud Backend (Authentication, Cloud Storage, Remote Config, Crashlytics) của Lab 3. |
| **4** | **C01 Button & Contrast** | Mã màu nút Cam `#FF5722` đi kèm một số cỡ chữ nhỏ 12sp. | Tăng cỡ chữ trên Button lên **15sp SemiBold**, kích thước chạm tối thiểu **48x48 dp**. | Đảm bảo tuân thủ tiêu chuẩn truy cập (Accessibility Checklist - WCAG 2.1 AA) và phản hồi tốt trên màn hình thiết bị Android outdoor. |