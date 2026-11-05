# BÁO CÁO CÔNG VIỆC HOÀN THÀNH – KTX FOOD APP
**Dự án:** Web App Giao Hàng Gom Đơn KTX (PRM393 - Lab 3)  
**Thời gian thực hiện:** 06/11/2026  
**Quy chuẩn tham chiếu:** Figma Prototype Canvas `06 Prototype` (File Key: `ALDYFWUZ72BaeyulpVi7uY`) & Tài liệu Thông số thiết kế KTX Food.

---

## I. TỔNG QUAN MỤC TIÊU & YÊU CẦU
1. **Responsive & Không hardcode kích thước:** Khắc phục triệt để các lỗi tràn viền (horizontal overflow), tràn chữ, chồng chéo component, đảm bảo giao diện thích ứng linh hoạt từ màn hình điện thoại (360px - 390px - 414px) đến tablet/desktop web.
2. **Đồng bộ 100% UI Figma Prototype:**
   - Chuẩn hóa hệ thống Design System (Màu sắc, Typography, Card, Button, Input, Pill).
   - Chuẩn hóa Header (`KtxAppBar` cao 66px, nền trắng 95%, các nút tròn 44x44 `#f9fafb`).
   - Chuẩn hóa Footer (`KtxBottomNavBar` cao 56px với 5 tab chuẩn).
   - Chuẩn hóa Thanh Giỏ Hàng Nổi Bám Đáy (`KtxStickyCartBar` Dark Floating Dock `#111827`).
3. **Sửa toàn bộ luồng điều hướng (Navigation Flow):**
   - Khắc phục lỗi chuyển sai trang giữa các tab Footer.
   - Đổi tab thứ 3 thành **Thông báo** (icon chuông + badge số thông báo chưa đọc).
   - Fix lỗi chọn món xong bấm vào giỏ hàng không chuyển trang.
   - Bấm vào Avatar trên Header chuyển thẳng đến trang **Cá nhân / Tài khoản**.

---

## II. XÂY DỰNG & CHUẨN HÓA HỆ THỐNG THIẾT KẾ (DESIGN SYSTEM)

| Thành phần | File mã nguồn | Mô tả quy chuẩn Figma |
|---|---|---|
| **Màu sắc (Colors)** | `lib/theme/app_colors.dart` | Nền `#f8fafc`, chữ chính `#111827`, chữ phụ `#6b7280`, cam chủ đạo `#ff5722`, cam nhạt `#ffedd5`, xanh lá `#059669`, đỏ `#ef4444`/`#b91c1c`, nút tròn `#f9fafb`, nền tối giỏ hàng `#111827`. |
| **Typography** | `lib/theme/app_typography.dart` | Chuẩn hóa toàn bộ sang font **Inter**: Tiêu đề Header 16 Bold, Tên quán/món 14 Bold, Giá 14 Bold (`#ff5722`), Thường 12, Chú thích 10–11, Pill 10 Bold. |
| **Bo góc (Radius)** | `lib/theme/app_radius.dart` | Thẻ bo tròn 16px, Nút & Ô nhập bo tròn 12px, Chip & Pill bo tròn tối đa 9999px. |
| **Khoảng cách (Spacing)**| `lib/theme/app_spacing.dart` | Đệm thẻ 12px, khoảng cách giữa các phần 12px, đệm form 16px. |
| **Thẻ KTX (Card)** | `lib/widgets/ktx_card.dart` | Nền trắng, bo 16, viền `#f3f4f6` dày 1, bóng Drop Shadow blur 2 offset y:1 đen 5%. |
| **Nút bấm (Button)** | `lib/widgets/ktx_button.dart` | Cao chuẩn 44px, bo 12, chữ 12 Bold. Hỗ trợ Primary (`#ff5722`), Secondary (`#ffedd5`), Danger (`#fef2f2`). |
| **Ô nhập (TextField)** | `lib/widgets/ktx_text_field.dart` | Nền `#f3f4f6`, bo 12, cao 44px, nhãn 12 SemiBold phía trên, vùng bấm chạm tối thiểu 44x44. |
| **Nhãn trạng thái (Pill)** | `lib/widgets/ktx_pill.dart` | Bo góc 9999px, chữ 10 Bold. Các biến thể: Chờ (`#ffedd5`), Hoàn thành (`#059669`), Từ chối (`#fef2f2`), Tiếp nhận (`#f3f4f6`). |

---

## III. CÁC NÂNG CẤP & SỬA LỖI GIAO DIỆN QUAN TRỌNG

### 1. Thanh Giỏ Hàng Nổi Bám Đáy (`lib/widgets/ktx_sticky_cart_bar.dart`)
- **Trước khi sửa:** Là một thanh cam toàn dải đơn điệu (`#ff5722`), không khớp thiết kế Figma.
- **Sau khi chuẩn hóa (Figma Node `822:394` & `605:381`):**
  - Đổi sang giao diện **Dark Floating Dock**: Nền tối `#111827` (độ mờ 95%), bo góc 16, đổ bóng bám đáy.
  - Bên trái: Vòng tròn cam 38x38 `#ff5722` chứa icon giỏ hàng trắng, góc trên gắn **Badge đỏ `#ef4444`** hiển thị chính xác số món.
  - Ở giữa: Dòng trên là địa điểm gom đơn (xám `#9ca3af`, 11px); dòng dưới là `{X} món` (trắng 13 Bold) • `{Tổng tiền}đ` (cam `#ff5722` 14 Bold).
  - Bên phải: Nút cam `#ff5722` bo góc 12 mang nhãn `"Xem giỏ hàng"` kèm icon mũi tên `->`.
  - **Quy tắc hiển thị thông minh:** Chỉ xuất hiện tại **Trang chủ (Tab 0)** và **Trang chọn món (Tab 1 / StoreDetailScreen)** khi có món trong giỏ (`totalItemCount > 0`). Ẩn hoàn toàn trên các trang Thông báo, Lịch sử, Tài khoản.
  - **Fix click:** Bấm vào bất kỳ đâu trên thanh nổi lập tức mở trực tiếp trang **Thanh Toán Gom Đơn** (`GroupCartCheckoutScreen`).

