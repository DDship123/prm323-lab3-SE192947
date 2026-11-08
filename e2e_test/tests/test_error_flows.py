"""Luồng lỗi: kiểm tra validate dữ liệu và trạng thái rỗng."""

import pytest

pytestmark = pytest.mark.error_flow

CATEGORY = "Luồng lỗi"


def test_tc07_login_with_empty_email_shows_validation(app, run_case):
    app.start_logged_out()
    run_case(
        case_id="TC07",
        title="Đăng nhập khi bỏ trống email bị chặn kèm thông báo lỗi",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra app chặn đăng nhập khi chưa nhập email.
Các bước:
1. Ở màn hình "Đăng nhập tài khoản", KHÔNG bấm chip tài khoản mẫu nào và để trống ô "Email hoặc Số điện thoại".
2. Nhập "123456" vào ô "Mật khẩu".
3. Bấm nút "Đăng nhập ngay", rồi quan sát NGAY màn hình (thông báo chỉ hiện khoảng 4 giây).
Kết quả mong đợi:
- Thanh thông báo (snackbar) màu đỏ hiển thị "Vui lòng nhập Email hoặc Số điện thoại".
- App vẫn ở màn hình "Đăng nhập tài khoản" (không xuất hiện thanh điều hướng 5 tab).
""",
    )


def test_tc08_login_with_empty_password_shows_validation(app, run_case):
    app.start_logged_out()
    run_case(
        case_id="TC08",
        title="Đăng nhập khi bỏ trống mật khẩu bị chặn kèm thông báo lỗi",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra app chặn đăng nhập khi chưa nhập mật khẩu.
Các bước:
1. Ở màn hình "Đăng nhập tài khoản", nhập "student@fpt.edu.vn" vào ô "Email hoặc Số điện thoại".
2. Để trống ô "Mật khẩu".
3. Bấm nút "Đăng nhập ngay", rồi quan sát NGAY màn hình (thông báo chỉ hiện khoảng 4 giây).
Kết quả mong đợi:
- Snackbar màu đỏ hiển thị "Vui lòng nhập Mật khẩu".
- App vẫn ở màn hình "Đăng nhập tài khoản".
""",
    )


def test_tc09_register_without_name_is_rejected(app, run_case):
    app.start_logged_out()
    run_case(
        case_id="TC09",
        title="Đăng ký sinh viên thiếu họ tên bị từ chối",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra validate form đăng ký sinh viên.
Các bước:
1. Ở màn hình đăng nhập, bấm liên kết "Đăng ký tài khoản mới".
2. Ở màn hình "Đăng ký Sinh viên KTX", để trống ô "Họ và tên sinh viên *".
3. Nhập "0987654321" vào ô "Số điện thoại nhận đơn & OTP *".
4. Ẩn bàn phím nếu đang che nút, rồi bấm nút "Tiếp tục nhận mã OTP".
Kết quả mong đợi:
- Một khung báo lỗi hiển thị "Vui lòng nhập đầy đủ họ tên và số điện thoại hợp lệ."
- App vẫn ở màn hình "Đăng ký Sinh viên KTX" (không chuyển sang màn hình nhập OTP).
""",
    )


def test_tc10_empty_cart_state_and_explore_cta(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC10",
        title="Giỏ hàng trống hiển thị empty state và nút CTA điều hướng sang thực đơn",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra trạng thái giỏ hàng trống.
Các bước:
1. Bấm tab "Giỏ hàng" ở thanh điều hướng dưới cùng (giỏ đang trống vì app vừa được reset).
2. Xác nhận màn hình hiển thị tiêu đề "Giỏ hàng của bạn đang trống".
3. Bấm nút "Khám phá thực đơn ngay".
Kết quả mong đợi:
- Bước 2: dòng chữ "Giỏ hàng của bạn đang trống" xuất hiện.
- Sau bước 3: tab "Đặt món" trở thành tab đang chọn và màn hình hiển thị thực đơn quán ăn.
""",
    )


def test_tc11_checkout_with_no_item_selected_is_blocked(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC11",
        title="Bỏ chọn tất cả món rồi bấm Thanh toán bị chặn",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra không cho thanh toán khi không có món nào được tích chọn.
Các bước:
1. Bấm tab "Đặt món", bấm nút "Thêm <tên món> vào giỏ" (dấu + màu cam) của món đầu tiên không cần tùy biến.
2. Bấm tab "Giỏ hàng".
3. Ở thanh dưới cùng, bấm ô "Tất cả" để BỎ chọn toàn bộ món (nút thanh toán chuyển thành "Thanh toán (0)" màu xám).
4. Bấm nút "Thanh toán (0)", rồi quan sát NGAY màn hình (thông báo chỉ hiện 2 giây).
Kết quả mong đợi:
- Snackbar màu đỏ hiển thị "Vui lòng tích chọn ít nhất 1 món ăn để thanh toán".
- App vẫn ở màn hình "Giỏ Hàng Gom Đơn" (không mở màn hình "Thanh Toán Gom Đơn").
""",
    )
