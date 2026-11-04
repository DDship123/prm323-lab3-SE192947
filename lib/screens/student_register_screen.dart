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
import 'otp_verification_screen.dart';

/// Màn hình S0_Reg: Đăng ký thông tin tài khoản Sinh viên KTX
class StudentRegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterCompleted;

  const StudentRegisterScreen({
    super.key,
    required this.onRegisterCompleted,
  });

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _roomCtrl = TextEditingController(text: '312');
  String _selectedBuilding = 'Khu B - Tòa BA1';

  static const _buildings = [
    'Khu B - Tòa BA1',
    'Khu B - Tòa BA2',
    'Khu A - Tòa A3',
    'Khu A - Tòa A5',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final authVm = context.read<AuthViewModel>();
    final ok = await authVm.registerStudent(
      email: _emailCtrl.text,
      displayName: _nameCtrl.text,
      phone: _phoneCtrl.text,
      ktxBuilding: _selectedBuilding,
      ktxRoom: _roomCtrl.text,
    );

    if (!mounted || !ok) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: _phoneCtrl.text.trim(),
          onOtpVerified: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            widget.onRegisterCompleted();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Đăng ký Sinh viên KTX'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thông tin định danh KTX',
              style: AppTypography.heading2,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Số điện thoại của bạn được dùng để sinh mã PIN 4 số đối soát nhận hàng tại cổng KTX.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (authVm.errorMessage != null) ...[
              KtxErrorState(
                message: authVm.errorMessage!,
                isInlineBanner: true,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            KtxTextField(
              label: 'Họ và tên sinh viên *',
              hintText: 'Ví dụ: Ngô Hoàng Trường Đạt',
              controller: _nameCtrl,
              prefixIcon: Icons.badge_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            KtxTextField(
              label: 'Số điện thoại nhận đơn & OTP *',
              hintText: 'Ví dụ: 0987654321',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_android_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            KtxTextField(
              label: 'Email sinh viên (@fpt.edu.vn / @vnuhcm.edu.vn)',
              hintText: 'student@fpt.edu.vn',
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.alternate_email_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tòa nhà KTX *',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            DropdownButtonFormField<String>(
              initialValue: _selectedBuilding,
              decoration: const InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(),
              ),
              items: _buildings
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBuilding = val);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            KtxTextField(
              label: 'Số phòng KTX *',
              hintText: 'Ví dụ: 312',
              controller: _roomCtrl,
              prefixIcon: Icons.meeting_room_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            KtxButton(
              label: 'Tiếp tục nhận mã OTP',
              icon: Icons.sms_outlined,
              isLoading: authVm.isSyncing,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
