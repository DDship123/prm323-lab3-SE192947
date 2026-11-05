# QUY CHUẨN VIẾT GIT COMMIT MESSAGE

Tài liệu này quy định tiêu chuẩn viết thông điệp commit (commit message) theo phong cách **Conventional Commits** cho toàn bộ thành viên tham gia phát triển dự án **WaterBus**. Việc tuân thủ quy chuẩn giúp lịch sử Git rõ ràng, dễ theo dõi tiến độ, dễ tra cứu lỗi và tự động hóa việc tạo changelog / release notes.

---

## 1. Cấu Trúc Chuẩn Của Commit Message

Mỗi commit message bao gồm cấu trúc như sau:

```text
[TYPE] <Mô tả ngắn gọn nội dung thay đổi>

[Phần thân (Body) - Không bắt buộc: Giải thích chi tiết nguyên nhân và giải pháp]

[Chân trang (Footer) - Không bắt buộc: Liên kết Issue / Ticket / Task]
```

---

## 2. Danh Mục Các Commit Type Chuẩn

Bắt buộc sử dụng các tiền tố viết hoa nằm trong dấu ngoặc vuông `[TYPE]`:

| Type | Ý nghĩa & Khi nào sử dụng | Ví dụ mẫu |
| :--- | :--- | :--- |
| **`[FEAT]`** | Thêm một tính năng mới (Feature) hoặc API endpoint mới cho hệ thống. | `[FEAT] Thêm API đăng ký user mới` |
| **`[FIX]`** | Sửa chữa một lỗi (Bug fix) trong logic, xử lý dữ liệu hoặc validation. | `[FIX] Sửa lỗi validation email` |
| **`[UPDATE]`** | Cập nhật, nâng cấp hoặc chỉnh sửa chức năng, giao diện (UI) hoặc cấu hình hiện có. | `[UPDATE] Cập nhật UI trang đặt vé` |
| **`[REFACTOR]`** | Tái cấu trúc mã nguồn (tách file, đổi tên, dọn dẹp code thừa) nhưng **không** làm thay đổi hành vi hoạt động của hệ thống. | `[REFACTOR] Tách component BookingForm` |
| **`[TEST]`** | Thêm mới, cập nhật hoặc sửa chữa các bài kiểm thử (Unit test, Integration test). | `[TEST] Thêm unit test cho AuthService` |
| **`[DOCS]`** | Thêm hoặc cập nhật tài liệu kỹ thuật, hướng dẫn sử dụng, file `.md`. | `[DOCS] Cập nhật tài liệu quy chuẩn RESTful API` |
| **`[CHORE]`** | Các thay đổi phụ trợ không ảnh hưởng code nghiệp vụ: Cập nhật dependency (`pom.xml`), cấu hình build, gitignore,... | `[CHORE] Nâng cấp phiên bản Spring Cloud Dependencies` |
| **`[PERF]`** | Tối ưu hóa hiệu năng hệ thống (truy vấn DB, thuật toán, caching,...). | `[PERF] Đánh index bảng tickets để tối ưu tốc độ tìm kiếm` |

---

## 3. Các Quy Tắc Viết Commit Subject (Dòng Tiêu Đề)

1. **Định dạng tiền tố:** Viết hoa toàn bộ tên Type và bọc trong dấu ngoặc vuông `[ ]`, theo sau là một khoảng trắng.
   - Chuẩn: `[FEAT] ...`
   - Không chuẩn: `feat: ...`, `[feat] ...`, `FEAT: ...`
2. **Độ dài tiêu đề:** Ngắn gọn, súc tích, **dưới 72 ký tự**.
3. **Dấu câu:** **KHÔNG** kết thúc dòng tiêu đề bằng dấu chấm (`.`).
4. **Ngôn ngữ:** **BẮT BUỘC sử dụng tiếng Việt CÓ DẤU đầy đủ, chuẩn chính tả.** Tuyệt đối KHÔNG viết tiếng Việt không dấu.
   - *Lưu ý trên môi trường Windows CLI/PowerShell:* Cần thiết lập bảng mã UTF-8 (`[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` hoặc `chcp 65001`) hoặc truyền message qua file/script UTF-8 để đảm bảo ký tự có dấu không bị vỡ font/mojibake.
5. **Nội dung:** Mô tả trực tiếp hành động được thực hiện thay vì mô tả chung chung.

