"""Luồng chính (happy path): đăng nhập, chọn món, giỏ hàng, đặt đơn, đăng xuất."""

import pytest

pytestmark = pytest.mark.main_flow

CATEGORY = "Luồng chính"


def test_tc01_login_with_student_demo_account(app, run_case):
    app.start_logged_out()
    run_case(
        case_id="TC01",
        title="Đăng nhập bằng tài khoản mẫu Sinh viên",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra đăng nhập bằng tài khoản mẫu Sinh viên.
Các bước:
1. Ở màn hình "Đăng nhập tài khoản", bấm chip "Tài khoản mẫu Sinh viên" (nhãn hiển thị "🎓 Sinh viên").
2. Kiểm tra ô "Email hoặc Số điện thoại" đã được điền "student@fpt.edu.vn".
3. Bấm nút "Đăng nhập ngay" và chờ tối đa 20 giây (app có thể hiển thị vòng xoay khi gọi backend).
Kết quả mong đợi:
- Màn hình đăng nhập biến mất.
- Thanh điều hướng dưới cùng hiển thị đủ 5 tab: "Khám phá", "Đặt món", "Giỏ hàng", "Lịch sử", "Tài khoản".
""",
    )


def test_tc02_add_simple_item_updates_sticky_cart(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC02",
        title="Thêm 1 phần món đầu tiên vào giỏ, thanh giỏ hàng nổi cập nhật",
        category=CATEGORY,
        goal="""
Mục tiêu: thêm 1 phần của món đầu tiên trong thực đơn vào giỏ hàng (giỏ đang trống).
Thực đơn được tải từ backend; món có thể có nút "Tùy biến" hoặc nút dấu + màu cam, cả hai đều hợp lệ.
Các bước:
1. Bấm tab "Đặt món" ở thanh điều hướng dưới cùng và chờ thực đơn tải xong. Ghi nhớ tên món đầu tiên trong danh sách món.
2. Ở món đầu tiên đó:
   - Nếu món có nút dấu + màu cam ("Thêm <tên món> vào giỏ"): bấm nút đó đúng 1 lần. Giá cần ghi nhớ là giá hiển thị trên thẻ món.
   - Nếu món có nút "Tùy biến": bấm nút "Tùy biến". Ở màn hình tùy biến, GIỮ NGUYÊN các lựa chọn mặc định và số lượng 1
     (không bấm tùy chọn nào, không bấm "Tăng số lượng"). Ghi nhớ số tiền trên nút "Thêm vào giỏ • <số tiền>" ở đáy màn hình,
     rồi bấm nút đó đúng 1 lần để quay lại thực đơn.
Kết quả mong đợi:
- Thẻ của món vừa thêm hiển thị bộ đếm số lượng với giá trị "1" (có nút giảm "-" và tăng "+").
- Thanh giỏ hàng nổi ở đáy màn hình hiển thị "1 món" và tổng tiền bằng đúng số tiền đã ghi nhớ ở bước 2.
""",
    )


def test_tc03_customize_item_and_add_two_portions(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC03",
        title="Tùy biến món (đổi tùy chọn, số lượng 2) rồi thêm vào giỏ",
        category=CATEGORY,
        goal="""
Mục tiêu: tùy biến một món có tùy chọn và thêm 2 phần vào giỏ.
Tùy chọn của món được tải từ backend nên KHÔNG cố định tên; hãy đọc trên màn hình.
Các bước:
1. Bấm tab "Đặt món". Tìm món đầu tiên có nút "Tùy biến" và bấm nút đó. Ghi nhớ tên món.
2. Ở màn hình "Tùy Biến Món Ăn", tìm nhóm tùy chọn đầu tiên. Chọn lựa chọn THỨ HAI của nhóm đó
   (nếu nhóm chỉ có 1 lựa chọn thì chọn lựa chọn đó). Ghi nhớ chính xác tên lựa chọn vừa chọn.
3. Bấm nút "Tăng số lượng" đúng 1 lần để số lượng chuyển từ 1 thành 2.
4. Bấm nút "Thêm vào giỏ • ..." ở đáy màn hình.
5. Bấm tab "Giỏ hàng".
Kết quả mong đợi:
- Màn hình "Giỏ Hàng Gom Đơn" có món vừa tùy biến với số lượng "2".
- Dưới tên món có nhãn tùy chọn chứa đúng tên lựa chọn đã ghi nhớ ở bước 2.
Nếu thực đơn không có món nào có nút "Tùy biến", trả về FAIL với lý do "không có món có tùy chọn".
""",
    )


def test_tc04_cart_quantity_increase_updates_line_total(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC04",
        title="Tăng số lượng món trong giỏ hàng, thành tiền cập nhật đúng",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra tăng số lượng một món trong giỏ hàng.
Thực đơn được tải từ backend; món có thể có nút "Tùy biến" hoặc nút dấu + màu cam, cả hai đều hợp lệ.
Các bước:
1. Bấm tab "Đặt món" và chờ thực đơn tải xong. Thêm 1 phần của món đầu tiên trong danh sách món vào giỏ:
   - Nếu món có nút dấu + màu cam ("Thêm <tên món> vào giỏ"): bấm nút đó đúng 1 lần.
   - Nếu món có nút "Tùy biến": bấm nút đó, GIỮ NGUYÊN các lựa chọn mặc định và số lượng 1,
     rồi bấm nút "Thêm vào giỏ • <số tiền>" ở đáy màn hình đúng 1 lần.
2. Bấm tab "Giỏ hàng".
3. Ở dòng món vừa thêm, xác nhận số lượng là "1" và ghi nhớ giá trị "Thành tiền: ..." hiện tại (đây là đơn giá của 1 phần).
4. Bấm nút "Tăng số lượng <tên món>" (dấu +) của dòng món đó đúng 1 lần.
Kết quả mong đợi:
- Số lượng của món hiển thị "2".
- "Thành tiền" của dòng món bằng đúng 2 lần giá trị đã ghi nhớ ở bước 3.
- Nút thanh toán ở đáy hiển thị "Thanh toán (2)" (đếm theo tổng số phần đang được chọn).
""",
    )


