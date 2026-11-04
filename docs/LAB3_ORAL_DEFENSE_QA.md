# BỘ CÂU HỎI VẤN ĐÁP LÝ THUYẾT & THỰC HÀNH BẢO VỆ LAB 3 (PRM393)
## TÀI LIỆU ÔN TẬP VẤN ĐÁP DÀNH CHO SINH VIÊN

---

### PHẦN 1: FIREBASE CLOUD MESSAGING (FCM)

#### Câu 1: FCM Registration Token được sinh ra từ đâu và có ý nghĩa gì?
* **Trả lời**:
  * Token được sinh ra trực tiếp từ dịch vụ **Firebase Cloud Messaging SDK** trên thiết bị thông qua lời gọi hàm `FirebaseMessaging.instance.getToken()`.
  * **Ý nghĩa**: Token là một chuỗi định danh duy nhất (Unique Identifier) đại diện cho một bản cài đặt ứng dụng cụ thể trên một thiết bị phần cứng cụ thể. Nó cho phép FCM Backend định tuyến chính xác thông báo đến thiết bị đó mà không bị nhầm lẫn.

#### Câu 2: FCM Token được lưu trữ ở đâu trên Client và Server?
* **Trả lời**:
  * **Phía Client**: Được lưu vào bộ nhớ tạm thời (`_cachedFcmToken`) hoặc lưu bền vững trong `SharedPreferences` để tái sử dụng.
  * **Phía Server**: Client gọi API `POST /api/v1/users/me/fcm-token` để gửi token lên Backend. Server Spring Boot lưu token này vào trường `fcm_token` của bảng `users` trong cơ sở dữ liệu tương ứng với `userId` của sinh viên/tài xế.

#### Câu 3: Khi nào FCM Token bị thay đổi (Refresh)? Client xử lý thế nào?
* **Trả lời**:
  * Token thay đổi khi:
    1. Người dùng xóa dữ liệu ứng dụng (Clear App Data).
    2. Ứng dụng bị gỡ cài đặt và cài lại (Re-install).
    3. Thiết bị được khôi phục cài đặt gốc (Factory Reset).
    4. Firebase tự động làm mới token định kỳ vì lý do bảo mật.
  * **Cách xử lý**: Lắng nghe sự kiện `FirebaseMessaging.instance.onTokenRefresh.listen((newToken) { ... })`, mỗi khi có token mới thì tự động gọi API đẩy token mới lên Backend cập nhật lại DB.

#### Câu 4: Phía Server dùng hàm nào để gửi tin nhắn đến thiết bị?
* **Trả lời**:
  * Server Spring Boot sử dụng thư viện **Firebase Admin SDK** (Java):
    ```java
    Message message = Message.builder()
        .setToken(userFcmToken)
        .setNotification(Notification.builder()
            .setTitle("Đơn hàng đang giao")
            .setBody("Shipper Nguyễn Hùng đang mang món đến sảnh KTX BA1")
            .build())
        .putData("orderId", "1001")
        .build();
    FirebaseMessaging.getInstance().send(message);
    ```

#### Câu 5: Thiết bị nhận và hiển thị thông báo thế nào ở Foreground vs Background?
* **Trả lời**:
  * **Background / Terminated (App đang tắt hoặc chạy ẩn)**: Hệ điều hành Android/iOS tự động nhận payload thông báo từ Google Play Services và vẽ thanh Notification lên Status Bar trên cùng của điện thoại. Khi người dùng nhấn vào, hệ điều hành khởi động app và kích hoạt hàm `FirebaseMessaging.onMessageOpenedApp`.
  * **Foreground (App đang mở trên màn hình)**: Mặc định hệ điều hành sẽ **không** hiện thông báo status bar để tránh làm phiền trải nghiệm. Do đó, app phải lắng nghe `FirebaseMessaging.onMessage.listen((RemoteMessage message) { ... })` và chủ động hiển thị **In-App Notification Banner** (hoặc Custom SnackBar) ở đỉnh màn hình để người dùng biết.

---

### PHẦN 2: FIREBASE CRASHLYTICS & GIÁM SÁT LỖI

#### Câu 6: Sự khác nhau bản chất giữa Fatal Crash và Non-Fatal Error là gì?
* **Trả lời**:
  * **Fatal Crash (Sự cố sập ứng dụng)**: Là lỗi nghiêm trọng không được bắt (unhandled native crash hoặc unhandled exception) khiến tiến trình (process) ứng dụng bị hệ điều hành tiêu diệt ngay lập tức. App bị văng ra màn hình Home của điện thoại.
  * **Non-Fatal Error (Lỗi được xử lý)**: Là các exception nghiệp vụ nằm trong khối `try-catch` (ví dụ: mất mạng, timeout, parse JSON lỗi). Ứng dụng vẫn tiếp tục chạy bình thường, người dùng vẫn sử dụng được, nhưng developer ghi nhận vết lỗi lên Crashlytics qua `recordError(..., fatal: false)` để theo dõi tần suất lỗi.

#### Câu 7: Vì sao khi bấm nút gây Crash, mở Firebase Console chưa thấy ngay mà phải mở lại app mới thấy?
* **Trả lời**:
  * Khi app bị **Force Crash**, tiến trình của ứng dụng bị hệ điều hành tắt tức thì, các kết nối mạng bị ngắt ngay lập tức, **không thể gửi request HTTP lên Firebase kịp thời**.
  * Crashlytics giải quyết bằng cách: SDK ghi lại báo cáo lỗi (Crash Session Dump, Stacktrace, Log) vào **bộ nhớ đệm trên đĩa (Local Storage)** của thiết bị ngay trước khi tiến trình tắt.
  * Khi người dùng **khởi động lại ứng dụng ở phiên tiếp theo**, Crashlytics SDK khởi tạo trong hàm `main()`, quét bộ nhớ đệm phát hiện có Crash dump chưa gửi, và ngầm gửi toàn bộ gói tin lỗi đó lên Firebase Console.

