import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_text_field.dart';

/// Màn hình S0_OTP: Xác thực mã OTP 6 chữ số
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onOtpVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onOtpVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpCtrl = TextEditingController(text: '123456');

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _verify() {
    final authVm = context.read<AuthViewModel>();
    if (authVm.verifyOtp(_otpCtrl.text)) {
      widget.onOtpVerified();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Xác thực OTP'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.mark_chat_read_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nhập mã xác thực 6 số',
              style: AppTypography.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Mã OTP đã được gửi tới số điện thoại ${widget.phoneNumber}.\n(Mã mặc định phục vụ chấm bài: 123456)',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (authVm.errorMessage != null) ...[
              KtxErrorState(
                message: authVm.errorMessage!,
                isInlineBanner: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            KtxTextField(
              label: 'Mã OTP (6 chữ số)',
              hintText: '123456',
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.lock_clock_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            KtxButton(
              label: 'Xác nhận & Hoàn tất',
              icon: Icons.verified_user_outlined,
              onPressed: _verify,
            ),
          ],
        ),
      ),
    );
  }
}
