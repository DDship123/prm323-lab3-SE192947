import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'firebase/analytics_service.dart';
import 'firebase/crashlytics_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase/fcm_service.dart';
import 'firebase/remote_config_service.dart';
import 'firebase/cloud_storage_service.dart';
import 'firebase_options.dart';
import 'models/order_model.dart';
import 'screens/dispute_refund_screen.dart';
import 'screens/group_cart_checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_order_tracking_screen.dart';
import 'screens/notification_board_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/student_register_screen.dart';
import 'services/auth_api_service.dart';
import 'services/dispute_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/payment_service.dart';
import 'services/review_service.dart';
import 'services/store_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'viewmodels/auth_vm.dart';
import 'viewmodels/cart_checkout_vm.dart';
import 'viewmodels/dispute_vm.dart';
import 'viewmodels/home_vm.dart';
import 'viewmodels/order_tracking_vm.dart';
import 'viewmodels/profile_demo_vm.dart';
import 'viewmodels/review_vm.dart';
import 'viewmodels/store_detail_vm.dart';
import 'widgets/ktx_bottom_nav_bar.dart';
import 'widgets/ktx_button.dart';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    // Chuyển toàn bộ lỗi framework Flutter tới Crashlytics
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Bắt các lỗi bất đồng bộ không được xử lý
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb
        ? '119011257696-fhiv11ekbecn6gjvdi2emv6gthpm60bp.apps.googleusercontent.com'
        : null,
  );

  final remoteConfigService = RemoteConfigService();
  await remoteConfigService.initialize();

  runApp(AppBootstrap(remoteConfigService: remoteConfigService));
}

/// Khởi tạo toàn bộ Dependency Injection (Services & ViewModels) qua MultiProvider
class AppBootstrap extends StatelessWidget {
  final RemoteConfigService remoteConfigService;

  const AppBootstrap({super.key, required this.remoteConfigService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RemoteConfigService>.value(
          value: remoteConfigService,
        ),
        Provider<AnalyticsService>(create: (_) => AnalyticsService()),
        Provider<CrashlyticsService>(create: (_) => CrashlyticsService()),
        Provider<FcmService>(create: (_) => FcmService()),
        Provider<AuthApiService>(create: (_) => AuthApiService()),
        Provider<StoreService>(create: (_) => StoreService()),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<PaymentService>(create: (_) => PaymentService()),
        Provider<ReviewService>(create: (_) => ReviewService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<CloudStorageService>(create: (_) => CloudStorageService()),
        Provider<DisputeService>(create: (_) => DisputeService()),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) =>
              AuthViewModel(authApiService: ctx.read<AuthApiService>()),
        ),
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(
            storeService: ctx.read<StoreService>(),
            notificationService: ctx.read<NotificationService>(),
          ),
        ),
        ChangeNotifierProvider<StoreDetailViewModel>(
          create: (ctx) => StoreDetailViewModel(
            storeService: ctx.read<StoreService>(),
            reviewService: ctx.read<ReviewService>(),
          ),
        ),
        ChangeNotifierProvider<CartCheckoutViewModel>(
          create: (ctx) => CartCheckoutViewModel(
            orderService: ctx.read<OrderService>(),
            paymentService: ctx.read<PaymentService>(),
          ),
        ),
        ChangeNotifierProvider<OrderTrackingViewModel>(
          create: (ctx) =>
              OrderTrackingViewModel(orderService: ctx.read<OrderService>()),
        ),
        ChangeNotifierProvider<DisputeViewModel>(
          create: (ctx) => DisputeViewModel(
            cloudStorageService: ctx.read<CloudStorageService>(),
            disputeService: ctx.read<DisputeService>(),
          ),
        ),
        ChangeNotifierProvider<ReviewViewModel>(
          create: (ctx) =>
              ReviewViewModel(reviewService: ctx.read<ReviewService>()),
        ),
        ChangeNotifierProvider<ProfileDemoViewModel>(
          create: (ctx) => ProfileDemoViewModel(
            notificationService: ctx.read<NotificationService>(),
          ),
        ),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KTX Food Ordering - PRM393 Lab 3',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Điều hướng tự động theo trạng thái đăng nhập (S0 -> S1..S13)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _manualDemoSignedIn = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser != null || _manualDemoSignedIn) {
          return MainShellScreen(
            firebaseUser: firebaseUser,
            onSignOut: () async {
              try {
                await context.read<AnalyticsService>().logSignOut();
              } catch (_) {}
              setState(() => _manualDemoSignedIn = false);
              try {
                await GoogleSignIn.instance.signOut();
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
            },
          );
        }

        return LoginScreen(
          onRegisteredOrDemoSuccess: () {
            setState(() => _manualDemoSignedIn = true);
          },
        );
      },
    );
  }
}

