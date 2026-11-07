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
        title="Thêm món không tùy biến vào giỏ, thanh giỏ hàng nổi cập nhật",
        category=CATEGORY,
        goal="""
Mục tiêu: thêm một món không cần tùy biến vào giỏ hàng.
Các bước:
1. Bấm tab "Đặt món" ở thanh điều hướng dưới cùng và chờ thực đơn tải xong.
2. Tìm món đầu tiên trong thực đơn có nút "Thêm <tên món> vào giỏ" (nút dấu + màu cam, KHÔNG phải nút "Tùy biến"). Cuộn xuống nếu cần. Ghi nhớ tên và giá của món đó.
3. Bấm nút "Thêm <tên món> vào giỏ" đúng 1 lần.
Kết quả mong đợi:
- Tại vị trí món đó xuất hiện bộ đếm số lượng với giá trị "1" và các nút "Giảm số lượng" / "Tăng số lượng".
- Thanh giỏ hàng nổi ở đáy màn hình xuất hiện với nội dung "1 món" và tổng tiền bằng đúng giá của món vừa thêm.
""",
    )


def test_tc03_customize_item_and_add_two_portions(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC03",
        title="Tùy biến món (đổi nước mắm, số lượng 2) rồi thêm vào giỏ",
        category=CATEGORY,
        goal="""
Mục tiêu: tùy biến một món có tùy chọn và thêm 2 phần vào giỏ.
Các bước:
1. Bấm tab "Đặt món". Tìm món đầu tiên có nút "Tùy biến" và bấm nút đó. Ghi nhớ tên món.
2. Ở màn hình "Tùy Biến Món Ăn", cuộn xuống nhóm "Độ cay & Nước mắm" và chọn "Nước mắm không cay (Không ớt)".
3. Bấm nút "Tăng số lượng" đúng 1 lần để số lượng chuyển từ 1 thành 2.
4. Bấm nút "Thêm vào giỏ • ..." ở đáy màn hình.
5. Bấm tab "Giỏ hàng".
Kết quả mong đợi:
- Màn hình "Giỏ Hàng Gom Đơn" có món vừa tùy biến với số lượng "2".
- Dưới tên món có nhãn tùy chọn "Nước mắm không cay (Không ớt)".
""",
    )


def test_tc04_cart_quantity_increase_updates_line_total(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC04",
        title="Tăng số lượng trong giỏ hàng, thành tiền cập nhật đúng",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra tăng số lượng một món trong giỏ hàng.
Các bước:
1. Bấm tab "Đặt món", bấm nút "Thêm <tên món> vào giỏ" (dấu + màu cam) của món đầu tiên không cần tùy biến. Ghi nhớ đơn giá của món.
2. Bấm tab "Giỏ hàng".
3. Ở dòng món đó, đọc giá trị "Thành tiền: ..." hiện tại.
4. Bấm nút "Tăng số lượng <tên món>" đúng 1 lần.
Kết quả mong đợi:
- Số lượng của món hiển thị "2".
- "Thành tiền" của dòng món bằng đúng 2 lần đơn giá.
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
Các bước:
1. Bấm tab "Đặt món", bấm nút "Thêm <tên món> vào giỏ" (dấu + màu cam) của món đầu tiên không cần tùy biến.
2. Bấm tab "Giỏ hàng", rồi bấm nút "Thanh toán (1)".
3. Ở màn hình "Thanh Toán Gom Đơn", cuộn xuống phần phương thức thanh toán và chọn "Tiền mặt khi nhận tại cổng (COD)".
4. Bấm nút "Đặt đơn nhận tại ..." ở đáy màn hình và chờ tối đa 20 giây.
Kết quả mong đợi:
- Hộp thoại "Đặt đơn thành công!" xuất hiện, có mã đơn hàng và nút "Theo dõi đơn hàng".
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