#### Câu 8: Trong Flutter, hàm nào bắt toàn bộ lỗi Unhandled Exception?
* **Trả lời**:
  * Có 2 tầng bắt lỗi cần cấu hình tại hàm `main()`:
    1. **Tầng Framework (UI/Flutter Widget)**:
       ```dart
       FlutterError.onError = (errorDetails) {
         FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
       };
       ```
    2. **Tầng Nền tảng (Asynchronous Dart Engine / Platform Dispatcher)**:
       ```dart
       PlatformDispatcher.instance.onError = (error, stack) {
         FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
         return true; // Đã xử lý lỗi
       };
       ```

#### Câu 9: Làm thế nào để thêm thông tin chẩn đoán (User ID, Custom Keys) lên Crashlytics?
* **Trả lời**:
  * Gán User ID: `FirebaseCrashlytics.instance.setUserIdentifier("student_se192947@fpt.edu.vn");`
  * Gán Custom Key (Metadata): `FirebaseCrashlytics.instance.setCustomKey("active_role", "STUDENT");`
  * Ghi Breadcrumb log: `FirebaseCrashlytics.instance.log("Người dùng nhấn nút Đặt Hàng Ca Trưa");`

---

### PHẦN 3: FIREBASE REMOTE CONFIG & CLOUD STORAGE

#### Câu 10: Remote Config hoạt động thế nào và tại sao cần thiết hơn lưu trên DB?
* **Trả lời**:
  * **Nguyên lý**: Remote Config lưu các cặp key-value trên đám mây của Google. Client tải về bằng `fetchAndActivate()`.
  * **Ưu điểm so với Database thông thường**:
    1. **Không phụ thuộc vào Database server**: Nếu backend gặp sự cố hoặc bảo trì, app vẫn lấy được cấu hình từ hạ tầng CDN toàn cầu của Google.
    2. **Hỗ trợ phân nhóm A/B Testing & Phân đoạn người dùng**: Có thể cấu hình giá trị khác nhau theo hệ điều hành (Android vs iOS), theo ngôn ngữ, hoặc theo phần trăm người dùng.
    3. **Không cần cập nhật APK**: Thay đổi tham số nghiệp vụ (như số đơn tối thiểu để giảm giá gom đơn từ 5 xuống 3) có hiệu lực ngay lập tức.

#### Câu 11: Quy trình upload và xem ảnh bằng chứng món hỏng diễn ra thế nào?
* **Trả lời**:
  1. Sinh viên chụp ảnh món ăn bị hỏng -> nén dạng `Uint8List`.
  2. Client gọi `FirebaseStorage.instance.ref('reports/{userId}/evidence_{timestamp}.jpg').putData(bytes, metadata)`.
  3. Lấy `getDownloadURL()` công khai và đính kèm vào trường `evidenceImageUrl` khi tạo khiếu nại qua API `POST /api/v1/disputes`.
  4. Trên Cổng Web Admin: Admin mở danh sách khiếu nại, ảnh được hiển thị qua widget `InteractiveViewer` cho phép cuộn/phóng to thu nhỏ để kiểm tra xem thức ăn có thực sự bị bung nắp hay giao nhầm hay không trước khi bấm nút "Duyệt hoàn tiền".

---

### PHẦN 4: THIẾT BỊ THẬT, MÔ HÌNH WEB ADMIN & VPS

#### Câu 12: Giảng viên yêu cầu chấm trên thiết bị thật, làm sao ứng dụng kết nối được Backend khi 2 máy ở 2 mạng khác nhau?
* **Trả lời**:
  * Nhóm triển khai Backend Spring Boot lên **VPS có IP Public tĩnh** (không dùng IP mạng nội bộ `192.168.x.x` hay `10.0.2.2`).
  * Đồng thời, trên ứng dụng Flutter đã tích hợp **Hộp thoại cấu hình máy chủ động (`ServerConfigDialog`)**:
    * Cho phép nhập trực tiếp IP VPS, Domain hoặc Ngrok tunnel.
    * Có nút **"Kiểm tra kết nối (Ping Test)"** gửi request tới `/api/v1/health/ping` để báo trạng thái Ping thành công (Pong) trước khi lưu.
    * Nhờ đó thiết bị thật chạy 4G Viettel/Vinaphone hay Wi-Fi bất kỳ đều kết nối thông suốt với Backend.

#### Câu 13: Tại sao Admin phải dùng Web và Web chỉ phục vụ cho Admin?
* **Trả lời**:
  * Đây là yêu cầu nghiệp vụ thực tế của mô hình trường đại học:
    * **Sinh viên, Shipper, Quán ăn**: Cần tính cơ động, sử dụng điện thoại di động mọi lúc mọi nơi để đặt món, nhận thông báo đẩy và giao hàng tại sảnh KTX.
    * **Ban Quản Lý KTX (Admin)**: Ngồi tại phòng trực ban quản lý, sử dụng màn hình máy tính lớn (Desktop/Laptop Web) để xem bảng biểu số liệu tổng quan KPI, đối soát doanh thu gom đơn, và đặc biệt là xem ảnh bằng chứng phóng to để phân xử khiếu nại công bằng.
  * Ứng dụng sử dụng cờ `kIsWeb` của Flutter: khi mở trên trình duyệt Web máy tính, hệ thống tự động khóa và chuyển hướng thẳng vào **Web Admin Portal**.