/// Màn hình S0: Đăng nhập Google Sign-In & Đăng ký tài khoản Sinh viên KTX
class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisteredOrDemoSuccess;

  const LoginScreen({super.key, required this.onRegisteredOrDemoSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      User? user;
      try {
        final GoogleSignInAccount account = await GoogleSignIn.instance
            .authenticate();
        final GoogleSignInAuthentication googleAuth = account.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCred = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        user = userCred.user;
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) return;
        // Fallback cho máy ảo Android có Google Play Services < 24.x (bị lỗi GetSignInWithGoogleOption NPE)
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final userCred = await FirebaseAuth.instance.signInWithProvider(
          provider,
        );
        user = userCred.user;
      }

      if (user != null && mounted) {
        context.read<AnalyticsService>().logSignIn(method: 'google');
        await context.read<AuthViewModel>().syncFirebaseUser(
          uid: user.uid,
          email: user.email ?? 'student@fpt.edu.vn',
          displayName: user.displayName ?? 'Sinh viên KTX',
          photoUrl: user.photoURL,
        );
        context.read<CrashlyticsService>().setUserContext(
          userId: user.uid,
          campusZone: 'KTX_KHU_B',
          currentScreen: 'S1_Home',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng nhập: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fastfood_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'KTX Food Ordering',
                  style: AppTypography.heading1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Đặt món & Gom đơn theo Ca KTX Khu A / Khu B\n(PRM393 - Lab 3)',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                KtxButton(
                  label: 'Đăng nhập bằng Google (S0)',
                  icon: Icons.login_rounded,
                  isLoading: _isLoading,
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                KtxButton(
                  label: 'Đăng ký SĐT & Phòng KTX (S0_Reg / OTP)',
                  variant: KtxButtonVariant.outline,
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentRegisterScreen(
                          onRegisterCompleted: widget.onRegisteredOrDemoSuccess,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Khung điều hướng chính 4 Tab (S1 Trang chủ, S12 Thông báo, S10 Đơn hàng, S13 Hồ sơ)
class MainShellScreen extends StatefulWidget {
  final User? firebaseUser;
  final VoidCallback onSignOut;

  const MainShellScreen({
    super.key,
    required this.firebaseUser,
    required this.onSignOut,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFcmListeners();
      final user = widget.firebaseUser;
      if (user != null) {
        context.read<AuthViewModel>().syncFirebaseUser(
          uid: user.uid,
          email: user.email ?? 'student@fpt.edu.vn',
          displayName: user.displayName ?? 'Sinh viên KTX',
          photoUrl: user.photoURL,
        );
        context.read<CrashlyticsService>().setUserContext(
          userId: user.uid,
          campusZone: 'KTX_KHU_B',
          currentScreen: 'S1_Home',
        );
      }
    });
  }

  Future<void> _setupFcmListeners() async {
    final fcmService = context.read<FcmService>();
    final demoVm = context.read<ProfileDemoViewModel>();

    final token = await fcmService.initialize(
      onMessageReceived: (RemoteMessage message, String appState) {
        if (!mounted) return;
        final title =
            message.notification?.title ?? 'Thông báo đơn hàng KTX';
        final body = message.notification?.body ??
            'Bạn có cập nhật mới về đơn hàng gom đơn KTX.';
        final type = (message.data['type'] as String?) ?? 'ORDER_STATUS';
        final orderId = message.data['order_id']?.toString() ?? '101';

        final savedNoti = demoVm.recordIncomingFcmMessage(
          title: title,
          body: body,
          type: type,
          appState: appState,
          dataPayload: orderId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 [$appState] $title\n$body'),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Xem ngay',
              textColor: Colors.amberAccent,
              onPressed: () {
                demoVm.markAsRead(savedNoti.id);
                NotificationBoardScreen.navigateByNotificationType(
                  context,
                  type: type,
                  dataPayload: orderId,
                );
              },
            ),
          ),
        );
      },
      onNotificationTapped: (RemoteMessage message, String appState) {
        if (!mounted) return;
        final title =
            message.notification?.title ?? 'Thông báo đơn hàng KTX';
        final body = message.notification?.body ??
            'Đã mở ứng dụng từ thông báo đẩy FCM.';
        final type = (message.data['type'] as String?) ?? 'ORDER_STATUS';
        final orderId = message.data['order_id']?.toString() ?? '101';

        final savedNoti = demoVm.recordIncomingFcmMessage(
          title: title,
          body: body,
          type: type,
          appState: appState,
          dataPayload: orderId,
        );
        demoVm.markAsRead(savedNoti.id);

        NotificationBoardScreen.navigateByNotificationType(
          context,
          type: type,
          dataPayload: orderId,
        );
      },
    );

    if (mounted) {
      demoVm.updateFcmMetadata(
        token: token,
        permissionStatus: fcmService.permissionStatus,
      );
    }
  }

  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupCartCheckoutScreen(
          onOrderCompleted: (OrderDetailModel order) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LiveOrderTrackingScreen(initialOrder: order),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDispute() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DisputeRefundScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.firebaseUser;
    final authVm = context.watch<AuthViewModel>();
    final displayName =
        user?.displayName ?? authVm.currentUser?.displayName ?? 'Sinh viên KTX';
    final email =
        user?.email ?? authVm.currentUser?.email ?? 'student@fpt.edu.vn';
    final uid =
        user?.uid ?? authVm.currentUser?.firebaseUid ?? 'student_ktx_demo';

    final pages = [
      HomeScreen(
        onOpenNotifications: () => setState(() => _selectedIndex = 1),
        onOpenCheckout: _openCheckout,
        onOpenDispute: _openDispute,
      ),
      const NotificationBoardScreen(),
      const OrderHistoryScreen(),
      ProfileSettingsScreen(
        displayName: displayName,
        email: email,
        uid: uid,
        photoUrl: user?.photoURL,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: KtxBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
