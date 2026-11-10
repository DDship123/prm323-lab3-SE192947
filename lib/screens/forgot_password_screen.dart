import 'dart:async';
import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

/// Màn hình khôi phục mật khẩu tích hợp Backend Java Spring Boot OTP Terminal
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Input phone, 2: Enter OTP & New password
  final _contactController = TextEditingController(text: '0968097907');
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authApiService = AuthApiService();

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

    // Gọi trực tiếp Spring Boot Backend để sinh mã OTP và in ra Terminal VPS
    final res = await _authApiService.sendForgotPasswordOtp(phone);

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
              const Icon(Icons.terminal_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '📟 Đã tạo mã OTP cho số $phone! Mã đã in ra Terminal máy chủ VPS.',
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
      setState(() => _errorMessage = res['message'] ?? 'Không thể gửi mã OTP');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Không thể gửi mã OTP'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResetPassword() async {
    final phone = _contactController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Mã xác thực OTP phải gồm đúng 6 chữ số');
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

    // Cập nhật mật khẩu mới trực tiếp vào Backend Java Spring Boot & MySQL
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
      setState(() => _errorMessage = res['message'] ?? 'Mã xác thực không chính xác hoặc đã hết hạn');
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
            ? 'Khôi phục mật khẩu (OTP Terminal)'
            : 'Xác thực OTP & Đổi mật khẩu',
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
              child: const Icon(Icons.terminal_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xác thực qua Máy chủ Backend', style: AppTypography.heading2),
                  const SizedBox(height: 2),
                  const Text(
                    'Cơ chế mã xác thực OTP Java Spring Boot Console',
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
              Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Khi bấm "Gửi mã xác thực OTP", máy chủ Backend sẽ sinh mã OTP ngẫu nhiên 6 chữ số và in trực tiếp ra Terminal / VPS Console. Bạn có thể mở Terminal VPS lấy mã hoặc dùng mã test nhanh 123456.',
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
            labelText: 'Số điện thoại tài khoản KTX',
            hintText: 'Ví dụ: 0968097907',
            prefixIcon: Icon(Icons.phone_android, color: AppColors.primary),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : KtxButton(
                label: 'Gửi mã xác thực OTP (Terminal)',
                icon: Icons.send_rounded,
                onPressed: _handleSendOtp,
              ),
      ],
    );
  }

  Widget _buildStep2() {
    final phone = _contactController.text.trim();

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
                  Text('Nhập mã OTP & Mật khẩu mới', style: AppTypography.heading2),
                  const SizedBox(height: 2),
                  Text(
                    'Đã in mã xác thực cho số $phone ra Terminal VPS',
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
                  'Mã xác thực OTP đã xuất hiện trên màn hình Terminal của máy chủ VPS! Hãy kiểm tra Terminal hoặc dùng mã demo 123456.',
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
            labelText: 'Mã xác thực OTP (6 chữ số)',
            hintText: 'Nhập mã từ Terminal máy chủ',
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
                  'Gửi lại mã OTP',
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
