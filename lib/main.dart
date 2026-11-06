import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase/analytics_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase/fcm_service.dart';
import 'firebase/remote_config_service.dart';
import 'firebase/cloud_storage_service.dart';
import 'firebase_options.dart';
import 'models/order_model.dart';
import 'models/store_model.dart';
import 'models/user_role_enum.dart';
import 'screens/cart_screen.dart';
import 'screens/dispute_refund_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/group_cart_checkout_screen.dart';
import 'screens/home_screen.dart';
import 'screens/live_order_tracking_screen.dart';
import 'screens/notification_board_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/restaurant_shell_screen.dart';
import 'screens/shipper_shell_screen.dart';
import 'screens/store_detail_screen.dart';
import 'screens/student_register_screen.dart';
import 'screens/web_admin_shell_screen.dart';
import 'services/commission_policy_service.dart';
import 'services/api_config.dart';
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
import 'widgets/ktx_sticky_cart_bar.dart';
import 'services/server_config_service.dart';
import 'widgets/server_config_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting();
    await initializeDateFormatting('vi', null);
    await initializeDateFormatting('vi_VN', null);
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('en_US', null);
  } catch (_) {}
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Tự động tải địa chỉ máy chủ lưu trước đó (hoặc mặc định VPS/Emulator)
  try {
    await ServerConfigService().loadConfig();
    await CommissionPolicyService().loadCommissionRate();
  } catch (_) {}

  // Cấu hình bắt lỗi Fatal và chuyển tiếp tới Firebase Crashlytics (chỉ áp dụng Native Android/iOS, Web không hỗ trợ Crashlytics)
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } else {
    FlutterError.onError = (errorDetails) {
      FlutterError.presentError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[Web Platform Error]: $error\n$stack');
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
        Provider<OwnerApiService>(create: (_) => OwnerApiService()),
        Provider<ShipperApiService>(create: (_) => ShipperApiService()),
        Provider<AdminApiService>(create: (_) => AdminApiService()),
        Provider<CrashlyticsService>(create: (_) => CrashlyticsService()),
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
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final savedRoleName = prefs.getString('saved_user_role');
      final savedUserId = prefs.getInt('saved_backend_user_id');

      if (isLoggedIn && savedRoleName != null) {
        if (savedUserId != null) {
          ApiConfig.currentBackendUserId = savedUserId;
        }
        final restoredRole = UserAppRole.values.firstWhere(
          (r) => r.name == savedRoleName,
          orElse: () => UserAppRole.student,
        );
        if (mounted) {
          setState(() {
            _activeRole = restoredRole;
            _manualDemoSignedIn = true;
            _isLoadingSession = false;
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _manualDemoSignedIn = false;
        _isLoadingSession = false;
      });
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
    if (_isLoadingSession) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;
        if (_manualDemoSignedIn || (firebaseUser != null && _activeRole == UserAppRole.student)) {
          // Điều hướng màn hình giao diện theo đúng vai trò đang chọn (4 Roles)
          switch (_activeRole) {
            case UserAppRole.storeOwner:
              return RestaurantShellScreen(
                ownerId: '1', // Quán Cơm Tấm Ngô Quyền của Cô Ba (Store ID: 1)
                onSignOut: _signOut,
              );
            case UserAppRole.shipper:
              return ShipperShellScreen(
                shipperId: '3',
                onSignOut: _signOut,
              );
            case UserAppRole.admin:
              return WebAdminShellScreen(
                onSignOut: _signOut,
              );
            case UserAppRole.student:
              return MainShellScreen(
                firebaseUser: firebaseUser,
                currentRole: _activeRole,
                onSignOut: _signOut,
              );
          }
        }

        return LoginScreen(
          currentRole: _activeRole,
          onRoleChanged: _onRoleChanged,
          onRegisteredOrDemoSuccess: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', true);
              await prefs.setString('saved_user_role', UserAppRole.student.name);
              await prefs.setInt('saved_backend_user_id', 1);
            } catch (_) {}
            setState(() => _manualDemoSignedIn = true);
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('saved_user_role');
      await prefs.remove('saved_backend_user_id');
    } catch (_) {}

    ApiConfig.currentBackendUserId = 1;

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
  bool _obscurePassword = true;
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleDirectLogin() async {
    final emailOrPhone = _emailPhoneController.text.trim();
    final password = _passwordController.text.trim();

    if (emailOrPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Email hoặc Số điện thoại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Mật khẩu'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authApi = context.read<AuthApiService>();
      final user = await authApi.loginWithPassword(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      ApiConfig.currentBackendUserId = user.id;

      // Xác định Role trả về từ Backend Aiven MySQL
      UserAppRole matchedRole = UserAppRole.student;
      final upperRole = user.role.toUpperCase();
      if (upperRole.contains('OWNER') || upperRole.contains('STORE')) {
        matchedRole = UserAppRole.storeOwner;
      } else if (upperRole.contains('SHIPPER')) {
        matchedRole = UserAppRole.shipper;
      } else if (upperRole.contains('ADMIN')) {
        matchedRole = UserAppRole.admin;
      } else {
        matchedRole = UserAppRole.student;
      }

      if (mounted) {
        await context.read<AuthViewModel>().syncFirebaseUser(
              uid: user.firebaseUid,
              email: user.email,
              displayName: user.displayName,
              photoUrl: user.avatarUrl,
            );
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('saved_user_role', matchedRole.name);
          await prefs.setInt('saved_backend_user_id', user.id);
        } catch (_) {}

        widget.onRoleChanged(matchedRole);
        widget.onRegisteredOrDemoSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      User? user;

      if (kIsWeb) {
        // Trên nền tảng Web: Sử dụng Firebase Auth Popup (chuẩn Google Identity Services Web)
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        try {
          final userCred = await FirebaseAuth.instance.signInWithPopup(provider);
          user = userCred.user;
        } catch (webErr) {
          debugPrint('Firebase Web Popup error: $webErr');
          try {
            final userCred = await FirebaseAuth.instance.signInWithProvider(provider);
            user = userCred.user;
          } catch (_) {}
        }

        // Nếu trên localhost:3000 chưa gắn Authorized Domain trên Firebase Console, cấp phiên Google Sinh viên KTX mượt mà
        if (user == null && mounted) {
          context.read<AnalyticsService>().logSignIn(method: 'google_web');
          await context.read<AuthViewModel>().syncFirebaseUser(
            uid: 'google-student-web-demo',
            email: 'student.google@fpt.edu.vn',
            displayName: 'Nguyễn Văn Sinh Viên (Google FPT)',
            photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
          );
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_logged_in', true);
            await prefs.setString('saved_user_role', UserAppRole.student.name);
            await prefs.setInt('saved_backend_user_id', 1);
          } catch (_) {}
          widget.onRoleChanged(UserAppRole.student);
          widget.onRegisteredOrDemoSuccess();
          return;
        }
      } else {
        // Trên Android / iOS thiết bị thật: Sử dụng Google Sign-In Native SDK
        try {
          final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
          if (account != null) {
            final GoogleSignInAuthentication googleAuth = account.authentication;
            final AuthCredential credential = GoogleAuthProvider.credential(
              idToken: googleAuth.idToken,
            );
            final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
            user = userCred.user;
          }
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) return;
          final provider = GoogleAuthProvider();
          provider.setCustomParameters({'prompt': 'select_account'});
          final userCred = await FirebaseAuth.instance.signInWithProvider(provider);
          user = userCred.user;
        } catch (e) {
          debugPrint('Native Google Sign-In error: $e');
        }
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
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('saved_user_role', UserAppRole.student.name);
          await prefs.setInt('saved_backend_user_id', 1);
        } catch (_) {}
        widget.onRoleChanged(UserAppRole.student);
        widget.onRegisteredOrDemoSuccess();
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

  /// Widget Card Đăng nhập dùng chung cho cả Mobile & Desktop
  Widget _buildLoginFormCard({required bool isWideScreen}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: EdgeInsets.all(isWideScreen ? 32 : AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWideScreen ? 24 : 16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWideScreen ? 0.06 : 0.04),
            blurRadius: isWideScreen ? 24 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWideScreen) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đăng nhập Cổng Quản Trị',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dành cho BQL, Quán ăn, Shipper & Sinh viên',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            Text('Đăng nhập tài khoản', style: AppTypography.heading3),
            const SizedBox(height: 8),
          ],
          Text(
            'Chọn nhanh tài khoản mẫu 4 vai trò:',
            style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRoleChip(
                label: '🎓 Sinh viên',
                email: 'student@fpt.edu.vn',
              ),
              _buildRoleChip(
                label: '🍲 Chủ Quán',
                email: 'coba.owner@fpt.edu.vn',
              ),
              _buildRoleChip(
                label: '🛵 Shipper',
                email: 'shipper.hung@fpt.edu.vn',
              ),
              _buildRoleChip(
                label: '🏢 Admin BQL',
                email: 'admin.ktx@fpt.edu.vn',
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailPhoneController,
            decoration: InputDecoration(
              labelText: 'Email hoặc Số điện thoại',
              hintText: 'Nhập email hoặc SĐT của bạn',
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),
          KtxButton(
            label: 'Đăng nhập ngay',
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _handleDirectLogin,
          ),
          const SizedBox(height: 12),
          KtxButton(
            label: 'Đăng nhập bằng Google (S0)',
            icon: Icons.g_mobiledata_rounded,
            variant: KtxButtonVariant.outline,
            isLoading: _isLoading,
            onPressed: _signInWithGoogle,
          ),
          const SizedBox(height: 12),
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
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip({required String label, required String email}) {
    final isSelected = _emailPhoneController.text == email;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryLight,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
        width: isSelected ? 1.5 : 1.0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) {
        setState(() {
          _emailPhoneController.text = email;
          _passwordController.text = '123456';
        });
      },
    );
  }

  /// Banner giới thiệu Portal bên trái (chỉ hiển thị trên màn hình Desktop to của Admin)
  Widget _buildDesktopHeroSection() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A), // Slate 900
            Color(0xFF1E293B), // Slate 800
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Logo & Brand
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fastfood_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KTX Food Ordering',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Dormitory Meal Logistics System',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Main Highlight Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.primary, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'PORTAL QUẢN TRỊ & ĐIỀU PHỐI KTX',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Quản lý Gom đơn & Suất ăn\nKTX Khu A / Khu B',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Nền tảng tập trung kết nối Sinh viên, Quán ăn đối tác và Đội ngũ Shipper nội khu. Tự động hóa gom đơn, đối soát chiết khấu và giám sát khiếu nại thời gian thực.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[300],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Feature Highlights
              _buildFeatureItem(
                icon: Icons.electric_moped_rounded,
                title: 'Gom đơn theo ca 5.000đ/đơn',
                desc: 'Tự động gộp đơn cùng khung giờ trưa/tối, tối ưu lộ trình toà nhà Khu A & Khu B.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.query_stats_rounded,
                title: 'Quản lý Chiết khấu & Doanh thu',
                desc: 'Admin cấu hình tỷ lệ sàn động 0% - 20%, đối soát minh bạch từng đơn hàng.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.verified_user_rounded,
                title: 'Xử lý Khiếu nại (Dispute System)',
                desc: 'Minh bạch ảnh bằng chứng giao đồ, xác thực vị trí phòng KTX và hoàn tiền.',
              ),
            ],
          ),

          // Footer info
          Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.greenAccent[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Spring Boot API • PostgreSQL Cloud • Cloudflare Tunnel Active',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 880;

    if (isWideScreen) {
      // GIAO DIỆN WEB DESKTOP / ADMIN PORTAL SANG TRỌNG
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Row(
              children: [
                // Cột trái: Hero Showcase Portal
                Expanded(
                  flex: 5,
                  child: _buildDesktopHeroSection(),
                ),
                // Cột phải: Form Đăng nhập Admin
                Expanded(
                  flex: 4,
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: _buildLoginFormCard(isWideScreen: true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Nút cấu hình Server VPS ở góc trên phải
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                tooltip: 'Cài đặt IP Máy chủ / VPS',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
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
          ],
        ),
      );
    }

    // GIAO DIỆN MOBILE NATIVE (GIỮ NGUYÊN 100% CẤU TRÚC MOBILE)
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
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
                      const SizedBox(height: AppSpacing.lg),
                      _buildLoginFormCard(isWideScreen: false),
                    ],
                  ),
                ),
              ),
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
  final VoidCallback? onSwitchRole;
  final VoidCallback onSignOut;

  const MainShellScreen({
    super.key,
    required this.firebaseUser,
    required this.currentRole,
    this.onSwitchRole,
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

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationBoardScreen()),
    );
  }

  void _openProfile() {
    setState(() => _selectedIndex = 4);
  }

  void _openCart() {
    setState(() => _selectedIndex = 2);
  }

  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupCartCheckoutScreen(
          onBackToMenu: () => Navigator.of(context).maybePop(),
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
    final cartVm = context.watch<CartCheckoutViewModel>();
    final demoVm = context.watch<ProfileDemoViewModel>();
    final homeVm = context.watch<HomeViewModel>();
    final unreadNotis = demoVm.unreadCount + homeVm.unreadNotificationCount;

    final displayName =
        user?.displayName ?? authVm.currentUser?.displayName ?? 'Sinh viên KTX';
    final email =
        user?.email ?? authVm.currentUser?.email ?? 'student@fpt.edu.vn';
    final uid =
        user?.uid ?? authVm.currentUser?.firebaseUid ?? 'student_ktx_demo';

    final pages = [
      // Tab 0: Khám phá (Trang chủ gom đơn KTX - Node 462:1932)
      HomeScreen(
        onOpenNotifications: _openNotifications,
        onOpenCheckout: _openCart,
        onOpenDispute: _openDispute,
        onOpenProfile: _openProfile,
        onSwitchRole: widget.onSwitchRole,
      ),
      // Tab 1: Đặt món (Chi tiết Quán ăn & Thực đơn - Node 438:1030)
      StoreDetailScreen(
        store: const StoreModel(
          id: 1,
          name: 'Cơm Tấm Sườn Bì KTX B2',
          description: 'Cơm tấm sườn nướng mật ong, giao gom đơn tận trụ KTX Khu B',
          address: 'Cổng B2 KTX ĐHQG TP.HCM',
          campusZone: 'KTX_KHU_B',
          phoneNumber: '0901234567',
          avatarUrl:
              'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',
          isActive: true,
          ratingAvg: 4.8,
          ratingCount: 128,
        ),
        onOpenCheckout: _openCart,
      ),
      // Tab 2: Giỏ hàng (Màn hình Giỏ Hàng xem & chọn món, topping trước khi sang Thanh toán)
      CartScreen(
        onProceedToCheckout: _openCheckout,
        onExploreMenu: () => setState(() => _selectedIndex = 1),
      ),
      // Tab 3: Lịch sử (Lịch sử đơn hàng - Node 438:3541)
      const OrderHistoryScreen(),
      // Tab 4: Tài khoản (Hồ sơ cá nhân & Cài đặt - Node 438:3979)
      ProfileSettingsScreen(
        displayName: displayName,
        email: email,
        uid: uid,
        photoUrl: user?.photoURL,
        onSwitchRole: widget.onSwitchRole,
        onSignOut: widget.onSignOut,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thanh giỏ hàng nổi bám đáy: CHỈ HIỆN Ở TRANG CHỦ (tab 0) VÀ TRANG CHỌN MÓN (tab 1)
          if (cartVm.totalItemCount > 0 && (_selectedIndex == 0 || _selectedIndex == 1))
            KtxStickyCartBar(
              itemCount: cartVm.totalItemCount,
              totalAmount: cartVm.subtotalAmount,
              pickupLocation: 'Đơn gom Cổng KTX Khu B',
              onCheckoutTap: _openCart,
            ),
          // Footer Navigation chuẩn 5 tab (Tab 2: Giỏ hàng)
          KtxBottomNavBar(
            currentIndex: _selectedIndex,
            notificationBadgeCount: unreadNotis,
            cartBadgeCount: cartVm.totalItemCount,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        ],
      ),
    );
  }
}