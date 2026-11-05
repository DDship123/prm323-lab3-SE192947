# Kế Hoạch Đo Lường & Phân Tích Sự Kiện (Firebase Analytics Plan)

- **Dự án:** KTX Food Ordering App (Ứng dụng Đặt món & Gom đơn KTX)
- **Mã môn học:** PRM393 - Lab 3 (Bước 5: Instrument)
- **Package Name:** `com.example.prm393_lab03_se192947`
- **Nguyên tắc Bảo mật & Quyền riêng tư (Zero-PII Policy):**
  - **TUYỆT ĐỐI KHÔNG** gửi thông tin định danh cá nhân (PII - Personally Identifiable Information) như: Họ tên thật (`displayName`), Địa chỉ Email (`email`), Số điện thoại (`phoneNumber`), Số tài khoản ngân hàng, hoặc Địa chỉ phòng chi tiết của cá nhân trong bất kỳ tham số sự kiện (Event Parameters) nào.
  - Chỉ sử dụng các mã định danh hệ thống ẩn danh (`store_id`, `menu_item_id`, `order_id`, `campus_zone`, `auth_method`) và các chỉ số định lượng (`result_count`, `cart_total`, `file_size_kb`).

---

## 1. Danh Mục Sự Kiện Theo Dõi (Analytics Events Catalog)

Bảng dưới đây định nghĩa **8 sự kiện cốt lõi** (vượt mức tối thiểu 7 sự kiện theo yêu cầu Lab 3), tuân thủ chuẩn đặt tên `snake_case` và Recommended Events của Google Analytics 4 (GA4):

| STT | Tên sự kiện (`event_name`) | Phân loại | Màn hình / ViewModel kích hoạt | Mục đích đo lường | Tham số đính kèm (`parameters`) & Kiểu dữ liệu | Kiểm tra PII |
| :-: | :--- | :--- | :--- | :--- | :--- | :-: |
| **1** | `login` | Chuẩn GA4 (Sign-In) | **S0 - LoginScreen** (`AuthViewModel`) | Đo lường tỷ lệ đăng nhập thành công theo phương thức xác thực. | - `method` (`String`): `"google"` hoặc `"phone_otp"`<br/>- `campus_zone` (`String`): `"KTX_KHU_A"` / `"KTX_KHU_B"` | Không chứa PII |
| **2** | `sign_out` | Tùy chỉnh (Sign-Out) | **S13 - ProfileSettingsScreen** (`AuthViewModel`) | Theo dõi tần suất người dùng chủ động đăng xuất khỏi phiên làm việc. | - `session_type` (`String`): `"authenticated"` hoặc `"demo"` | Không chứa PII |
| **3** | `search` | Chuẩn GA4 (Search) | **S1 - HomeScreen** (`HomeViewModel`) | Phân tích nhu cầu tìm kiếm món ăn/quán ăn tại KTX và phát hiện từ khóa không có kết quả. | - `search_term` (`String`): Từ khóa món ăn (vd: `"Com tam"`)<br/>- `campus_zone` (`String`): `"ALL"`, `"KTX_KHU_A"`, `"KTX_KHU_B"`<br/>- `result_count` (`int`): Số lượng quán ăn tìm thấy | Không chứa PII |
| **4** | `view_store_detail` | Tùy chỉnh (Xem chi tiết) | **S2 - StoreDetailScreen** (`StoreDetailViewModel`) | Đánh giá mức độ quan tâm của sinh viên đối với từng quán ăn cụ thể. | - `store_id` (`int`): ID quán ăn (vd: `101`)<br/>- `store_category` (`String`): Phân khu quán (`"KTX_KHU_B"`)<br/>- `rating_avg` (`double`): Điểm đánh giá trung bình | Không chứa PII |
| **5** | `add_to_cart` | Chuẩn GA4 (Giỏ hàng) | **S3 - FoodCustomizationSheet** (`CartCheckoutViewModel`) | Theo dõi hành vi chọn món, tùy chỉnh size/topping và thêm vào giỏ gom đơn. | - `menu_item_id` (`int`): ID món ăn<br/>- `store_id` (`int`): ID quán ăn<br/>- `quantity` (`int`): Số lượng món<br/>- `unit_price` (`double`): Đơn giá món (VNĐ) | Không chứa PII |
| **6** | `begin_checkout` | Chuẩn GA4 (Thanh toán) | **S4 - GroupCartCheckoutScreen** (`CartCheckoutViewModel`) | Đo lường tỷ lệ chuyển đổi từ bước xem giỏ hàng sang bước xác nhận đặt đơn gom. | - `item_count` (`int`): Tổng số phần ăn trong giỏ<br/>- `subtotal_amount` (`double`): Tổng tiền món ăn (VNĐ)<br/>- `shipping_fee` (`double`): Phí ship gom đơn (VNĐ)<br/>- `pickup_point_code` (`String`): Mã cổng nhận hàng | Không chứa PII |
| **7** | `purchase` | Chuẩn GA4 (Đặt hàng) | **S5 - OnlinePaymentScreen** (`CartCheckoutViewModel`) | Ghi nhận đơn hàng gom KTX được thanh toán và khởi tạo thành công. | - `order_id` (`String`): Mã đơn hàng hệ thống<br/>- `value` (`double`): Tổng thanh toán cuối cùng<br/>- `currency` (`String`): `"VND"`<br/>- `payment_method` (`String`): `"VIETQR"` hoặc `"COD"` | Không chứa PII |
| **8** | `upload_dispute_evidence` | Tùy chỉnh (Export/Upload) | **S8 - DisputeRefundScreen** (`DisputeViewModel`) | Theo dõi luồng tải ảnh bằng chứng khiếu nại món hỏng/thiếu lên Firebase Cloud Storage. | - `order_id` (`String`): Mã đơn hàng khiếu nại<br/>- `reason_code` (`String`): Mã lý do (`"MISSING_ITEM"`, `"SPOILED_FOOD"`)<br/>- `refund_requested` (`double`): Số tiền yêu cầu hoàn (VNĐ)<br/>- `upload_status` (`String`): `"success"` hoặc `"failed"` | Không chứa PII |

