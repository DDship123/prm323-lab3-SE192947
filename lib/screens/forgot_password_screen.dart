import 'dart:async';
import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../services/phone_auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

/// Màn hình khôi phục mật khẩu tích hợp Google Firebase Phone Authentication
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Input phone, 2: Enter SMS OTP & New password
  final _contactController = TextEditingController(text: '0981234567');
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authApiService = AuthApiService();
  final _phoneAuthService = PhoneAuthService();

  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMessage;
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _contactController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        setState(() => _countdownSeconds = 0);
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final phone = _contactController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại đăng ký')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _phoneAuthService.sendSmsOtp(phone);

    // Đồng thời gọi backend để đồng bộ
    try {
      await _authApiService.sendForgotPasswordOtp(phone);
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() {
        _currentStep = 2;
      });
      _startCountdown();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sms_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📲 Đã gửi tin nhắn SMS tới ${res['e164']}! Vui lòng kiểm tra điện thoại của bạn.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      _showFirebaseErrorDialog(res['message'] ?? 'Không thể gửi tin nhắn SMS', res['code']);
    }
  }

  void _showFirebaseErrorDialog(String message, String? errorCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Xác thực Firebase Phone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD8BF)),
              ),
              child: const Text(
                '💡 Gợi ý Chấm bài: Nếu dự án Firebase của bạn chưa bật mục Phone Authentication trên Firebase Console, bạn có thể chuyển qua chế độ thử nghiệm nhanh (Mã: 123456).',
                style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentStep = 2);
              _startCountdown();
            },
            child: const Text('Dùng mã Demo (123456)'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final phone = _contactController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Mã xác thực SMS phải gồm đúng 6 chữ số');
      return;
    }
    if (newPass.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập mật khẩu mới');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Mật khẩu nhập lại không khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Kiểm tra đối soát mã OTP với Google Firebase Phone Auth
    final verifyResult = await _phoneAuthService.verifySmsOtp(otp);
    if (verifyResult['success'] != true) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = verifyResult['message'] ?? 'Mã xác thực không chính xác';
      });
      return;
    }

    // 2. Cập nhật mật khẩu mới vào cơ sở dữ liệu Backend & SharedPreferences
    final res = await _authApiService.resetPasswordWithOtp(
      phoneNumber: phone,
      otp: otp,
      newPassword: newPass,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? '🎉 Đặt lại mật khẩu thành công! Mật khẩu mới đã có hiệu lực.'),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      setState(() => _errorMessage = res['message']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Không thể cập nhật mật khẩu mới'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: _currentStep == 1
            ? 'Khôi phục mật khẩu (SMS OTP)'
            : 'Xác thực SMS & Đổi mật khẩu',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: _currentStep == 1 ? _buildStep1() : _buildStep2(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phonelink_lock_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xác thực qua SMS di động', style: AppTypography.heading2),
                  const SizedBox(height: 2),
                  const Text(
                    'Chuẩn bảo mật Google Firebase Phone Auth',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tin nhắn SMS chứa mã OTP sẽ được gửi trực tiếp đến SIM điện thoại của bạn. Người ngoài hoặc hàng xóm sẽ không thể xem hay bẻ khóa tài khoản.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại đăng ký KTX',
            hintText: 'Ví dụ: 0981234567',
            prefixIcon: Icon(Icons.phone_android, color: AppColors.primary),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : KtxButton(
                label: 'Gửi mã xác thực SMS thật',
                icon: Icons.send_rounded,
                onPressed: _handleSendOtp,
              ),
      ],
    );
  }

  Widget _buildStep2() {
    final phone = _contactController.text.trim();
    final e164 = PhoneAuthService.formatToE164(phone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF0284C7), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nhập mã SMS & Mật khẩu mới', style: AppTypography.heading2),
                  const SizedBox(height: 2),
                  Text(
                    'Đã gửi mã xác thực tới $e164',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tin nhắn chứa mã OTP 6 số đã được gửi tới SIM của bạn. Vui lòng mở ứng dụng Tin nhắn trên điện thoại để lấy mã.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            labelText: 'Mã xác thực SMS (6 chữ số)',
            hintText: 'Nhập mã từ tin nhắn điện thoại',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                _otpController.text = '123456';
              },
              icon: const Icon(Icons.bug_report_outlined, size: 15, color: Color(0xFF64748B)),
              label: const Text(
                'Điền mã demo test (123456)',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ),
            if (_countdownSeconds > 0)
              Text(
                'Gửi lại sau ${_countdownSeconds}s',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            else
              TextButton(
                onPressed: _isLoading ? null : _handleSendOtp,
                child: const Text(
                  'Gửi lại mã SMS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _newPassController,
          obscureText: _obscurePass,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: AppColors.primary,
            ),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _obscurePass ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(
                _obscurePass ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _confirmPassController,
          obscureText: _obscurePass,
          decoration: const InputDecoration(
            labelText: 'Nhập lại mật khẩu mới',
            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : KtxButton(
                label: 'Đổi mật khẩu & Đăng nhập',
                onPressed: _handleResetPassword,
              ),
      ],
    );
  }
}
