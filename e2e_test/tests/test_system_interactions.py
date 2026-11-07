"""Tương tác hệ thống Android: hộp thoại quyền, nút Back, đưa app xuống nền / khởi động lại."""

import pytest

pytestmark = pytest.mark.system

CATEGORY = "Tương tác hệ thống"


def test_tc12_notification_permission_dialog_after_login(app, run_case):
    app.start_logged_out(grant_notifications=False)
    run_case(
        case_id="TC12",
        title="Hộp thoại quyền thông báo (Android 13+) sau khi đăng nhập",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra app xin quyền gửi thông báo (POST_NOTIFICATIONS) của hệ thống Android sau khi đăng nhập.
Các bước:
1. Bấm chip "Tài khoản mẫu Sinh viên" rồi bấm "Đăng nhập ngay", chờ tối đa 20 giây.
2. Một hộp thoại HỆ THỐNG Android sẽ hỏi có cho phép ứng dụng gửi thông báo hay không
   (tiếng Anh: "Allow ... to send you notifications?", tiếng Việt: "Cho phép ... gửi thông báo cho bạn?").
   Đây là hộp thoại của hệ điều hành, được phép bấm vào nó. Bấm "Allow" / "Cho phép".
Kết quả mong đợi:
- Hộp thoại xin quyền thông báo của hệ thống đã xuất hiện ở bước 2.
- Sau khi bấm cho phép, hộp thoại đóng lại và app hiển thị thanh điều hướng 5 tab ("Khám phá", "Đặt món", "Giỏ hàng", "Lịch sử", "Tài khoản").
""",
    )


def test_tc13_system_back_button_navigation(app, run_case):
    app.start_logged_out()
    run_case(
        case_id="TC13",
        title="Nút Back hệ thống quay lại đúng màn hình trước",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra nút Back phần cứng/hệ thống của Android.
Các bước:
1. Ở màn hình đăng nhập, bấm liên kết "Quên mật khẩu?".
2. Xác nhận đang ở màn hình "Khôi phục mật khẩu - 1".
3. Nhấn nút BACK của hệ thống Android (phím Back, không dùng nút mũi tên trên app bar).
Kết quả mong đợi:
- Bước 2: tiêu đề "Khôi phục mật khẩu - 1" hiển thị.
- Sau bước 3: app quay lại màn hình "Đăng nhập tài khoản" và app KHÔNG bị thoát ra màn hình chính của Android.
""",
    )


def test_tc14_background_and_resume_keeps_cart(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC14",
        title="Đưa app xuống nền rồi mở lại vẫn giữ phiên đăng nhập và giỏ hàng",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra app giữ trạng thái khi bị đưa xuống nền.
Các bước:
1. Bấm tab "Đặt món", bấm nút "Thêm <tên món> vào giỏ" (dấu + màu cam) của món đầu tiên không cần tùy biến.
2. Xác nhận thanh giỏ hàng nổi hiển thị "1 món".
3. Nhấn nút HOME của hệ thống Android để về màn hình chính của điện thoại, chờ khoảng 3 giây.
4. Mở lại ứng dụng KTX Food Ordering (qua màn hình ứng dụng gần đây hoặc mở lại app).
Kết quả mong đợi:
- Sau khi mở lại, app KHÔNG quay về màn hình "Đăng nhập tài khoản".
- Thanh điều hướng 5 tab vẫn hiển thị và tab "Giỏ hàng" có huy hiệu số "1" (hoặc thanh giỏ hàng nổi vẫn hiển thị "1 món").
""",
    )


def test_tc15_saved_session_survives_cold_start(app, run_case):
    app.start_logged_in()
    run_case(
        case_id="TC15",
        title="Khởi động lạnh (cold start) tự khôi phục phiên đã lưu",
        category=CATEGORY,
        goal="""
Mục tiêu: kiểm tra app tự khôi phục phiên đăng nhập đã lưu sau khi bị tắt hẳn và mở lại.
Ứng dụng vừa được hệ thống tắt hẳn rồi khởi động lại, KHÔNG cần đăng nhập.
Các bước:
1. Quan sát màn hình hiện tại của app (chờ tối đa 15 giây nếu đang hiển thị vòng xoay tải).
2. Bấm tab "Tài khoản".
Kết quả mong đợi:
- Ở bước 1 app KHÔNG hiển thị màn hình "Đăng nhập tài khoản" mà vào thẳng giao diện có thanh điều hướng 5 tab.
- Ở bước 2 màn hình tài khoản hiển thị nút "Đăng xuất tài khoản".
""",
    )