---

## 2. Cấu Trúc Triển Khai Trong Kiến Trúc MVVM

Tuân thủ quy tắc kiến trúc trong `docs/architecture.md`, các Widget ở tầng UI **tuyệt đối không gọi trực tiếp** `FirebaseAnalytics.instance`. Mọi lời gọi được đóng gói qua `AnalyticsService` (`lib/firebase/analytics_service.dart`) và chỉ được gọi từ tầng **ViewModel**:

```mermaid
flowchart LR
    UI["Screens / Widgets<br/>(S0, S1, S2, S4, S8, S13)"] -->|User Action| VM["ViewModels<br/>(AuthVM, HomeVM, CartVM, DisputeVM)"]
    VM -->|Sanitized Params<br/>(No PII)| AS["AnalyticsService<br/>(lib/firebase/analytics_service.dart)"]
    AS -->|logEvent()| FA["Firebase Analytics SDK<br/>(GA4 DebugView)"]
```

---

## 3. Hướng Dẫn Kích Hoạt DebugView & Chụp Ảnh Minh Chứng

Mặc định Firebase gom nhóm (batch) các sự kiện và gửi lên server sau mỗi 30–60 phút để tiết kiệm pin. Để xem sự kiện hiển thị **theo thời gian thực (Realtime)** trên **Firebase Console > Analytics > DebugView**, thực hiện các bước sau:

### Bước 1: Bật chế độ Analytics Debug cho máy ảo / thiết bị Android
Mở Terminal và chạy lệnh `adb` với đúng `applicationId` của dự án:

```powershell
adb shell setprop debug.firebase.analytics.app com.example.prm393_lab03_se192947
```

*(Để tắt chế độ debug sau khi hoàn tất kiểm thử: `adb shell setprop debug.firebase.analytics.app .none.`)*

### Bước 2: Thao tác trên ứng dụng để sinh đủ các sự kiện
1. **Sự kiện `login`:** Nhấn nút *"Đăng nhập bằng Google (S0)"* trên màn hình đăng nhập.
2. **Sự kiện `search`:** Tại màn hình Trang chủ (S1), nhập từ khóa `"Cơm tấm"` vào thanh tìm kiếm và nhấn nút *"Tìm"*.
3. **Sự kiện `view_store_detail`:** Nhấn vào một thẻ quán ăn bất kỳ trên danh sách ở Trang chủ (S1) để mở màn hình Chi tiết quán (S2).
4. **Sự kiện `add_to_cart`:** Chọn một món ăn trong quán, chọn số lượng và nhấn *"Thêm vào giỏ gom đơn"*.
5. **Sự kiện `begin_checkout` & `purchase`:** Mở giỏ hàng (S4), kiểm tra phí ship gom đơn và nhấn *"Đặt đơn"* / *"Xác nhận thanh toán"* (S5).
6. **Sự kiện `upload_dispute_evidence`:** Vào mục *"Khiếu nại S8"*, chọn ảnh bằng chứng món ăn và nhấn *"Gửi khiếu nại & Tải ảnh Cloud"*.
7. **Sự kiện `sign_out`:** Chuyển sang tab *"Hồ sơ S13"* và nhấn nút *"Đăng xuất tài khoản"*.

### Bước 3: Mở DebugView trên Firebase Console và chụp ảnh minh chứng
1. Truy cập [Firebase Console](https://console.firebase.google.com/) > Chọn dự án **`prm323-lab3`**.
2. Ở menu bên trái, chọn **Analytics** > **DebugView**.
3. Tại ô **Debug Device** ở góc trên bên trái, chọn thiết bị máy ảo Android (`sdk gphone...`).
4. Khi các sự kiện (`login`, `search`, `view_store_detail`, `upload_dispute_evidence`, `sign_out`,...) xuất hiện trên dòng thời gian (Timeline), bấm vào từng sự kiện để mở bảng **Parameters** bên phải.
5. Chụp ảnh màn hình và lưu vào thư mục `evidence/` của dự án để nộp báo cáo.

