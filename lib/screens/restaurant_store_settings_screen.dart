import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/store_bank_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class RestaurantStoreSettingsScreen extends StatefulWidget {
  final String ownerId;
  final VoidCallback? onSignOut;

  const RestaurantStoreSettingsScreen({
    super.key,
    required this.ownerId,
    this.onSignOut,
  });

  @override
  State<RestaurantStoreSettingsScreen> createState() => _RestaurantStoreSettingsScreenState();
}

class _RestaurantStoreSettingsScreenState extends State<RestaurantStoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Cơm Tấm Cô Ba - ĐHQG');
  final _addressController = TextEditingController(text: 'Cổng B2 KTX ĐHQG, Phường Đông Hòa, Dĩ An');
  final _phoneController = TextEditingController(text: '0908888999');
  final _hoursController = TextEditingController(text: '06:30 - 21:00');
  bool _isOpen = true;
  bool _serveZoneA = true;
  bool _serveZoneB = true;

  // Cấu hình thanh toán VietQR / SePay ngân hàng của Quán
  final StoreBankService _bankService = StoreBankService();
  late String _selectedBankCode;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountNameController;

  @override
  void initState() {
    super.initState();
    _selectedBankCode = _bankService.bankCode;
    _accountNumberController = TextEditingController(text: _bankService.accountNumber);
    _accountNameController = TextEditingController(text: _bankService.accountName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  void _showTestQrDialog() {
    final payload = _bankService.getQrPaymentPayload(amount: 45000, transferContent: 'ORD_TEST_COBA');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        title: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Mã VietQR Thực Tế Của Quán', style: AppTypography.heading3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: AppRadius.roundedMd,
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_bankService.bankName}\nSTK: ${_accountNumberController.text}\nChủ TK: ${_accountNameController.text}',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Sinh viên có thể quét mã này bằng bất kỳ App ngân hàng nào (MB, VCB, Momo, SePay) để thanh toán trực tiếp vào tài khoản Quán!',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Thiết lập cửa hàng & VietQR'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trạng thái quán ăn', style: AppTypography.heading2),
                      Switch(
                        value: _isOpen,
                        activeColor: AppColors.success,
                        onChanged: (val) => setState(() => _isOpen = val),
                      ),
                    ],
                  ),
                  Text(
                    _isOpen ? 'Quán đang mở cửa nhận đơn gom KTX' : 'Quán tạm nghỉ không nhận đơn',
                    style: TextStyle(
                      color: _isOpen ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ================= CẤU HÌNH NGÂN HÀNG VIETQR / SEPAY =================
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Tài khoản nhận tiền VietQR / SePay', style: AppTypography.heading3),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Kiểm tra mã QR Quán',
                        icon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                        onPressed: _showTestQrDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tiền thanh toán từ sinh viên sẽ được chuyển tự động vào tài khoản ngân hàng của quán thông qua mã VietQR Napas 247 thật.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  DropdownButtonFormField<String>(
                    value: _selectedBankCode,
                    decoration: const InputDecoration(
                      labelText: 'Ngân hàng thụ hưởng',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: StoreBankService.supportedBanks.map((b) {
                      return DropdownMenuItem(
                        value: b.code,
                        child: Text('${b.code} - ${b.name}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBankCode = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản ngân hàng',
                      hintText: 'Nhập số tài khoản của quán',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.credit_card),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Không được để trống số tài khoản' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _accountNameController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản (Viết hoa không dấu)',
                      hintText: 'VD: TRAN THI BA',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Không được để trống tên chủ tài khoản' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.visibility_rounded, size: 18),
                      label: const Text('Xem trước mã QR'),
                      onPressed: _showTestQrDialog,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin cửa hàng', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên quán ăn hiển thị',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Không được để trống tên quán' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ quán',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại liên hệ chủ quán',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _hoursController,
                    decoration: const InputDecoration(
                      labelText: 'Khung giờ hoạt động',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Khu vực gom đơn phục vụ', style: AppTypography.heading2),
                  CheckboxListTile(
                    title: const Text('KTX Khu A – Cổng 1 & Cổng 2'),
                    value: _serveZoneA,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _serveZoneA = val ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('KTX Khu B – Trụ A1–A2 (Cổng B2)'),
                    value: _serveZoneB,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _serveZoneB = val ?? true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            KtxButton(
              label: 'Lưu cấu hình cửa hàng & Ngân hàng',
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _bankService.saveConfig(
                    bankCode: _selectedBankCode,
                    accountNumber: _accountNumberController.text.trim(),
                    accountName: _accountNameController.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật thông tin cửa hàng & tài khoản ngân hàng VietQR thành công!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.onSignOut != null)
              KtxButton(
                label: 'Đăng xuất tài khoản Quán ăn',
                icon: Icons.logout_rounded,
                variant: KtxButtonVariant.outline,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xác nhận đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Quán không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Ở lại'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                          onPressed: () {
                            Navigator.pop(ctx);
                            widget.onSignOut?.call();
                          },
                          child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
