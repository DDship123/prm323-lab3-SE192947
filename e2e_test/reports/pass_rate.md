## Bảng tỷ lệ vượt qua (Pass rate)

| Mã TC | Nhóm | Tên test case | Kết quả từng lần | Pass / Tổng | Pass rate | Thời gian TB | Đánh giá |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| TC01 | Luồng chính | Đăng nhập bằng tài khoản mẫu Sinh viên | ✅ ✅ ✅ | 3/3 | 100% | 38s | Ổn định |
| TC02 | Luồng chính | Thêm 1 phần món đầu tiên vào giỏ, thanh giỏ hàng nổi cập nhật | ✅ ✅ ✅ | 3/3 | 100% | 45s | Ổn định |
| TC03 | Luồng chính | Tùy biến món (đổi tùy chọn, số lượng 2) rồi thêm vào giỏ | ✅ ✅ ✅ | 3/3 | 100% | 81s | Ổn định |
| TC04 | Luồng chính | Tăng số lượng món trong giỏ hàng, thành tiền cập nhật đúng | ✅ ✅ ✅ | 3/3 | 100% | 43s | Ổn định |
| TC05 | Luồng chính | Đặt đơn gom KTX với phương thức tiền mặt (COD) | ✅ ✅ ✅ | 3/3 | 100% | 105s | Ổn định |
| TC06 | Luồng chính | Đăng xuất từ tab Tài khoản quay về màn hình đăng nhập | ✅ ✅ ✅ | 3/3 | 100% | 55s | Ổn định |
| TC07 | Luồng lỗi | Đăng nhập khi bỏ trống email bị chặn kèm thông báo lỗi | ✅ ✅ ✅ | 3/3 | 100% | 76s | Ổn định |
| TC08 | Luồng lỗi | Đăng nhập khi bỏ trống mật khẩu bị chặn kèm thông báo lỗi | ❌ ✅ ✅ | 2/3 | 67% | 101s | Flaky |
| TC09 | Luồng lỗi | Đăng ký sinh viên thiếu họ tên bị từ chối | ✅ ✅ ✅ | 3/3 | 100% | 41s | Ổn định |
| TC10 | Luồng lỗi | Giỏ hàng trống hiển thị empty state và nút CTA điều hướng sang thực đơn | ✅ ✅ ✅ | 3/3 | 100% | 35s | Ổn định |
| TC11 | Luồng lỗi | Bỏ chọn tất cả món rồi bấm Thanh toán bị chặn | ✅ ✅ ❌ | 2/3 | 67% | 82s | Flaky |
| TC12 | Tương tác hệ thống | Hộp thoại quyền thông báo (Android 13+) sau khi đăng nhập | ✅ ✅ ✅ | 3/3 | 100% | 38s | Ổn định |
| TC13 | Tương tác hệ thống | Nút Back hệ thống quay lại đúng màn hình trước | ✅ ✅ ✅ | 3/3 | 100% | 26s | Ổn định |
| TC14 | Tương tác hệ thống | Đưa app xuống nền rồi mở lại vẫn giữ phiên đăng nhập và giỏ hàng | ✅ ❌ ❌ | 1/3 | 33% | 99s | Flaky |
| TC15 | Tương tác hệ thống | Khởi động lạnh (cold start) tự khôi phục phiên đã lưu | ✅ ✅ ✅ | 3/3 | 100% | 26s | Ổn định |
| **Tổng** | | | | **41/45** | **91%** | | |

## Chi tiết các lần chạy thất bại

- **TC08 run#1** (status `failed`, verdict `FAIL`, trace `f6e83885-ae25-414e-b3ea-32735e807804`): Đã thực hiện đầy đủ các bước: nhập "student@fpt.edu.vn" vào ô email, để trống mật khẩu, và bấm nút "Đăng nhập ngay". Ứng dụng vẫn ở màn hình đăng nhập, tuy nhiên không hiển thị thông báo Snackbar màu đỏ "Vui lòng nhập Mật khẩu" như yêu cầu kiểm thử. Do đó kết quả là thất bại (FAIL).
- **TC11 run#3** (status `failed`, verdict `FAIL`, trace `e3bfdedf-b204-4f4d-8860-70fc50b6307e`): The application menu requires item customization ('Tùy biến') for all dishes in this restaurant, meaning it is impossible to add any dish to the cart without selecting options first. Following the instruction: 'Nếu một kết quả mong đợi không xuất hiện sau tối đa 2 lần thử thì dừng lại và báo FAIL, t
- **TC14 run#2** (status `failed`, verdict `FAIL`, trace `c20a0302-78f2-490c-9814-5a8df811b175`): The application does not allow adding items without customization or without selecting options, and the cart remains empty after multiple attempts to add 'cơm chiên dương châu'. Therefore, step 1 cannot be completed successfully.
- **TC14 run#3** (status `failed`, verdict `FAIL`, trace `c32f3c27-de96-43a0-a0ff-a7e3e21d4986`): Sau khi kiểm tra, các món ăn trong ứng dụng KTX Food Ordering đều yêu cầu tùy biến trước khi thêm vào giỏ hàng hoặc nút thêm trực tiếp không phản hồi và không có thanh giỏ hàng nổi xuất hiện sau tối đa 2 lần thử theo yêu cầu bài toán. Do đó, không thể xác nhận trạng thái giỏ hàng 1 món để tiến hành 