def test_tc05_place_order_with_cod(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC05",
        title="Đặt đơn gom KTX với phương thức tiền mặt (COD)",
        category=CATEGORY,
        goal="""
Mục tiêu: đặt một đơn hàng hoàn chỉnh bằng phương thức tiền mặt.
Thực đơn được tải từ backend; món có thể có nút "Tùy biến" hoặc nút dấu + màu cam, cả hai đều hợp lệ.
Các bước:
1. Bấm tab "Đặt món" và chờ thực đơn tải xong. Thêm 1 phần của món đầu tiên trong danh sách món vào giỏ:
   - Nếu món có nút dấu + màu cam ("Thêm <tên món> vào giỏ"): bấm nút đó đúng 1 lần.
   - Nếu món có nút "Tùy biến": bấm nút đó, GIỮ NGUYÊN các lựa chọn mặc định và số lượng 1,
     rồi bấm nút "Thêm vào giỏ • <số tiền>" ở đáy màn hình đúng 1 lần.
2. Bấm tab "Giỏ hàng", rồi bấm nút "Thanh toán (1)".
3. Ở màn hình "Thanh Toán Gom Đơn", cuộn xuống phần phương thức thanh toán và chọn "Tiền mặt khi nhận tại cổng (COD)".
4. Bấm nút "Đặt đơn nhận tại ..." ở đáy màn hình và chờ tối đa 20 giây.
Kết quả mong đợi:
- Hộp thoại "Đặt đơn thành công!" xuất hiện, có mã đơn hàng và nút "Theo dõi đơn hàng".
Đơn được tạo thật qua backend. Nếu sau 20 giây vẫn ở màn hình "Thanh Toán Gom Đơn" mà không có hộp thoại nào,
trả về FAIL với lý do "backend không tạo được đơn (app không hiển thị lỗi)".
""",
    )


def test_tc06_sign_out_returns_to_login(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC06",
        title="Đăng xuất từ tab Tài khoản quay về màn hình đăng nhập",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra đăng xuất.
Các bước:
1. Bấm tab "Tài khoản" ở thanh điều hướng dưới cùng.
2. Cuộn xuống cuối trang và bấm nút "Đăng xuất tài khoản".
Kết quả mong đợi:
- App quay về màn hình có tiêu đề "Đăng nhập tài khoản" với nút "Đăng nhập ngay".
- Thanh điều hướng 5 tab không còn hiển thị.
""",
    )
