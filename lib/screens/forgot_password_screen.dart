import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Input phone/email, 2: New password
  final _contactController = TextEditingController(text: '0981234567');
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _authApiService = AuthApiService();

  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _contactController.dispose();
    _otpController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
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

    final res = await _authApiService.sendForgotPasswordOtp(phone);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      setState(() => _currentStep = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.terminal_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã tạo mã OTP! Hãy nhìn vào màn hình Terminal Backend để lấy mã.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
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
      setState(() => _errorMessage = 'Mã OTP phải gồm đúng 6 chữ số');
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
          content: Text(res['message'] ?? 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } else {
      setState(() => _errorMessage = res['message']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Mã OTP không chính xác hoặc đã hết hạn'),
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
            ? 'Khôi phục mật khẩu - 1'
            : 'Khôi phục mật khẩu - 2',
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
        Text('Nhập số điện thoại đăng ký KTX', style: AppTypography.heading2),
        const SizedBox(height: 6),
        Text(
          'Chúng tôi sẽ gửi mã xác thực OTP 6 số đến số điện thoại của bạn và hiển thị trực tiếp trên cửa sổ Terminal Backend.',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _contactController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại',
            prefixIcon: Icon(Icons.phone_android, color: AppColors.primary),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : KtxButton(
                label: 'Gửi mã xác thực OTP',
                onPressed: _handleSendOtp,
              ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nhập mã OTP & Mật khẩu mới', style: AppTypography.heading2),
        const SizedBox(height: 6),
        Text(
          'Mã xác thực đã gửi tới ${_contactController.text}',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        // Hộp hướng dẫn xem Terminal
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD8BF)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.terminal_rounded, color: Color(0xFFFF521B), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mã OTP 6 chữ số đang được in trên cửa sổ Terminal chạy Backend. Vui lòng nhìn Terminal để lấy mã và điền vào ô dưới.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w600,
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
            fontSize: 20,
            letterSpacing: 6,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            labelText: 'Mã xác thực OTP (6 chữ số)',
            hintText: 'Nhìn Terminal để lấy mã',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
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
