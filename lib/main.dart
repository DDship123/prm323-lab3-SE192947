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
import 'services/voucher_service.dart';
import 'services/delivery_handshake_service.dart';
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

  // Tá»± Ä‘á»™ng táº£i Ä‘á»‹a chá»‰ mÃ¡y chá»§ lÆ°u trÆ°á»›c Ä‘Ã³ (hoáº·c máº·c Ä‘á»‹nh VPS/Emulator)
  try {
    await ServerConfigService().loadConfig();
    await CommissionPolicyService().loadCommissionRate();
    await VoucherService().loadVouchers();
    await DeliveryHandshakeService().loadSavedData();
  } catch (_) {}

  // Cáº¥u hÃ¬nh báº¯t lá»—i Fatal vÃ  chuyá»ƒn tiáº¿p tá»›i Firebase Crashlytics (chá»‰ Ã¡p dá»¥ng Native Android/iOS, Web khÃ´ng há»— trá»£ Crashlytics)
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

/// Khá»Ÿi táº¡o toÃ n bá»™ Dependency Injection (Services & ViewModels) qua MultiProvider
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
        ChangeNotifierProvider<VoucherService>.value(
          value: VoucherService(),
        ),
        ChangeNotifierProvider<DeliveryHandshakeService>.value(
          value: DeliveryHandshakeService(),
        ),
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
          create: (ctx) =>
              OwnerViewModel(apiService: ctx.read<OwnerApiService>()),
        ),
        ChangeNotifierProvider<ShipperViewModel>(
          create: (ctx) =>
              ShipperViewModel(apiService: ctx.read<ShipperApiService>()),
        ),
        ChangeNotifierProvider<AdminViewModel>(
          create: (ctx) =>
              AdminViewModel(apiService: ctx.read<AdminApiService>()),
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

/// Äiá»u hÆ°á»›ng tá»± Ä‘á»™ng theo tráº¡ng thÃ¡i Ä‘Äƒng nháº­p vÃ  vai trÃ² (STUDENT, STORE_OWNER, SHIPPER, ADMIN)
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

  Future<void> _onRoleChanged(UserAppRole newRole) async {
    setState(() {
      _activeRole = newRole;
      _manualDemoSignedIn = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('saved_user_role', newRole.name);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        if (_manualDemoSignedIn ||
            (firebaseUser != null && _activeRole == UserAppRole.student)) {
          // Äiá»u hÆ°á»›ng mÃ n hÃ¬nh giao diá»‡n theo Ä‘Ãºng vai trÃ² Ä‘ang chá»n (4 Roles)
          switch (_activeRole) {
            case UserAppRole.storeOwner:
              return RestaurantShellScreen(ownerId: '2', onSignOut: _signOut);
              return RestaurantShellScreen(
                ownerId: '1', // QuÃ¡n CÆ¡m Táº¥m NgÃ´ Quyá»n cá»§a CÃ´ Ba (Store ID: 1)
                onSignOut: _signOut,
              );
            case UserAppRole.shipper:
              return ShipperShellScreen(shipperId: '3', onSignOut: _signOut);
            case UserAppRole.admin:
              return WebAdminShellScreen(onSignOut: _signOut);
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
              await prefs.setString(
                'saved_user_role',
                UserAppRole.student.name,
              );
              await prefs.setInt('saved_backend_user_id', 1);
            } catch (_) {}
            setState(() {
              _activeRole = UserAppRole.student;
              _manualDemoSignedIn = true;
            });
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

/// MÃ n hÃ¬nh S0: ÄÄƒng nháº­p Google Sign-In & ÄÄƒng kÃ½ tÃ i khoáº£n Sinh viÃªn KTX
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
          content: Text('Vui lÃ²ng nháº­p Email hoáº·c Sá»‘ Ä‘iá»‡n thoáº¡i'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lÃ²ng nháº­p Máº­t kháº©u'),
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

      // XÃ¡c Ä‘á»‹nh Role tráº£ vá» tá»« Backend Aiven MySQL
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ÄÄƒng nháº­p tháº¥t báº¡i: $e'),
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
        // TrÃªn ná»n táº£ng Web: Sá»­ dá»¥ng Firebase Auth Popup (chuáº©n Google Identity Services Web)
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

        // Náº¿u trÃªn localhost:3000 chÆ°a gáº¯n Authorized Domain trÃªn Firebase Console, cáº¥p phiÃªn Google Sinh viÃªn KTX mÆ°á»£t mÃ 
        if (user == null && mounted) {
          context.read<AnalyticsService>().logSignIn(method: 'google_web');
          await context.read<AuthViewModel>().syncFirebaseUser(
            uid: 'google-student-web-demo',
            email: 'student.google@fpt.edu.vn',
            displayName: 'Nguyá»…n VÄƒn Sinh ViÃªn (Google FPT)',
            photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
          );
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('is_logged_in', true);
            await prefs.setString('saved_user_role', UserAppRole.student.name);
            await prefs.setInt('saved_backend_user_id', 1);
          } catch (_) {}
          widget.onRoleChanged(UserAppRole.student);
          return;
        }
      } else {
        // TrÃªn Android / iOS thiáº¿t bá»‹ tháº­t: Sá»­ dá»¥ng Google Sign-In Native SDK
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
          displayName: user.displayName ?? 'Sinh viÃªn KTX',
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lá»—i Ä‘Äƒng nháº­p: $e'),
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
              content: Text(
                'ÄÃ£ cáº­p nháº­t mÃ¡y chá»§ Backend: ${newConfig.baseUrl}',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      },
    );
  }

  Widget _buildDemoAccountChip(
    String roleKey,
    String label,
    String semanticLabel,
    String email,
  ) {
    final isSelected = _emailPhoneController.text == email;
    void fillDemoAccount() {
      setState(() {
        _emailPhoneController.text = email;
        _passwordController.text = '123456';
      });
    }

    return Semantics(
      identifier: 'chip_role_$roleKey',
      label: semanticLabel,
      selected: isSelected,
      button: true,
      excludeSemantics: true,
      onTap: fillDemoAccount,
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        onSelected: (_) => fillDemoAccount(),
  /// Widget Card ÄÄƒng nháº­p dÃ¹ng chung cho cáº£ Mobile & Desktop
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
                        'ÄÄƒng nháº­p Cá»•ng Quáº£n Trá»‹',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'DÃ nh cho BQL, QuÃ¡n Äƒn, Shipper & Sinh viÃªn',
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
            Text('ÄÄƒng nháº­p tÃ i khoáº£n', style: AppTypography.heading3),
            const SizedBox(height: 8),
          ],
          Text(
            'Chá»n nhanh tÃ i khoáº£n máº«u 4 vai trÃ²:',
            style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRoleChip(
                label: 'ðŸŽ“ Sinh viÃªn',
                email: 'student@fpt.edu.vn',
              ),
              _buildRoleChip(
                label: 'ðŸ² Chá»§ QuÃ¡n',
                email: 'coba.owner@fpt.edu.vn',
              ),
              _buildRoleChip(
                label: 'ðŸ›µ Shipper',
                email: 'shipper.hung@fpt.edu.vn',
              ),
              _buildRoleChip(
                label: 'ðŸ¢ Admin BQL',
                email: 'admin.ktx@fpt.edu.vn',
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _emailPhoneController,
            decoration: InputDecoration(
              labelText: 'Email hoáº·c Sá»‘ Ä‘iá»‡n thoáº¡i',
              hintText: 'Nháº­p email hoáº·c SÄT cá»§a báº¡n',
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
              labelText: 'Máº­t kháº©u',
              hintText: 'Nháº­p máº­t kháº©u',
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
            label: 'ÄÄƒng nháº­p ngay',
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _handleDirectLogin,
          ),
          const SizedBox(height: 12),
          KtxButton(
            label: 'ÄÄƒng nháº­p báº±ng Google (S0)',
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
                child: const Text('ÄÄƒng kÃ½ tÃ i khoáº£n má»›i', style: TextStyle(fontSize: 12)),
              ),
              const Text('â€¢', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text(
                  'QuÃªn máº­t kháº©u?',
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

  /// Banner giá»›i thiá»‡u Portal bÃªn trÃ¡i (chá»‰ hiá»ƒn thá»‹ trÃªn mÃ n hÃ¬nh Desktop to cá»§a Admin)
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
                      'PORTAL QUáº¢N TRá»Š & ÄIá»€U PHá»I KTX',
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
                'Quáº£n lÃ½ Gom Ä‘Æ¡n & Suáº¥t Äƒn\nKTX Khu A / Khu B',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ná»n táº£ng táº­p trung káº¿t ná»‘i Sinh viÃªn, QuÃ¡n Äƒn Ä‘á»‘i tÃ¡c vÃ  Äá»™i ngÅ© Shipper ná»™i khu. Tá»± Ä‘á»™ng hÃ³a gom Ä‘Æ¡n, Ä‘á»‘i soÃ¡t chiáº¿t kháº¥u vÃ  giÃ¡m sÃ¡t khiáº¿u náº¡i thá»i gian thá»±c.',
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
                title: 'Gom Ä‘Æ¡n theo ca 5.000Ä‘/Ä‘Æ¡n',
                desc: 'Tá»± Ä‘á»™ng gá»™p Ä‘Æ¡n cÃ¹ng khung giá» trÆ°a/tá»‘i, tá»‘i Æ°u lá»™ trÃ¬nh toÃ  nhÃ  Khu A & Khu B.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.query_stats_rounded,
                title: 'Quáº£n lÃ½ Chiáº¿t kháº¥u & Doanh thu',
                desc: 'Admin cáº¥u hÃ¬nh tá»· lá»‡ sÃ n Ä‘á»™ng 0% - 20%, Ä‘á»‘i soÃ¡t minh báº¡ch tá»«ng Ä‘Æ¡n hÃ ng.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Icons.verified_user_rounded,
                title: 'Xá»­ lÃ½ Khiáº¿u náº¡i (Dispute System)',
                desc: 'Minh báº¡ch áº£nh báº±ng chá»©ng giao Ä‘á»“, xÃ¡c thá»±c vá»‹ trÃ­ phÃ²ng KTX vÃ  hoÃ n tiá»n.',
              ),
            ],
          ),

          // Footer info
          Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.greenAccent[400], size: 16),
              const SizedBox(width: 8),
              Text(
                'Spring Boot API â€¢ PostgreSQL Cloud â€¢ Cloudflare Tunnel Active',
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
      // GIAO DIá»†N WEB DESKTOP / ADMIN PORTAL SANG TRá»ŒNG
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Row(
              children: [
                // Cá»™t trÃ¡i: Hero Showcase Portal
                Expanded(
                  flex: 5,
                  child: _buildDesktopHeroSection(),
                ),
                // Cá»™t pháº£i: Form ÄÄƒng nháº­p Admin
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
            // NÃºt cáº¥u hÃ¬nh Server VPS á»Ÿ gÃ³c trÃªn pháº£i
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                tooltip: 'CÃ i Ä‘áº·t IP MÃ¡y chá»§ / VPS',
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

    // GIAO DIá»†N MOBILE NATIVE (GIá»® NGUYÃŠN 100% Cáº¤U TRÃšC MOBILE)
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              right: 12,
              child: IconButton(
                tooltip: 'CÃ i Ä‘áº·t IP MÃ¡y chá»§ / VPS',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
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
                      'Äáº·t mÃ³n & Gom Ä‘Æ¡n theo Ca KTX Khu A / Khu B\n(PRM393 - Lab 3)',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ÄÄƒng nháº­p tÃ i khoáº£n',
                            style: AppTypography.heading3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chá»n nhanh tÃ i khoáº£n máº«u 4 vai trÃ²:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildDemoAccountChip(
                                'student',
                                'ðŸŽ“ Sinh viÃªn',
                                'TÃ i khoáº£n máº«u Sinh viÃªn',
                                'student@fpt.edu.vn',
                              ),
                              _buildDemoAccountChip(
                                'owner',
                                'ðŸ² Chá»§ QuÃ¡n',
                                'TÃ i khoáº£n máº«u Chá»§ QuÃ¡n',
                                'coba.owner@fpt.edu.vn',
                              ),
                              _buildDemoAccountChip(
                                'shipper',
                                'ðŸ›µ Shipper',
                                'TÃ i khoáº£n máº«u Shipper',
                                'shipper.hung@fpt.edu.vn',
                              ),
                              _buildDemoAccountChip(
                                'admin',
                                'ðŸ¢ Admin BQL',
                                'TÃ i khoáº£n máº«u Admin BQL',
                                'admin.ktx@fpt.edu.vn',
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Semantics(
                            identifier: 'input_login_email',
                            child: TextField(
                              controller: _emailPhoneController,
                              decoration: const InputDecoration(
                                labelText: 'Email hoáº·c Sá»‘ Ä‘iá»‡n thoáº¡i',
                                hintText: 'Nháº­p email hoáº·c SÄT cá»§a báº¡n',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            identifier: 'input_login_password',
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Máº­t kháº©u',
                                hintText: 'Nháº­p máº­t kháº©u',
                                prefixIcon: Icon(Icons.lock_outline, size: 20),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          KtxButton(
                            label: 'ÄÄƒng nháº­p ngay',
                            icon: Icons.login_rounded,
                            isLoading: _isLoading,
                            onPressed: _handleDirectLogin,
                            semanticsId: 'btn_login_submit',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    KtxButton(
                      label: 'ÄÄƒng nháº­p báº±ng Google (S0)',
                      icon: Icons.login_rounded,
                      variant: KtxButtonVariant.outline,
                      isLoading: _isLoading,
                      onPressed: _signInWithGoogle,
                      semanticsId: 'btn_login_google',
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
                                  onRegisterCompleted:
                                      widget.onRegisteredOrDemoSuccess,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'ÄÄƒng kÃ½ tÃ i khoáº£n má»›i',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const Text('â€¢', style: TextStyle(color: Colors.grey)),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'QuÃªn máº­t kháº©u?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        'Äáº·t mÃ³n & Gom Ä‘Æ¡n theo Ca KTX Khu A / Khu B\n(PRM393 - Lab 3)',
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

/// Khung Ä‘iá»u hÆ°á»›ng chÃ­nh 4 Tab (S1 Trang chá»§, S12 ThÃ´ng bÃ¡o, S10 ÄÆ¡n hÃ ng, S13 Há»“ sÆ¡)
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
          displayName: user.displayName ?? 'Sinh viÃªn KTX',
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
        final title = message.notification?.title ?? 'ThÃ´ng bÃ¡o Ä‘Æ¡n hÃ ng KTX';
        final body =
            message.notification?.body ??
            'Báº¡n cÃ³ cáº­p nháº­t má»›i vá» Ä‘Æ¡n hÃ ng gom Ä‘Æ¡n KTX.';
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
            content: Text('ðŸ”” [$appState] $title\n$body'),
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
        final title = message.notification?.title ?? 'ThÃ´ng bÃ¡o Ä‘Æ¡n hÃ ng KTX';
        final body =
            message.notification?.body ??
            'ÄÃ£ má»Ÿ á»©ng dá»¥ng tá»« thÃ´ng bÃ¡o Ä‘áº©y FCM.';
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationBoardScreen()));
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
        user?.displayName ?? authVm.currentUser?.displayName ?? 'Sinh viÃªn KTX';
    final email =
        user?.email ?? authVm.currentUser?.email ?? 'student@fpt.edu.vn';
    final uid =
        user?.uid ?? authVm.currentUser?.firebaseUid ?? 'student_ktx_demo';

    final pages = [
      // Tab 0: KhÃ¡m phÃ¡ (Trang chá»§ gom Ä‘Æ¡n KTX - Node 462:1932)
      HomeScreen(
        onOpenNotifications: _openNotifications,
        onOpenCheckout: _openCart,
        onOpenDispute: _openDispute,
        onOpenProfile: _openProfile,
        onSwitchRole: widget.onSwitchRole,
      ),
      // Tab 1: Äáº·t mÃ³n (Chi tiáº¿t QuÃ¡n Äƒn & Thá»±c Ä‘Æ¡n - Node 438:1030)
      StoreDetailScreen(
        store: const StoreModel(
          id: 1,
          name: 'CÆ¡m Táº¥m SÆ°á»n BÃ¬ KTX B2',
          description:
              'CÆ¡m táº¥m sÆ°á»n nÆ°á»›ng máº­t ong, giao gom Ä‘Æ¡n táº­n trá»¥ KTX Khu B',
          address: 'Cá»•ng B2 KTX ÄHQG TP.HCM',
          campusZone: 'KTX_KHU_B',
          phoneNumber: '0901234567',
          avatarUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=600',
          isActive: true,
          ratingAvg: 4.8,
          ratingCount: 128,
        ),
        onOpenCheckout: _openCart,
      ),
      // Tab 2: Giá» hÃ ng (MÃ n hÃ¬nh Giá» HÃ ng xem & chá»n mÃ³n, topping trÆ°á»›c khi sang Thanh toÃ¡n)
      CartScreen(
        onProceedToCheckout: _openCheckout,
        onExploreMenu: () => setState(() => _selectedIndex = 1),
      ),
      // Tab 3: Lá»‹ch sá»­ (Lá»‹ch sá»­ Ä‘Æ¡n hÃ ng - Node 438:3541)
      const OrderHistoryScreen(),
      // Tab 4: TÃ i khoáº£n (Há»“ sÆ¡ cÃ¡ nhÃ¢n & CÃ i Ä‘áº·t - Node 438:3979)
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
          // Thanh giá» hÃ ng ná»•i bÃ¡m Ä‘Ã¡y: CHá»ˆ HIá»†N á»ž TRANG CHá»¦ (tab 0) VÃ€ TRANG CHá»ŒN MÃ“N (tab 1)
          if (cartVm.totalItemCount > 0 &&
              (_selectedIndex == 0 || _selectedIndex == 1))
            KtxStickyCartBar(
              itemCount: cartVm.totalItemCount,
              totalAmount: cartVm.subtotalAmount,
              pickupLocation: 'ÄÆ¡n gom Cá»•ng KTX Khu B',
              onCheckoutTap: _openCart,
            ),
          // Footer Navigation chuáº©n 5 tab (Tab 2: Giá» hÃ ng)
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