---

## 4. Bảng So Sánh Ví Dụ Đúng & Sai

| Loại thay đổi | Commit ĐÚNG ✅ | Commit SAI ❌ |
| :--- | :--- | :--- |
| Tính năng mới | `[FEAT] Thêm API đăng ký user mới` | `feat api user`<br>`thêm tính năng` |
| Sửa lỗi | `[FIX] Sửa lỗi validation email` | `fix bug`<br>`sửa lỗi linh tinh` |
| Cập nhật | `[UPDATE] Cập nhật UI trang đặt vé` | `update`<br>`update code moi` |
| Tái cấu trúc | `[REFACTOR] Tách component BookingForm` | `refactor`<br>`dọn code` |
| Viết test | `[TEST] Thêm unit test cho AuthService` | `viet test`<br>`test auth` |
| Tài liệu | `[DOCS] Bổ sung hướng dẫn cài đặt môi trường` | `update readme` |
| Cấu hình | `[CHORE] Cập nhật phiên bản MapStruct lên 1.5.5` | `sua pom.xml` |

---

## 5. Mẫu Commit Đầy Đủ (Full Commit Message)

Với các thay đổi phức tạp hoặc quan trọng, nên viết kèm **Body** và **Footer**:

### Ví dụ 1: Tính năng mới phức tạp
```text
[FEAT] Thêm API giữ chỗ ghế tạm thời khi đặt vé

- Tạo endpoint POST /api/v1/trips/{id}/seats/reserve
- Cài đặt cơ chế Distributed Lock bằng Redis để tránh tranh chấp ghế
- Thiết lập thời gian hết hạn giữ chỗ trong vòng 10 phút

Refs #WB-102
```

### Ví dụ 2: Sửa lỗi nghiêm trọng (Bug fix)
```text
[FIX] Sửa lỗi sai số tiền thanh toán khi áp dụng mã giảm giá

- Nguyên nhân: Chưa làm tròn số thập phân trước khi gửi sang cổng VNPay
- Khắc phục: Ép kiểu sang số nguyên VND trước khi tạo chữ ký thanh toán

Closes #WB-245
```

### Ví dụ 3: Tái cấu trúc code (Refactor)
```text
[REFACTOR] Tách component BookingForm thành các sub-components nhỏ

- Tách SeatPicker và CustomerInfoForm thành 2 component độc lập
- Giảm kích thước file từ 800 dòng xuống dưới 200 dòng mỗi file
```

---

## 6. Quy Định Về Nhánh (Branching Naming Convention)

Để đồng bộ với commit convention, tên nhánh (branch) trên Git cần đặt theo định dạng:

```text
<loại-nhánh>/<nội-dung-ngắn-gọn>
```

- **`feature/`**: Phát triển tính năng mới.
  - Ví dụ: `feature/user-registration`, `feature/booking-seats`
- **`bugfix/`**: Sửa lỗi trên môi trường dev/staging.
  - Ví dụ: `bugfix/email-validation-error`, `bugfix/vnpay-checksum`
- **`hotfix/`**: Sửa lỗi khẩn cấp trực tiếp trên production.
  - Ví dụ: `hotfix/security-jwt-expired`
- **`refactor/`**: Tái cấu trúc mã nguồn.
  - Ví dụ: `refactor/booking-form-component`

---

## 7. Checklist Tự Kiểm Tra Trước Khi Commit

Trước khi thực hiện `git commit`, hãy tự kiểm tra:
- [ ] Commit này có mang tính **Atomic** không (chỉ giải quyết 1 mục đích duy nhất, không gom nhiều việc không liên quan vào 1 commit)?
- [ ] Tiền tố `[TYPE]` đã đúng định dạng chữ in hoa và có dấu ngoặc vuông chưa?
- [ ] **Commit message đã viết bằng TIẾNG VIỆT CÓ DẤU ĐẦY ĐỦ chưa?** (Tuyệt đối không viết không dấu)
- [ ] Tiêu đề commit đã mô tả rõ ràng nội dung thay đổi chưa?
- [ ] Dòng tiêu đề có bị thừa dấu chấm `.` ở cuối không?
- [ ] Đã kiểm tra không commit nhầm các file rác (`.DS_Store`, file log, thư mục `target/`, file cấu hình mật khẩu cá nhân)?
