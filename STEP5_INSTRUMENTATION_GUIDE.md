# Hướng Dẫn Chi Tiết Bước 5: Instrument (Analytics, Crashlytics, Remote Config & FCM)

Tài liệu này là **cẩm nang thực hành từng bước (Step-by-Step)** được đúc kết từ quá trình triển khai thực tế trên dự án `prm393_lab03_se192947`. Tất cả các đường dẫn file trong tài liệu đều sử dụng **đường dẫn tương đối (động)** để mọi thành viên trong nhóm khi clone từ GitHub về máy hoặc xem trực tiếp trên GitHub đều có thể bấm mở file ngay lập tức.

---

## 📌 Mục Lục
1. [Chuẩn Bị: Thư Viện, Gradle & Khắc Phục Lỗi Build](#1-chuẩn-bị-thư-viện-gradle--khắc-phục-lỗi-build)
2. [Phần 1: Cấu Hình Firebase Analytics & Bật DebugView](#2-phần-1-cấu-hình-firebase-analytics--bật-debugview)
3. [Phần 2: Cấu Hình & Áp Dụng Firebase Crashlytics](#3-phần-2-cấu-hình--áp-dụng-firebase-crashlytics)
4. [Phần 3: Cấu Hình & Áp Dụng Firebase Remote Config](#4-phần-3-cấu-hình--áp-dụng-firebase-remote-config)
5. [Phần 4: Cấu Hình & Áp Dụng Cloud Messaging (FCM) & Điều Hướng](#5-phần-4-cấu-hình--áp-dụng-cloud-messaging-fcm--điều-hướng)
6. [Checklist Đánh Giá & Minh Chứng Cần Chụp Nộp Bài](#6-checklist-đánh-giá--minh-chứng-cần-chụp-nộp-bài)

---

## 1. Chuẩn Bị: Thư Viện, Gradle & Khắc Phục Lỗi Build

### 1.1. Cài đặt các gói thư viện vào Flutter
Mở Terminal tại thư mục gốc của dự án và chạy lệnh:
```powershell
flutter pub add firebase_analytics firebase_crashlytics firebase_remote_config firebase_messaging
```

Đảm bảo [`pubspec.yaml`](./pubspec.yaml) có đầy đủ:
```yaml
dependencies:
  firebase_core: ^4.6.0
  firebase_auth: ^6.3.0
  google_sign_in: ^7.2.0
  firebase_storage: ^13.2.0
  firebase_analytics: ^12.2.0
  firebase_crashlytics: ^5.1.0
  firebase_remote_config: ^6.3.0
  firebase_messaging: ^16.1.3
```

### 1.2. Cấu hình Gradle cho Crashlytics
1. File [`android/build.gradle.kts`](./android/build.gradle.kts):
   ```kotlin
   plugins {
       id("com.google.gms.google-services") version "4.4.2" apply false
       id("com.google.firebase.crashlytics") version "3.0.3" apply false
   }
   ```
2. File [`android/app/build.gradle.kts`](./android/app/build.gradle.kts):
   ```kotlin
   plugins {
       id("com.android.application")
       id("kotlin-android")
       id("dev.flutter.flutter-gradle-plugin")
       id("com.google.gms.google-services")
       id("com.google.firebase.crashlytics") // Bắt buộc để gửi báo cáo Crashlytics
   }
   ```
3. **Lưu ý sửa lỗi biên dịch chéo ổ đĩa (C: và D:) trên Windows**:
   Nếu dự án đặt ở ổ đĩa khác ổ `C:` (nơi chứa Pub Cache), thêm 2 dòng sau vào cuối file [`android/gradle.properties`](./android/gradle.properties):
   ```properties
   kotlin.incremental=false
   kotlin.incremental.useClasspathSnapshot=false
   ```

### 1.3. Cấp quyền Thông báo trên Android 13+ (`POST_NOTIFICATIONS`)
Mở [`android/app/src/main/AndroidManifest.xml`](./android/app/src/main/AndroidManifest.xml), thêm quyền ngay trên thẻ `<application>`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## 2. Phần 1: Cấu Hình Firebase Analytics & Bật DebugView

### 2.1. Thiết kế 8 sự kiện chuẩn GA4 (Zero-PII)
Chi tiết kế hoạch đo lường nằm tại [`docs/analytics-plan.md`](./docs/analytics-plan.md). Danh sách 8 sự kiện (yêu cầu tối thiểu 7 sự kiện):
1. `login` — Đăng nhập thành công (`method`, `campus_zone`).
2. `sign_out` — Đăng xuất khỏi ứng dụng (`session_type`).
3. `search` — Tìm kiếm món ăn/quán ăn (`search_term`, `campus_zone`, `result_count`).
4. `view_store_detail` — Xem chi tiết quán ăn (`store_id`, `store_category`, `rating_avg`).
5. `add_to_cart` — Thêm món vào giỏ gom đơn (`menu_item_id`, `store_id`, `quantity`, `unit_price`).
6. `begin_checkout` — Bắt đầu thanh toán (`item_count`, `subtotal_amount`, `shipping_fee`).
7. `purchase` — Thanh toán đơn hàng thành công (`order_id`, `value`, `currency`, `payment_method`).
8. `upload_dispute_evidence` — Gửi khiếu nại kèm ảnh bằng chứng (`order_id`, `reason_code`, `refund_requested`, `upload_status`).

> **Nguyên tắc Zero-PII**: Tuyệt đối không truyền email, tên thật, số điện thoại hay địa chỉ phòng cá nhân vào `parameters`.

---

### 2.2. Tạo file Service [`lib/firebase/analytics_service.dart`](./lib/firebase/analytics_service.dart)
File này đóng gói toàn bộ 8 hàm ghi nhận sự kiện (`logSignIn`, `logSignOut`, `logSearch`, `logViewStoreDetail`, `logAddToCart`, `logBeginCheckout`, `logPurchase`, `logUploadDisputeEvidence`) dùng `FirebaseAnalytics.instance.logEvent(...)`.

---

### 2.3. Các vị trí gắn kết (Wiring) `AnalyticsService` vào Project

Để sự kiện được bắn lên khi người dùng thao tác, `AnalyticsService` được gắn vào **7 file** sau:

1. **[`lib/main.dart`](./lib/main.dart)**:
   - Đăng ký vào `MultiProvider`:
     ```dart
     Provider<AnalyticsService>(create: (_) => AnalyticsService()),
     ```
   - Gọi `context.read<AnalyticsService>().logSignIn(method: 'google')` khi đăng nhập Google thành công.
   - Gọi `context.read<AnalyticsService>().logSignOut(sessionType: 'authenticated')` khi bấm đăng xuất.

2. **[`lib/screens/home_screen.dart`](./lib/screens/home_screen.dart) (Trang chủ S1)**:
   - Khi bấm nút Tìm kiếm: gọi `logSearch(searchTerm: ..., campusZone: ..., resultCount: ...)`.
   - Khi chạm vào thẻ quán ăn: gọi `logViewStoreDetail(storeId: store.id, storeCategory: ..., ratingAvg: store.ratingAvg)`.

3. **[`lib/screens/food_customization_sheet.dart`](./lib/screens/food_customization_sheet.dart) (Chọn Size/Topping S3)**:
   - Khi bấm "Thêm vào giỏ gom đơn": gọi `logAddToCart(menuItemId: widget.menuItem.id, storeId: widget.storeId, quantity: _quantity, unitPrice: widget.menuItem.basePrice)`.

4. **[`lib/screens/group_cart_checkout_screen.dart`](./lib/screens/group_cart_checkout_screen.dart) (Giỏ hàng S4)**:
   - Trong `_handlePlaceOrder`: gọi `logBeginCheckout(itemCount: cartVm.totalItemCount, subtotalAmount: cartVm.subtotalAmount, shippingFee: cartVm.deliveryFee)`.

5. **[`lib/screens/online_payment_screen.dart`](./lib/screens/online_payment_screen.dart) (Thanh toán S5)**:
   - Khi xác nhận VietQR hoặc chuyển sang COD thành công: gọi `logPurchase(orderId: widget.order.id.toString(), totalValue: widget.order.finalAmount, paymentMethod: 'VIETQR')`.

6. **[`lib/screens/dispute_refund_screen.dart`](./lib/screens/dispute_refund_screen.dart) (Khiếu nại S8)**:
   - Khi gửi khiếu nại xong: gọi `logUploadDisputeEvidence(orderId: 'ORD_${vm.selectedOrder!.id}', reasonCode: vm.selectedReason, refundRequested: ..., uploadStatus: 'success' / 'failed')`.

7. **[`lib/screens/profile_settings_screen.dart`](./lib/screens/profile_settings_screen.dart) (Màn hình Hồ sơ & Demo S13)**:
   - Cung cấp nút **"Bắn 8 Sự Kiện"** gọi hàm `_triggerAllAnalyticsEvents(context)` để gửi liên tiếp cả 8 sự kiện cách nhau 300ms phục vụ chụp ảnh minh chứng nhanh.

---

### 2.4. Cách bật DebugView bằng ADB & Xử lý lỗi thường gặp

#### Bước 1: Kích hoạt chế độ Debug Analytics cho máy ảo
Mặc định Firebase gom sự kiện sau mỗi 1 giờ mới gửi. Để hiện tức thì (Realtime) trên **DebugView**, phải chạy lệnh `adb`:

- **Trường hợp 1 (Máy đã cài `adb` trong biến môi trường PATH)**:
  ```powershell
  adb shell setprop debug.firebase.analytics.app com.example.prm393_lab03_se192947
  ```
- **Trường hợp 2 (Bị lỗi `adb: The term 'adb' is not recognized...` trên Windows PowerShell)**:
  Dùng biến môi trường động `$env:LOCALAPPDATA` trỏ thẳng tới Android SDK của máy hiện tại:
  ```powershell
  & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" shell setprop debug.firebase.analytics.app com.example.prm393_lab03_se192947
  ```
  *(Khi nào muốn tắt chế độ debug thì thay tên package ở cuối bằng `.none.`)*.

#### Bước 2: Chạy ứng dụng trên máy ảo Android
> **Lưu ý**: Không chạy trên trình duyệt Web (Chrome/Edge) để test Firebase native plugins. Luôn chạy trên máy ảo Android:
```powershell
flutter run -d emulator-5554
```
*(Nếu vừa sửa code xong mà app đang mở sẵn, hãy nhấn phím **`R` (viết hoa)** trong cửa sổ Terminal để **Hot Restart** nạp code mới)*.

#### Bước 3: Bắn 8 sự kiện và kiểm tra trên Firebase Console DebugView
1. Mở **Firebase Console** ➔ Chọn project **prm323-lab3** ➔ Menu bên trái chọn **Analytics** ➔ **DebugView**.
2. Ở góc trên bên trái mục **Debug Device**, đảm bảo đã chọn đúng máy ảo (ví dụ: `sdk_gphone16k_x86_64`).
3. **Phân biệt sự kiện tự động và sự kiện nghiệp vụ**:
   - Khi mới mở app ở màn hình Đăng nhập, DebugView chỉ hiển thị các sự kiện hệ thống mặc định: `session_start`, `screen_view`, `user_engagement`, `first_open`. **Lúc này CHƯA ĐỦ 8 sự kiện!**
4. **Cách lấy đủ 8 sự kiện trong 5 giây**:
   - Trên máy ảo, bấm **Đăng nhập bằng Google** để vào trong app.
   - Bấm vào tab **Hồ sơ** (biểu tượng hình người góc dưới bên phải).
   - Kéo xuống mục **Firebase Demo & Testing**, tại dòng *"Bắn 8 sự kiện lên DebugView"*, bấm nút **[Bắn 8 Sự Kiện]**.
   - Đợi thông báo màu xanh *"🎉 Đã gửi thành công đủ 8 sự kiện!"*.
5. Nhìn sang trình duyệt **DebugView** (đợi 3–5 giây), kiểm tra bảng **TOP EVENTS** bên phải đã xuất hiện đủ tên các sự kiện: `login`, `search`, `view_store_detail`, `add_to_cart`, `begin_checkout`, `purchase`, `upload_dispute_evidence`, `sign_out`. Chụp ảnh màn hình này để nộp bài!

---

## 3. Phần 2: Cấu Hình & Áp Dụng Firebase Crashlytics

### 3.1. Yêu cầu kỹ thuật của Bước 5
1. Gửi **1 lỗi được xử lý (Non-Fatal Error)** từ một luồng lỗi thực tế.
2. Gửi **1 lỗi thử nghiệm làm văng app (Test Fatal Crash)**.
3. Đính kèm **User ID** và ít nhất **1 Custom Key** lên Crashlytics Dashboard.

### 3.2. Mã nguồn [`lib/firebase/crashlytics_service.dart`](./lib/firebase/crashlytics_service.dart)
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Đính kèm User ID và Custom Keys lên Dashboard
  Future<void> setUserContext({
    required String userId,
    required String campusZone,
    required String currentScreen,
  }) async {
    if (kIsWeb) return;
    await _crashlytics.setUserIdentifier(userId);
    await _crashlytics.setCustomKey('ktx_campus_zone', campusZone);
    await _crashlytics.setCustomKey('current_screen', currentScreen);
  }

  /// 1. Gửi lỗi được xử lý (Non-Fatal Error)
  Future<void> recordNonFatalError(
    Object exception,
    StackTrace? stackTrace, {
    required String reason,
  }) async {
    if (kIsWeb) return;
    await _crashlytics.log('Non-fatal error occurred: $reason');
    await _crashlytics.recordError(
      exception,
      stackTrace ?? StackTrace.current,
      reason: reason,
      fatal: false,
    );
  }

  /// 2. Kích hoạt lỗi thử nghiệm (Test Fatal Crash)
  void triggerTestCrash() {
    if (kIsWeb) return;
    _crashlytics.log('User triggered manual test crash from S13 Demo Area');
    _crashlytics.crash();
  }
}
```

### 3.3. 3 vị trí bắt buộc gọi `CrashlyticsService` trong Project

1. **[`lib/main.dart`](./lib/main.dart)**:
   - **Bắt lỗi toàn cục trong `main()`**:
     ```dart
     if (!kIsWeb) {
       FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
       PlatformDispatcher.instance.onError = (error, stack) {
         FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
         return true;
       };
     }
     ```
   - **Cung cấp qua `MultiProvider`**:
     ```dart
     Provider<CrashlyticsService>(create: (_) => CrashlyticsService()),
     ```
   - **Gắn User ID & Custom Keys khi đăng nhập**:
     Trong `_signInWithGoogle()` và `_MainShellScreenState.initState()`:
     ```dart
     context.read<CrashlyticsService>().setUserContext(
       userId: user.uid,
       campusZone: 'KTX_KHU_B',
       currentScreen: 'S1_Home',
     );
     ```

2. **[`lib/screens/online_payment_screen.dart`](./lib/screens/online_payment_screen.dart) (Luồng lỗi thực tế)**:
   - Trong `_handleConfirmTransfer` và `_handleSwitchToCod`, khi xác nhận thanh toán thất bại (`!ok`), hệ thống tự động gọi:
     ```dart
     context.read<CrashlyticsService>().recordNonFatalError(
       Exception('VietQrVerificationFailedException: Không tìm thấy giao dịch đơn #${widget.order.id} thất bại'),
       StackTrace.current,
       reason: 'Khách hàng bấm Xác nhận nhưng hệ thống ngân hàng chưa ghi nhận tiền về',
     );
     ```

3. **[`lib/screens/profile_settings_screen.dart`](./lib/screens/profile_settings_screen.dart) (Nút bấm test nhanh tại S13)**:
   - Nút **[Ghi Log]** (*Firebase Crashlytics Non-Fatal Log*): Gọi `recordNonFatalError(...)` gửi lỗi `HandledPaymentTimeoutException` ngay lập tức.
   - Nút **[Crash App]** (*Firebase Crashlytics Fatal Crash (Test)*): Gọi `triggerTestCrash()` làm văng app ngay lập tức để kiểm thử Fatal Crash.

### 3.4. Quy trình 4 bước kiểm thử & lấy ảnh Crashlytics trên Firebase Console
1. **Bước 1**: Mở app trên máy ảo và **Đăng nhập bằng Google** (bắt buộc để Crashlytics ghi nhận `userId` và Custom Keys `ktx_campus_zone`, `current_screen`).
2. **Bước 2**: Vào tab **Hồ sơ (S13)** ➔ Bấm nút **[Ghi Log]** để gửi lỗi Non-Fatal.
3. **Bước 3**: Bấm nút **[Crash App]** màu đỏ ➔ Ứng dụng sẽ bị đóng đột ngột (văng ra màn hình chính máy ảo).
4. **Bước 4 (Rất quan trọng)**: Chạm vào biểu tượng ứng dụng trên máy ảo để **mở lại app một lần nữa**. Khi app khởi động lại, SDK Crashlytics mới đẩy gói báo cáo crash vừa xảy ra lên máy chủ Firebase.
5. Vào **Firebase Console** ➔ **Crashlytics** (đợi 1–2 phút và tải lại trang):
   - Bạn sẽ thấy cả lỗi **Fatal** và **Non-fatal**.
   - Bấm vào chi tiết một lỗi ➔ Chuyển sang tab **Keys** và nhìn góc phải để thấy **User ID** cùng các khóa `ktx_campus_zone = KTX_KHU_B`, `current_screen = S1_Home`. Chụp màn hình này làm minh chứng!

---

## 4. Phần 3: Cấu Hình & Áp Dụng Firebase Remote Config

### 4.1. Yêu cầu kỹ thuật của Bước 5
- Cấu hình ít nhất **2 tham số** trên Firebase Remote Config làm thay đổi giao diện/hành vi ứng dụng mà **không cần build lại app**.
- Thiết lập giá trị mặc định trong ứng dụng (`setDefaults`).

### 4.2. Mã nguồn [`lib/firebase/remote_config_service.dart`](./lib/firebase/remote_config_service.dart)
`RemoteConfigService` kế thừa `ChangeNotifier` để khi gọi `fetchAndActivate()`, mọi màn hình đang lắng nghe sẽ tự động vẽ lại giao diện ngay lập tức:

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService extends ChangeNotifier {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero, // Fetch tức thì không bị cache khi demo
        ),
      );

      await _remoteConfig.setDefaults(const {
        'ktx_promo_banner_enabled': true,
        'ktx_promo_banner_text':
            'Đồng giá ship 5.000đ giao thẳng tới Trụ A1–A2 (Cổng B2) & Khu A.',
        'ktx_group_ship_fee': 5000,
      });

      await fetchAndActivate();
    } catch (e) {
      debugPrint('RemoteConfig initialize error: $e');
    }
  }

  Future<bool> fetchAndActivate() async {
    if (kIsWeb) return false;
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      notifyListeners();
      return updated;
    } catch (e) {
      return false;
    }
  }

  bool get promoBannerEnabled =>
      kIsWeb ? true : _remoteConfig.getBool('ktx_promo_banner_enabled');

  String get promoBannerText {
    if (kIsWeb) return 'Đồng giá ship 5.000đ giao thẳng tới Trụ A1–A2 (Cổng B2) & Khu A.';
    final text = _remoteConfig.getString('ktx_promo_banner_text');
    return text.isNotEmpty
        ? text
        : 'Đồng giá ship 5.000đ giao thẳng tới Trụ A1–A2 (Cổng B2) & Khu A.';
  }

  int get groupShipFee {
    if (kIsWeb) return 5000;
    final fee = _remoteConfig.getInt('ktx_group_ship_fee');
    return fee > 0 ? fee : 5000;
  }
}
```

### 4.3. 4 vị trí áp dụng `RemoteConfigService` trong Project

1. **[`lib/main.dart`](./lib/main.dart)**:
   - Khởi tạo trong `main()` trước khi `runApp`:
     ```dart
     final remoteConfigService = RemoteConfigService();
     await remoteConfigService.initialize();
     runApp(AppBootstrap(remoteConfigService: remoteConfigService));
     ```
   - Đưa vào `MultiProvider`:
     ```dart
     ChangeNotifierProvider<RemoteConfigService>.value(value: remoteConfigService),
     ```

2. **[`lib/screens/home_screen.dart`](./lib/screens/home_screen.dart) (Thay đổi giao diện Trang chủ S1)**:
   - Lắng nghe `final remoteConfig = context.watch<RemoteConfigService>();`.
   - Ẩn/Hiện và đổi nội dung Banner theo cấu hình từ Server:
     ```dart
     if (remoteConfig.promoBannerEnabled)
       _buildPromoBanner(remoteConfig.promoBannerText),
     ```
   - Khi vuốt xuống làm mới trang (Pull-to-Refresh), tự động gọi `fetchAndActivate()` để kéo cấu hình mới về.

3. **[`lib/screens/group_cart_checkout_screen.dart`](./lib/screens/group_cart_checkout_screen.dart) & [`lib/viewmodels/cart_checkout_vm.dart`](./lib/viewmodels/cart_checkout_vm.dart) (Thay đổi logic tính tiền S4)**:
   - Khi mở giỏ hàng, `initState` lấy `remoteConfig.groupShipFee.toDouble()` cập nhật vào `cartVm.updateDeliveryFee(...)`. Nếu đổi phí ship trên Firebase Console từ `5000` thành `10000`, tổng tiền đơn hàng tự động tăng tương ứng.

4. **[`lib/screens/profile_settings_screen.dart`](./lib/screens/profile_settings_screen.dart) (Bảng điều khiển S13)**:
   - Hiển thị trực tiếp trạng thái hiện tại của cả 3 tham số (`promoBannerEnabled`, `groupShipFee`, `promoBannerText`).
   - Có nút **[Fetch & Activate]** để bấm kéo dữ liệu mới từ Firebase Console ngay lập tức.

### 4.4. Các bước cấu hình trên Firebase Console & Kiểm thử

1. Vào **Firebase Console** ➔ **Run** (hoặc **Engage**) ➔ **Remote Config**.
2. Bấm **Create configuration** / **Add parameter** và tạo đúng tên khóa:
   - **Tham số 1**:
     - Parameter name (Key): `ktx_promo_banner_enabled`
     - Data type: `Boolean`
     - Default value: `false` *(thử tắt banner)* hoặc `true`
   - **Tham số 2**:
     - Parameter name (Key): `ktx_promo_banner_text`
     - Data type: `String`
     - Default value: `🔥 Siêu sale KTX Khu B: Miễn phí ship mọi khung giờ!`
   - **Tham số 3 (Tùy chọn thêm)**:
     - Parameter name (Key): `ktx_group_ship_fee`
     - Data type: `Number`
     - Default value: `8000`
3. Nhấn **Save** ➔ Bấm nút **Publish changes** (góc trên bên phải) để phát hành cấu hình.
4. Quay lại máy ảo Android:
   - Vào tab **Hồ sơ (S13)** ➔ Bấm nút **[Fetch & Activate]** (hoặc ở Trang chủ S1 vuốt từ trên xuống để Refresh).
   - Quan sát giao diện Banner ở Trang chủ S1 và thông số ở S13 lập tức thay đổi theo đúng giá trị bạn vừa sửa trên web mà không cần build lại app!

---

## 5. Phần 4: Cấu Hình & Áp Dụng Cloud Messaging (FCM) & Điều Hướng

### 5.1. Yêu cầu kỹ thuật của Bước 5
1. **Xin cấp quyền thông báo** trên Android 13+ (`POST_NOTIFICATIONS` + `requestPermission`).
2. **Xử lý nhận thông báo ở cả 3 trạng thái ứng dụng**:
   - **Foreground**: App đang mở trên màn hình.
   - **Background**: App đang ẩn dưới nền, người dùng nhấn vào thông báo trên thanh trạng thái.
   - **Terminated**: App đã bị đóng hoàn toàn, người dùng nhấn vào thông báo để khởi động lại app.
3. **Lưu danh sách thông báo đã nhận trong ứng dụng** (tại màn hình Trung tâm thông báo S12) để người dùng nhấn vào **chuyển hướng sang màn hình tương ứng** (`LiveOrderTrackingScreen` S6 hoặc `DisputeHistoryScreen` S8b).

---

### 5.2. Mã nguồn [`lib/firebase/fcm_service.dart`](./lib/firebase/fcm_service.dart)

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

// Top-level function bắt buộc có @pragma('vm:entry-point') để chạy khi app ở Background / Terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📩 [FCM Background Handler] Nhận thông báo ngầm: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _fcmToken;
  String _permissionStatus = 'Chưa kiểm tra';

  String? get fcmToken => _fcmToken;
  String get permissionStatus => _permissionStatus;

  Future<String?> initialize({
    required void Function(RemoteMessage message, String appState)
        onMessageReceived,
    required void Function(RemoteMessage message, String appState)
        onNotificationTapped,
  }) async {
    if (kIsWeb) return null;

    try {
      // 1. Xin cấp quyền thông báo (bắt buộc từ Android 13 / API 33+)
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _permissionStatus = settings.authorizationStatus.name;

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Đăng ký nhận thông báo chung theo topic gom đơn KTX
        await _messaging.subscribeToTopic('ktx_group_orders');
      }

      // Cho phép hiển thị cảnh báo ngay cả khi đang mở app
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Trạng thái 1: FOREGROUND (Ứng dụng đang mở trực tiếp trên màn hình)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        onMessageReceived(message, 'FOREGROUND');
      });

      // 3. Trạng thái 2: BACKGROUND (Ứng dụng chạy ngầm, người dùng nhấn vào thông báo trên thanh trạng thái)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onNotificationTapped(message, 'BACKGROUND');
      });

      // 4. Trạng thái 3: TERMINATED (Ứng dụng đã bị đóng hẳn, người dùng nhấn vào thông báo để khởi động app)
      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onNotificationTapped(initialMessage, 'TERMINATED');
      }

      // 5. Lấy FCM Registration Token để test gửi từ Firebase Console
      _fcmToken = await _messaging.getToken();
      debugPrint('🔑 [FCM TOKEN]: $_fcmToken');
      return _fcmToken;
    } catch (e) {
      debugPrint('⚠️ Lỗi khởi tạo FCM: $e');
      return null;
    }
  }
}
```

---

### 5.3. Chi tiết 4 vị trí áp dụng `FcmService` & Điều hướng trong Project

#### 1. Khởi tạo & lắng nghe 3 trạng thái tại [`lib/main.dart`](./lib/main.dart)
- **Trong hàm `main()`**: Đăng ký hàm xử lý chạy ngầm trước khi chạy app:
  ```dart
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // ...
  }
  ```
- **Trong `MultiProvider`**: Đăng ký `Provider<FcmService>(create: (_) => FcmService())`.
- **Trong `_MainShellScreenState.initState()`**: Gọi `_setupFcmListeners()` ngay khi vào màn hình chính:
  - Khi nhận tin ở **Foreground** (`onMessageReceived`):
    1. Lưu ngay thông báo vào danh sách trong app thông qua `demoVm.recordIncomingFcmMessage(...)`.
    2. Bật `SnackBar` nổi hiển thị tiêu đề + nội dung kèm nút bấm **[Xem ngay]**. Khi người dùng bấm **[Xem ngay]**, đánh dấu đã đọc và gọi `NotificationBoardScreen.navigateByNotificationType(...)` để nhảy tới màn hình tương ứng.
  - Khi người dùng chạm vào thông báo ở **Background** hoặc **Terminated** (`onNotificationTapped`):
    1. Lưu thông báo vào danh sách trong app với nhãn `[BACKGROUND]` hoặc `[TERMINATED]`.
    2. Tự động gọi `NotificationBoardScreen.navigateByNotificationType(...)` để chuyển thẳng vào màn hình chi tiết đơn hàng hoặc khiếu nại.

#### 2. Lưu trữ danh sách thông báo trong app tại [`lib/viewmodels/profile_demo_vm.dart`](./lib/viewmodels/profile_demo_vm.dart)
- Quản lý danh sách `_inAppFcmNotifications` chứa các thông báo FCM đã nhận trong phiên làm việc.
- Hàm `recordIncomingFcmMessage(...)` tạo đối tượng `NotificationModel` mới, chèn lên đầu danh sách (`insert(0, newNoti)`), tăng số lượng thông báo chưa đọc (`unreadCount` hiển thị chấm đỏ trên thanh AppBar và BottomNavBar), đồng thời cập nhật lại `notificationsState`.

#### 3. Hiển thị danh sách & Nhấn để chuyển hướng màn hình tại [`lib/screens/notification_board_screen.dart`](./lib/screens/notification_board_screen.dart)
- Hiển thị toàn bộ thông báo đã lưu tại tab **Trung tâm Thông báo S12**.
- Cung cấp hàm điều hướng tĩnh dùng chung cho cả sự kiện chạm trong danh sách S12 lẫn sự kiện chạm từ thanh thông báo hệ thống:
  ```dart
  static void navigateByNotificationType(
    BuildContext context, {
    required String type,
    String? dataPayload,
  }) {
    if (type == 'DISPUTE_UPDATE') {
      // Chuyển hướng sang Màn hình Lịch sử Khiếu nại S8b
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DisputeHistoryScreen()),
      );
      return;
    }

    // Mặc định (ORDER_STATUS): Chuyển hướng sang Màn hình Theo dõi đơn hàng trực tiếp S6
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveOrderTrackingScreen(initialOrder: demoOrder),
      ),
    );
  }
  ```
- Trên mỗi thẻ thông báo ở S12 đều có nhãn chỉ dẫn rõ ràng:
  - `👉 Theo dõi đơn (S6)` (đối với thông báo đơn hàng `ORDER_STATUS`).
  - `👉 Xem Khiếu nại (S8b)` (đối với thông báo khiếu nại `DISPUTE_UPDATE`).

#### 4. Công cụ Copy FCM Token & Test nhanh tại [`lib/screens/profile_settings_screen.dart`](./lib/screens/profile_settings_screen.dart)
Tại khu vực **Firebase Demo & Testing (S13)**:
- Hiển thị trạng thái quyền thông báo (`authorized`) và chuỗi **FCM Token** của máy ảo kèm nút bấm **[Copy Token]** (lưu thẳng vào Clipboard).
- Cung cấp 2 nút giả lập nhận thông báo tức thì:
  - **[Test FCM Đơn hàng (S6)]**: Tạo thông báo `ORDER_STATUS`, lưu vào danh sách S12 và hiện nút mở nhanh màn hình S6.
  - **[Test FCM Khiếu nại (S8b)]**: Tạo thông báo `DISPUTE_UPDATE`, lưu vào danh sách S12 và hiện nút mở nhanh màn hình S8b.

---

### 5.4. Hướng dẫn kiểm thử FCM từng bước (Cả In-App và từ Firebase Console)

#### Cách 1: Kiểm thử nhanh ngay trong ứng dụng (5 giây)
1. Đăng nhập vào app ➔ Bấm **Allow (Cho phép)** khi hộp thoại xin quyền thông báo của Android 13+ hiện lên.
2. Vào tab **Hồ sơ (S13)** ➔ Kéo xuống mục **Firebase Cloud Messaging (FCM)**:
   - Bấm **[Test FCM Đơn hàng (S6)]** và **[Test FCM Khiếu nại (S8b)]**.
3. Chuyển sang tab **Thông báo (S12)** ở thanh điều hướng dưới cùng:
   - Bạn sẽ thấy cả 2 thông báo vừa nhận đã được lưu vào đầu danh sách.
   - Bấm vào thông báo thứ nhất ➔ App chuyển ngay sang màn hình **Theo dõi đơn hàng S6**.
   - Quay lại S12, bấm vào thông báo thứ hai ➔ App chuyển ngay sang màn hình **Lịch sử Khiếu nại S8b**.

#### Cách 2: Gửi thông báo đẩy thật từ Firebase Console cho cả 3 trạng thái (Foreground, Background, Terminated)
1. **Lấy FCM Token của máy ảo**:
   - Mở tab **Hồ sơ (S13)** trên máy ảo ➔ Nhấn vào biểu tượng **Copy** (`📋`) bên cạnh dòng `FCM Token`.
   - *(Hoặc xem trong cửa sổ Terminal chạy `flutter run` sẽ thấy dòng chữ `🔑 [FCM TOKEN]: ...`)*.
2. **Mở công cụ gửi tin trên Firebase Console**:
   - Truy cập **Firebase Console** ➔ Chọn project **prm323-lab3** ➔ Menu bên trái chọn **Run** (hoặc **Engage**) ➔ **Messaging**.
   - Bấm **Create your first campaign** (hoặc **New campaign**) ➔ Chọn **Firebase Notification messages** ➔ Bấm **Create**.
3. **Điền nội dung thông báo**:
   - **Notification title**: `Shipper đã tới Cổng B2 KTX!`
   - **Notification text**: `Đơn gom ca trưa đã tới Trụ A1-A2. Nhấn để mở mã QR nhận món.`
4. **Thực hiện bắn thử tới thiết bị (Send test message)**:
   - Bấm nút **Send test message** ở khung bên phải.
   - Dán chuỗi **FCM Token** vừa copy vào ô *Add an FCM registration token* ➔ Bấm dấu **`+`** ➔ Tích chọn token đó.
   - **Kịch bản 1 — Test trạng thái FOREGROUND**:
     - Để ứng dụng đang mở sẵn trên màn hình máy ảo ➔ Bấm nút **Test** trên Firebase Console.
     - Trên máy ảo lập tức xuất hiện `SnackBar` nổi `[FOREGROUND] Shipper đã tới Cổng B2 KTX!` kèm nút **[Xem ngay]** và thông báo được tự động lưu vào tab S12.
   - **Kịch bản 2 — Test trạng thái BACKGROUND**:
     - Bấm nút **Home** trên máy ảo để ẩn ứng dụng xuống nền.
     - Quay lại Firebase Console lặp lại bước **Send test message** ➔ Bấm **Test**.
     - Trên thanh trạng thái của máy ảo xuất hiện thông báo đẩy của hệ thống Android ➔ Kéo thanh thông báo xuống và **nhấn vào thông báo** ➔ Ứng dụng tự mở lên, lưu thông báo với nhãn `[BACKGROUND]` vào S12 và chuyển thẳng tới màn hình **Theo dõi đơn hàng S6**.
   - **Kịch bản 3 — Test trạng thái TERMINATED**:
     - Vuốt đóng hẳn ứng dụng khỏi danh sách đa nhiệm (Recent Apps) trên máy ảo.
     - Gửi thêm 1 tin từ **Send test message** trên Firebase Console.
     - Nhấn vào thông báo xuất hiện trên màn hình máy ảo ➔ Ứng dụng khởi động lại từ đầu, `getInitialMessage()` bắt được thông báo, lưu với nhãn `[TERMINATED]` vào S12 và điều hướng thẳng tới màn hình tương ứng!
   - *(Mẹo nâng cao: Nếu muốn thông báo từ Console mở màn hình Khiếu nại S8b, ở bước **Additional options (Tùy chọn bổ sung)** trên Firebase Console, mục **Custom data**, thêm Key: `type` và Value: `DISPUTE_UPDATE` rồi Publish gửi tới Topic `ktx_group_orders`)*.

---

## 6. Checklist Đánh Giá & Minh Chứng Cần Chụp Nộp Bài

| STT | Hạng mục | Yêu cầu cần đạt | File liên quan (Đường dẫn động) | Cách lấy minh chứng nộp bài |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Analytics Plan** | Có file kế hoạch $\ge$ 7 sự kiện, chuẩn `snake_case`, không chứa PII. | [`docs/analytics-plan.md`](./docs/analytics-plan.md) | Đã có sẵn trong source code nộp trên GitHub. |
| **2** | **Analytics DebugView** | Hiển thị đủ 8 sự kiện trên Firebase DebugView. | [`lib/firebase/analytics_service.dart`](./lib/firebase/analytics_service.dart) | Chạy lệnh `adb shell setprop...`, bấm nút **[Bắn 8 Sự Kiện]** ở S13, chụp ảnh màn hình DebugView có đủ 8 sự kiện ở cột **TOP EVENTS**. |
| **3** | **Crashlytics Non-Fatal & Fatal** | Có ít nhất 1 lỗi Non-Fatal, 1 lỗi Test Crash, kèm User ID và Custom Key. | [`lib/firebase/crashlytics_service.dart`](./lib/firebase/crashlytics_service.dart) | Đăng nhập Google ➔ Vào S13 bấm **[Ghi Log]** và **[Crash App]** ➔ Mở lại app ➔ Chụp ảnh Crashlytics Dashboard hiển thị cả 2 lỗi + tab **Keys** + **User ID**. |
| **4** | **Remote Config** | Có $\ge$ 2 tham số thay đổi giao diện/hành vi không cần build lại app, có `setDefaults`. | [`lib/firebase/remote_config_service.dart`](./lib/firebase/remote_config_service.dart) | Tạo `ktx_promo_banner_enabled` và `ktx_promo_banner_text` trên Console ➔ Publish ➔ Bấm **[Fetch & Activate]** ở S13 ➔ Chụp ảnh Console + ảnh App trước và sau khi đổi. |
| **5** | **FCM Push Notification** | Xin quyền Android 13+, nhận ở 3 trạng thái, lưu danh sách thông báo & bấm vào chuyển màn hình. | [`lib/firebase/fcm_service.dart`](./lib/firebase/fcm_service.dart)<br>[`lib/screens/notification_board_screen.dart`](./lib/screens/notification_board_screen.dart) | Chụp ảnh hộp thoại xin quyền / màn hình danh sách thông báo S12 và màn hình S6/S8b sau khi nhấn vào thông báo. |
