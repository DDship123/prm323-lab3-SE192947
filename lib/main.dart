import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase/cloud_storage_service.dart';
import 'firebase_options.dart';
import 'models/order_model.dart';
import 'models/user_role_enum.dart';
import 'screens/dispute_refund_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/group_cart_checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_order_tracking_screen.dart';
import 'screens/notification_board_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/restaurant_dashboard_screen.dart';
import 'screens/shipper_batch_pickup_screen.dart';
import 'screens/student_register_screen.dart';
import 'screens/web_admin_shell_screen.dart';
import 'services/admin_api_service.dart';
import 'services/auth_api_service.dart';
import 'services/crashlytics_service.dart';
import 'services/dispute_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/owner_api_service.dart';
import 'services/payment_service.dart';
import 'services/review_service.dart';
import 'services/shipper_api_service.dart';
import 'services/store_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_typography.dart';
import 'viewmodels/admin_vm.dart';
import 'viewmodels/auth_vm.dart';
import 'viewmodels/cart_checkout_vm.dart';
import 'viewmodels/dispute_vm.dart';
import 'viewmodels/home_vm.dart';
import 'viewmodels/order_tracking_vm.dart';
import 'viewmodels/owner_vm.dart';
import 'viewmodels/profile_demo_vm.dart';
import 'viewmodels/review_vm.dart';
import 'viewmodels/shipper_vm.dart';
import 'viewmodels/store_detail_vm.dart';
import 'widgets/ktx_bottom_nav_bar.dart';
import 'widgets/ktx_button.dart';
import 'widgets/role_selection_sheet.dart';
import 'services/server_config_service.dart';
import 'widgets/server_config_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('vi_VN', null);
  } catch (_) {}
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Tự động tải địa chỉ máy chủ lưu trước đó (hoặc mặc định VPS/Emulator)
  try {
    await ServerConfigService().loadConfig();
  } catch (_) {}

  // Cấu hình bắt lỗi Fatal và chuyển tiếp tới Firebase Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await GoogleSignIn.instance.initialize(
    clientId: kIsWeb
        ? '119011257696-fhiv11ekbecn6gjvdi2emv6gthpm60bp.apps.googleusercontent.com'
        : null,
  );

  runApp(const AppBootstrap());
}

/// Khởi tạo toàn bộ Dependency Injection (Services & ViewModels) qua MultiProvider
class AppBootstrap extends StatelessWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthApiService>(create: (_) => AuthApiService()),
        Provider<StoreService>(create: (_) => StoreService()),
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<PaymentService>(create: (_) => PaymentService()),
        Provider<ReviewService>(create: (_) => ReviewService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<CloudStorageService>(create: (_) => CloudStorageService()),
        Provider<DisputeService>(create: (_) => DisputeService()),
        Provider<OwnerApiService>(create: (_) => OwnerApiService()),
        Provider<ShipperApiService>(create: (_) => ShipperApiService()),
        Provider<AdminApiService>(create: (_) => AdminApiService()),
        Provider<CrashlyticsService>(create: (_) => CrashlyticsService()),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(
            authApiService: ctx.read<AuthApiService>(),
          ),
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
          create: (ctx) => OrderTrackingViewModel(
            orderService: ctx.read<OrderService>(),
          ),
        ),
        ChangeNotifierProvider<DisputeViewModel>(
          create: (ctx) => DisputeViewModel(
            cloudStorageService: ctx.read<CloudStorageService>(),
            disputeService: ctx.read<DisputeService>(),
          ),
        ),
        ChangeNotifierProvider<ReviewViewModel>(
          create: (ctx) => ReviewViewModel(
            reviewService: ctx.read<ReviewService>(),
          ),
        ),
        ChangeNotifierProvider<ProfileDemoViewModel>(
          create: (ctx) => ProfileDemoViewModel(
            notificationService: ctx.read<NotificationService>(),
            crashlyticsService: ctx.read<CrashlyticsService>(),
          ),
        ),
        ChangeNotifierProvider<OwnerViewModel>(
          create: (ctx) => OwnerViewModel(
            apiService: ctx.read<OwnerApiService>(),
          ),
        ),
        ChangeNotifierProvider<ShipperViewModel>(
          create: (ctx) => ShipperViewModel(
            apiService: ctx.read<ShipperApiService>(),
          ),
        ),
        ChangeNotifierProvider<AdminViewModel>(
          create: (ctx) => AdminViewModel(
            apiService: ctx.read<AdminApiService>(),
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

/// Điều hướng tự động theo trạng thái đăng nhập và vai trò (STUDENT, STORE_OWNER, SHIPPER, ADMIN)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _manualDemoSignedIn = false;
  UserAppRole _activeRole = UserAppRole.student;

  @override
  void initState() {
    super.initState();
    // Yêu cầu Lab 3: Web chỉ phục vụ cho Admin; khi mở trên trình duyệt Web lập tức vào Web Admin Portal
    if (kIsWeb) {
      _activeRole = UserAppRole.admin;
      _manualDemoSignedIn = true;
    }
  }

  void _onRoleChanged(UserAppRole newRole) {
    setState(() {
      _activeRole = newRole;
      _manualDemoSignedIn = true;
    });
  }

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
          // Điều hướng màn hình giao diện theo đúng vai trò đang chọn
          switch (_activeRole) {
            case UserAppRole.storeOwner:
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Góc Chủ Quán KTX'),
                  actions: [
                    IconButton(
                      tooltip: 'Đổi vai trò',
                      icon: const Icon(Icons.swap_horiz_rounded),
                      onPressed: () => _openRoleSwitcher(context),
                    ),
                    IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(Icons.logout),
                      onPressed: _signOut,
                    ),
                  ],
                ),
                body: const RestaurantDashboardScreen(ownerId: '2'),
              );
            case UserAppRole.shipper:
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Góc Tài Xế Gom KTX'),
                  actions: [
                    IconButton(
                      tooltip: 'Đổi vai trò',
                      icon: const Icon(Icons.swap_horiz_rounded),
                      onPressed: () => _openRoleSwitcher(context),
                    ),
                    IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(Icons.logout),
                      onPressed: _signOut,
                    ),
                  ],
                ),
                body: const ShipperBatchPickupScreen(shipperId: '3'),
              );
            case UserAppRole.admin:
              return WebAdminShellScreen(
                onSignOut: _signOut,
                onSwitchRole: () => _openRoleSwitcher(context),
              );
            case UserAppRole.student:
              return MainShellScreen(
                firebaseUser: firebaseUser,
                currentRole: _activeRole,
                onSwitchRole: () => _openRoleSwitcher(context),
                onSignOut: _signOut,
              );
          }
        }

        return LoginScreen(
          currentRole: _activeRole,
          onRoleChanged: _onRoleChanged,
          onRegisteredOrDemoSuccess: () {
            setState(() => _manualDemoSignedIn = true);
          },
        );
      },
    );
  }

  void _openRoleSwitcher(BuildContext context) async {
    final selected = await RoleSelectionBottomSheet.show(context, currentRole: _activeRole);
    if (selected != null) {
      _onRoleChanged(selected);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _manualDemoSignedIn = false;
      _activeRole = UserAppRole.student;
    });
    try {
      await GoogleSignIn.instance.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}

