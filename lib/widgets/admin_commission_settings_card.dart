import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/commission_policy_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'ktx_button.dart';

/// Thẻ quản lý Chính sách Chiết khấu Nền tảng KTX Food dành riêng cho Ban Quản Lý (Admin)
/// Cho phép Admin nhập số % hoa hồng sàn, tự động đồng bộ sang toàn bộ Quán ăn
class AdminCommissionSettingsCard extends StatefulWidget {
  final double totalRevenue;

  const AdminCommissionSettingsCard({
    super.key,
    this.totalRevenue = 0.0,
  });

  @override
  State<AdminCommissionSettingsCard> createState() => _AdminCommissionSettingsCardState();
}

class _AdminCommissionSettingsCardState extends State<AdminCommissionSettingsCard> {
  final TextEditingController _rateController = TextEditingController();
  final CommissionPolicyService _policyService = CommissionPolicyService();
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _policyService.loadCommissionRate().then((rate) {
      if (mounted) {
        _rateController.text = rate.toStringAsFixed(0);
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePolicy() async {
    final text = _rateController.text.trim();
    final newRate = double.tryParse(text);

    if (newRate == null || newRate < 0 || newRate > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tỷ lệ phần trăm hợp lệ (từ 0% đến 50%)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final ok = await _policyService.updateCommissionRate(newRate);
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Đã cập nhật Tỷ lệ Chiết khấu Sàn thành ${newRate.toStringAsFixed(0)}%! Quán ăn sẽ thực nhận ${(100 - newRate).toStringAsFixed(0)}%.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRate = _policyService.commissionRate;
    final storeRate = _policyService.storePayoutRate;
    final estimatedAdminRevenue = _policyService.calculatePlatformFee(widget.totalRevenue);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chính Sách Chiết Khấu Sàn KTX Food',
                        style: AppTypography.heading3.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cấu hình tỷ lệ hoa hồng nền tảng thu từ các Quán ăn khi bán đơn online',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.roundedFull,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Đang áp dụng: ${currentRate.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          // Khu vực nhập số chiết khấu & Nút lưu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tỷ lệ hoa hồng sàn (%):',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: TextField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Nhập số (VD: 10)',
                          suffixText: '%',
                          suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(borderRadius: AppRadius.roundedSm),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hành động:', style: TextStyle(fontSize: 12, color: Colors.transparent)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 44,
                      child: KtxButton(
                        label: 'Áp dụng chính sách',
                        isLoading: _isSaving,
                        onPressed: _handleSavePolicy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Tóm tắt tỷ lệ phân bổ dòng tiền
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.roundedSm,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phí sàn thu được',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentRate.toStringAsFixed(0)}% / đơn',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quán thực nhận (Net)',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${storeRate.toStringAsFixed(0)}% / đơn',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppColors.border),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ước tính hoa hồng ca này',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormatter.format(estimatedAdminRevenue),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