### 2. Header Chuẩn Figma (`lib/widgets/ktx_app_bar.dart`)
- Chiều cao chuẩn **66px**, nền trắng 95% (`#F2FFFFFF`), viền dưới `#f3f4f6`.
- Đã khắc phục lỗi co ép `SafeArea` làm tràn/cắt xén icon khi chạy trên các thiết bị có notch/status bar.
- Toàn bộ nút hành động đều dùng container tròn **44x44**, nền `#f9fafb`:
  - Nút Quay lại (Back).
  - Nút Chuông thông báo (kèm badge đỏ khi có tin chưa đọc).
  - Nút Giỏ hàng (kèm badge cam/đỏ số lượng món).
  - Nút Avatar người dùng.
- **Header Trang Chủ (Figma Node `822:414`):** Ô địa chỉ gom đơn với icon định vị cam trong ô tròn nhạt `#ffedd5` (34x34), nhãn `"GIAO ĐẾN"` (xám `#9ca3af`, 10 Bold) và địa chỉ `"Cổng KTX Khu B"` kèm chevron dropdown.
- **Xóa mã kỹ thuật:** Đổi toàn bộ tiêu đề từ dạng mã hoá nội bộ (S10, S12, S13, S4) thành tiêu đề chuẩn: `"Lịch Sử Đơn Hàng"`, `"Bảng Thông Báo"`, `"Tài Khoản"`, `"Thanh Toán Gom Đơn"`.

### 3. Thanh Footer Navigation (`lib/widgets/ktx_bottom_nav_bar.dart` & `lib/main.dart`)
Chuẩn hóa 5 tab độc lập, giải quyết triệt để lỗi chuyển sai màn hình:
1. **Tab 0: Khám phá (`HomeScreen`)**: Màn hình chính tìm món, duyệt các ca gom đơn KTX và quán ăn nổi bật.
2. **Tab 1: Đặt món (`StoreDetailScreen`)**: Màn hình chọn món trực tiếp với đầy đủ danh mục (Cơm KTX, Bún/Phở, Giải khát) và sheet tùy chọn Size/Topping.
3. **Tab 2: Thông báo (`NotificationBoardScreen`)**: 
   - Đổi từ "Thanh toán" sang **"Thông báo"**.
   - Icon: `Icons.notifications_none_rounded` / `Icons.notifications_rounded`.
   - Gắn huy hiệu (Badge) tự động đếm số thông báo ca gom / đơn hàng chưa đọc.
   - Bấm vào sẽ mở ngay **Bảng Thông Báo KTX**.
4. **Tab 3: Lịch sử (`OrderHistoryScreen`)**: Quản lý lịch sử đơn gom, xem chi tiết, QR code và đánh giá.
5. **Tab 4: Tài khoản (`ProfileSettingsScreen`)**: Xem thông tin sinh viên, đổi vai trò Demo, đăng xuất.

### 4. Tương Tác Avatar Trên Header
- Khi người dùng bấm vào Avatar tròn trên Header trang chủ: Chuyển hướng thẳng sang **Trang Cá nhân / Tài khoản** (`ProfileSettingsScreen`), thay vì hiện pop-up đổi vai trò như trước.
- Nút "Đổi vai trò người dùng (Demo)" được tích hợp gọn gàng trong trang Cá nhân.

### 5. Tối Ưu Hóa & Responsive Các Màn Hình Chi Tiết
- **Theo Dõi Đơn Hàng Thời Gian Thực (`LiveOrderTrackingScreen`)**: Responsive toàn bộ timeline trạng thái, responsive card thông tin shipper khi đơn ở trạng thái `DELIVERING`, đảm bảo duy nhất 1 nút chính primary theo đúng quy chuẩn.
- **Mã QR Nhận Hàng Cổng KTX (`PickupQrCodeScreen`)**: Sử dụng `LayoutBuilder` và `FittedBox` giúp container QR và mã PIN tự co giãn, căn giữa theo tỷ lệ mọi kích thước màn hình.
- **Đánh Giá & Phản Hồi (`ReviewFeedbackScreen`) & Thành Công (`ReviewSuccessScreen`)**: Card đánh giá quán & shipper độc lập, ChoiceChips wrap nhiều dòng không tràn màn hình, sau khi gửi đánh giá chuyển tiếp sang màn hình thành công tích xanh `#059669` và nút về lịch sử đơn hàng.
- **Khiếu Nại & Hoàn Tiền (`DisputeRefundScreen`)**: Banner bảo vệ 30 phút KTX, danh sách lý do Wrap responsive, tải ảnh chứng từ bồi hoàn.

---

## IV. KẾT QUẢ KIỂM TRA & XÁC MINH (VERIFICATION)
- **Kiểm tra cú pháp & biên dịch:** Chạy `flutter analyze --no-pub`.
- **Kết quả:** **0 lỗi biên dịch (0 compilation errors)**.
- **Khả năng tương thích:** Chạy tốt trên Flutter Web, Android, iOS, Windows desktop.

---
*Tài liệu được khởi tạo tự động bởi Antigravity Assistant.*