/// Màn hình S0: Đăng nhập Google Sign-In & Đăng ký tài khoản Sinh viên KTX
class LoginScreen extends StatefulWidget {
  final UserAppRole currentRole;
  final ValueChanged<UserAppRole> onRoleChanged;
  final VoidCallback onRegisteredOrDemoSuccess;

  const LoginScreen({
    super.key,
    required this.currentRole,
    required this.onRoleChanged,
    required this.onRegisteredOrDemoSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _emailPhoneController = TextEditingController(text: 'student@fpt.edu.vn');
  final _passwordController = TextEditingController(text: '123456');

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _quickLogin(UserAppRole role, String email, String name, String phone) async {
    widget.onRoleChanged(role);
    setState(() => _isLoading = true);
    try {
      final authApi = context.read<AuthApiService>();
      final user = await authApi.loginWithPassword(
        emailOrPhone: email,
        password: '123456',
      );
      if (mounted) {
        context.read<AuthViewModel>().syncFirebaseUser(
              uid: user.firebaseUid,
              email: user.email,
              displayName: user.displayName,
              photoUrl: user.avatarUrl,
            );
        widget.onRegisteredOrDemoSuccess();
      }
    } catch (_) {
      if (mounted) {
        widget.onRegisteredOrDemoSuccess();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDirectLogin() {
    final input = _emailPhoneController.text.trim().toLowerCase();
    if (input.contains('owner') || input.contains('coba')) {
      _quickLogin(UserAppRole.storeOwner, 'coba.owner@fpt.edu.vn', 'Cô Ba (Chủ Quán Cơm Tấm)', '0908888999');
    } else if (input.contains('shipper') || input.contains('hung')) {
      _quickLogin(UserAppRole.shipper, 'shipper.hung@fpt.edu.vn', 'Nguyễn Hùng (Shipper Đội Gom)', '0918765432');
    } else if (input.contains('admin')) {
      _quickLogin(UserAppRole.admin, 'admin.ktx@fpt.edu.vn', 'Ban Quản Lý KTX ĐHQG (Admin)', '0999000111');
    } else {
      _quickLogin(UserAppRole.student, input.isNotEmpty ? input : 'student@fpt.edu.vn', 'Ngô Trường Đạt (Sinh viên)', '0981234567');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      User? user;
      try {
        final GoogleSignInAccount account =
            await GoogleSignIn.instance.authenticate();
        final GoogleSignInAuthentication googleAuth = account.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCred =
            await FirebaseAuth.instance.signInWithCredential(credential);
        user = userCred.user;
      } on GoogleSignInException catch (e) {
        if (e.code == GoogleSignInExceptionCode.canceled) return;
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final userCred =
            await FirebaseAuth.instance.signInWithProvider(provider);
        user = userCred.user;
      }

      if (user != null && mounted) {
        await context.read<AuthViewModel>().syncFirebaseUser(
              uid: user.uid,
              email: user.email ?? 'student@fpt.edu.vn',
              displayName: user.displayName ?? 'Sinh viên KTX',
              photoUrl: user.photoURL,
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

  void _openServerConfigDialog() async {
    final serverService = ServerConfigService();
    final current = await serverService.loadConfig();
    if (!mounted) return;
    await ServerConfigDialog.show(
      context,
      currentConfig: current,
      onSaved: (newConfig) async {
        await serverService.saveConfig(newConfig);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật máy chủ Backend: ${newConfig.baseUrl}'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: IconButton(
                tooltip: 'Cài đặt IP Máy chủ / VPS',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.settings_ethernet_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                onPressed: _openServerConfigDialog,
              ),
            ),
            Center(
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
                const SizedBox(height: AppSpacing.md),

                // Nút chọn vai trò nhanh để demo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: InkWell(
                    onTap: () async {
                      final selected = await RoleSelectionBottomSheet.show(
                        context,
                        currentRole: widget.currentRole,
                      );
                      if (selected != null) {
                        widget.onRoleChanged(selected);
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Vai trò: ${widget.currentRole.labelVi}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Đăng nhập tài khoản', style: AppTypography.heading3),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Email hoặc Số điện thoại',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline, size: 20),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      KtxButton(
                        label: 'Đăng nhập ngay',
                        icon: Icons.login_rounded,
                        onPressed: _handleDirectLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('HOẶC VÀO NHANH 1-CHẠM THEO VAI TRÒ',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        title: 'Sinh viên',
                        account: 'student@fpt.edu.vn',
                        icon: Icons.school_rounded,
                        color: AppColors.primary,
                        onTap: () => _quickLogin(
                          UserAppRole.student,
                          'student@fpt.edu.vn',
                          'Ngô Trường Đạt (Sinh viên)',
                          '0981234567',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleCard(
                        title: 'Chủ quán',
                        account: 'coba.owner@fpt.edu.vn',
                        icon: Icons.restaurant_rounded,
                        color: Colors.deepOrange,
                        onTap: () => _quickLogin(
                          UserAppRole.storeOwner,
                          'coba.owner@fpt.edu.vn',
                          'Cô Ba (Chủ Quán Cơm Tấm)',
                          '0908888999',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        title: 'Shipper KTX',
                        account: 'shipper.hung@fpt.edu.vn',
                        icon: Icons.two_wheeler_rounded,
                        color: Colors.teal,
                        onTap: () => _quickLogin(
                          UserAppRole.shipper,
                          'shipper.hung@fpt.edu.vn',
                          'Nguyễn Hùng (Shipper Đội Gom)',
                          '0918765432',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRoleCard(
                        title: 'Quản trị (Admin)',
                        account: 'admin.ktx@fpt.edu.vn',
                        icon: Icons.admin_panel_settings_rounded,
                        color: Colors.indigo,
                        onTap: () => _quickLogin(
                          UserAppRole.admin,
                          'admin.ktx@fpt.edu.vn',
                          'Ban Quản Lý KTX ĐHQG (Admin)',
                          '0999000111',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                KtxButton(
                  label: 'Đăng nhập bằng Google (S0)',
                  icon: Icons.login_rounded,
                  variant: KtxButtonVariant.outline,
                  isLoading: _isLoading,
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StudentRegisterScreen(
                              onRegisterCompleted: widget.onRegisteredOrDemoSuccess,
                            ),
                          ),
                        );
                      },
                      child: const Text('Đăng ký tài khoản mới', style: TextStyle(fontSize: 12)),
                    ),
                    const Text('•', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);
  }

  Widget _buildRoleCard({
    required String title,
    required String account,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              account,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'MK: 123456 • Chạm để vào',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung điều hướng chính 4 Tab (S1 Trang chủ, S12 Thông báo, S10 Đơn hàng, S13 Hồ sơ)
class MainShellScreen extends StatefulWidget {
  final User? firebaseUser;
  final UserAppRole currentRole;
  final VoidCallback onSwitchRole;
  final VoidCallback onSignOut;

  const MainShellScreen({
    super.key,
    required this.firebaseUser,
    required this.currentRole,
    required this.onSwitchRole,
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
      final user = widget.firebaseUser;
      if (user != null) {
        context.read<AuthViewModel>().syncFirebaseUser(
              uid: user.uid,
              email: user.email ?? 'student@fpt.edu.vn',
              displayName: user.displayName ?? 'Sinh viên KTX',
              photoUrl: user.photoURL,
            );
      }
    });
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DisputeRefundScreen(),
      ),
    );
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
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: KtxBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}