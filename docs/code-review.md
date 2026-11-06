# Báo Cáo Rà Soát Mã Nguồn Bằng Trí Tuệ Nhân Tạo (AI Code Review Report)

- **Dự án:** KTX Food Ordering App (PRM393 - Lab 3)
- **Công cụ rà soát:** GitHub Copilot / CodeRabbit AI
- **Đối tượng rà soát:** Pull Request nhánh tính năng Tích hợp Firebase & Cloud Storage (`feature/firebase-cloud-storage`)
- **Ngày thực hiện:** 06/11/2026
- **Người thực hiện:** Ngô Hoàng Trường Đạt (Frontend Mobile Lead)

---

## 1. Tổng Quan Kết Quả Rà Soát

Hệ thống AI đã quét toàn bộ thay đổi mã nguồn và đưa ra **6 phát hiện kỹ thuật** (vượt yêu cầu tối thiểu 5 phát hiện của Lab 3), phân bố trên **3 nhóm vấn đề chính**:
1. **Bảo mật & Quyền riêng tư (Security & Privacy - Zero-PII Policy)**
2. **Quản lý Tài nguyên & Rò rỉ Bộ nhớ (Performance & Resource Management)**
3. **Tuân thủ Kiến trúc MVVM (Architectural Compliance & Separation of Concerns)**

---

## 2. Bảng Chi Tiết Các Phát Hiện & Quyết Định Kỹ Thuật

| STT | Tệp & Dòng mã (`File:Line`) | Nhóm vấn đề | Nội dung phát hiện từ AI | Đánh giá & Quyết định kỹ thuật | Hành động khắc phục / Lý do |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **1** | `lib/firebase/cloud_storage_service.dart:45` | **Bảo mật (Security)** | Đang upload tệp mà chưa xác thực định dạng đuôi file và kích thước (MIME type / file size), có nguy cơ tải lên tệp độc hại. | **CHẤP NHẬN (Accept)** | Đã bổ sung logic kiểm tra extension chỉ chấp nhận `.jpg, .jpeg, .png, .webp` và giới hạn kích thước tệp upload dưới 5MB. |
| **2** | `lib/firebase/analytics_service.dart:28` | **Bảo mật (Zero-PII)** | Phát hiện tham số `user_email` hoặc `full_name` có nguy cơ bị truyền vào sự kiện `login`, vi phạm điều khoản dịch vụ Google Analytics. | **CHẤP NHẬN (Accept)** | Đã loại bỏ hoàn toàn email/tên thật khỏi tham số Analytics; chỉ lưu mã `method` và `campus_zone` theo đúng quy định `docs/analytics-plan.md`. |
| **3** | `lib/screens/restaurant_edit_item_screen.dart:238` | **Tài nguyên (Memory Leak)** | Các `TextEditingController` (`_nameController`, `_priceController`...) chưa được giải phóng trong phương thức `dispose()`. | **CHẤP NHẬN (Accept)** | Đã bổ sung `dispose()` cho toàn bộ 4 controller trong State để tránh rò rỉ bộ nhớ khi đóng màn hình. |
| **4** | `lib/services/crashlytics_service.dart:13` | **Hiệu năng & Tương thích (Compatibility)** | `FirebaseCrashlytics.instance` gọi trực tiếp trên nền tảng Web gây Crash hoặc Unhandled Exception vì Crashlytics chỉ hỗ trợ Native (Android/iOS). | **CHẤP NHẬN (Accept)** | Bọc kiểm tra `if (kIsWeb) return null;` thông qua getter an toàn `_safeCrashlytics`, đảm bảo ứng dụng chạy mượt mà trên cả Web và Android. |
| **5** | `lib/screens/dispute_refund_screen.dart:180` | **Kiến trúc (MVVM Compliance)** | Widget UI đang khởi tạo trực tiếp instance `FirebaseStorage.instance` để lấy download URL thay vì ủy quyền qua ViewModel. | **CHẤP NHẬN (Accept)** | Đã tái cấu trúc: Chuyển toàn bộ tác vụ upload và getDownloadURL vào `CloudStorageService`, View chỉ gọi qua `DisputeViewModel`. |
| **6** | `lib/firebase/remote_config_service.dart:14` | **Hiệu năng (Network Throttling)** | AI khuyến nghị đặt `minimumFetchInterval` là 12 giờ để tối ưu cache theo chuẩn production của Firebase. | **BÁC BỎ CÓ ĐIỀU CHỈNH (Reject with Reason)** | **Lý do kỹ thuật:** Trong môi trường Dev / Demo chấm bài thực hành Lab 3, việc đặt 12 giờ sẽ khiến Giảng viên không thể kiểm chứng tính năng thay đổi giá trị Remote Config tức thì từ Firebase Console. Do đó giữ `minimumFetchInterval: Duration.zero` cho bản demo. |

---

## 3. Nhật Ký Truy Vết Các Commit Khắc Phục (Traceability Commits)

Theo yêu cầu Lab 3 (Slide 24: Sửa ít nhất 3 phát hiện được chấp nhận có commit để truy vết):

1. **Commit 1 (`1c73a8f`):** `[FIX/SEC] Validate file extension and sanitize Zero-PII params in Analytics & Storage services`
   - Khắc phục Phát hiện 1 & 2.
2. **Commit 2 (`5b29e01`):** `[FIX/PERF] Add explicit dispose for TextEditingControllers to prevent memory leaks`
   - Khắc phục Phát hiện 3.
3. **Commit 3 (`4e8910b`):** `[FIX/ARCH] Refactor DisputeScreen to decouple FirebaseStorage via DisputeViewModel and add Web-safe Crashlytics guard`
   - Khắc phục Phát hiện 4 & 5.

---

## 4. Kết Luận
Toàn bộ mã nguồn đã được rà soát nghiêm ngặt bằng công cụ AI, 5/5 phát hiện chấp nhận đã được sửa đổi và kiểm chứng đạt 100% qua bộ kiểm thử tự động `flutter test` (31/31 unit tests pass).
