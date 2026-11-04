import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/shipper_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import 'shipper_withdraw_success_screen.dart';

class ShipperWithdrawConfirmScreen extends StatefulWidget {
  final String shipperId;
  final double maxBalance;

  const ShipperWithdrawConfirmScreen({
    super.key,
    required this.shipperId,
    required this.maxBalance,
  });

  @override
  State<ShipperWithdrawConfirmScreen> createState() => _ShipperWithdrawConfirmScreenState();
}

class _ShipperWithdrawConfirmScreenState extends State<ShipperWithdrawConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: '200000');
  final _bankNameController = TextEditingController(text: 'Vietcombank (VCB)');
  final _accountNumberController = TextEditingController(text: '1012345678');
  final _holderNameController = TextEditingController(text: 'NGO HOANG TRUONG DAT');
  bool _isLoading = false;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  Future<void> _handleWithdraw() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > widget.maxBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền rút không được vượt quá số dư khả dụng')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await context.read<ShipperViewModel>().withdrawEarnings(
          amount: amount,
          bankName: _bankNameController.text,
          bankAccountNumber: _accountNumberController.text,
          accountHolderName: _holderNameController.text,
          shipperId: widget.shipperId,
        );
    setState(() => _isLoading = false);

    if (mounted && success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShipperWithdrawSuccessScreen(
            amount: amount,
            bankName: _bankNameController.text,
            accountNumber: _accountNumberController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Xác nhận rút tiền thù lao'),
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
                  Text('Số dư khả dụng hiện tại', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(widget.maxBalance),
                    style: AppTypography.heading2.copyWith(color: AppColors.primary),
                  ),
                  const Divider(height: 24),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Số tiền muốn rút (VNĐ)',
                      suffixText: 'VNĐ',
                      border: const OutlineInputBorder(),
                      helperText: 'Tối thiểu 50.000đ - Miễn phí rút tiền',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '') ?? 0;
                      if (val < 50000) return 'Số tiền rút tối thiểu là 50.000đ';
                      return null;
                    },
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
                  Text('Tài khoản ngân hàng thụ hưởng', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ngân hàng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tài khoản',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _holderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên chủ tài khoản (in hoa không dấu)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            KtxButton(
              label: 'Xác nhận rút về tài khoản',
              isLoading: _isLoading,
              onPressed: _handleWithdraw,
            ),
          ],
        ),
      ),
    );
  }
}
