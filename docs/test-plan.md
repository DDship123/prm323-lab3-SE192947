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
