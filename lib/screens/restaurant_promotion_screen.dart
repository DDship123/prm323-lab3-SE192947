import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class RestaurantPromotionScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantPromotionScreen({super.key, required this.ownerId});

  @override
  State<RestaurantPromotionScreen> createState() => _RestaurantPromotionScreenState();
}

class _RestaurantPromotionScreenState extends State<RestaurantPromotionScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final List<Map<String, dynamic>> _vouchers = [
    {
      'code': 'GOMDONKTX',
      'title': 'Hỗ trợ gom đơn KTX',
      'discount': 'Giảm 5.000đ phí gom đơn',
      'minOrder': 40000,
      'expiry': '30/11/2026',
      'isActive': true,
      'usedCount': 142,
    },
    {
      'code': 'COBATRUA',
      'title': 'Ưu đãi ca trưa Cơm Tấm',
      'discount': 'Giảm 10% (tối đa 15.000đ)',
      'minOrder': 60000,
      'expiry': '15/12/2026',
      'isActive': true,
      'usedCount': 89,
    },
    {
      'code': 'TANGBI10K',
      'title': 'Tặng bì chả cho tân sinh viên',
      'discount': 'Tặng 1 phần chả trứng',
      'minOrder': 35000,
      'expiry': '01/10/2026',
      'isActive': false,
      'usedCount': 210,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Quản lý khuyến mãi và voucher'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Khuyến mãi đang áp dụng', style: AppTypography.heading2),
              TextButton.icon(
                onPressed: _showAddPromotionDialog,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                label: const Text('Tạo mã mới', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._vouchers.map((v) => _buildVoucherCard(v)),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> v) {
    final bool isActive = v['isActive'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  v['code'] as String,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Switch(
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  setState(() => v['isActive'] = val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(v['title'] as String, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          Text(v['discount'] as String, style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đơn tối thiểu: ${currencyFormatter.format(v['minOrder'])}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              Text('Đã dùng: ${v['usedCount']} lượt',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Hạn sử dụng: ${v['expiry']}',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showAddPromotionDialog() {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final discountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo khuyến mãi mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Mã voucher (VD: CHAOSV)')),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tên khuyến mãi')),
            TextField(controller: discountCtrl, decoration: const InputDecoration(labelText: 'Mức giảm (VD: Giảm 5.000đ)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              if (codeCtrl.text.isNotEmpty) {
                setState(() {
                  _vouchers.insert(0, {
                    'code': codeCtrl.text.toUpperCase(),
                    'title': titleCtrl.text.isEmpty ? 'Khuyến mãi đặc biệt' : titleCtrl.text,
                    'discount': discountCtrl.text.isEmpty ? 'Giảm 5.000đ' : discountCtrl.text,
                    'minOrder': 30000,
                    'expiry': '31/12/2026',
                    'isActive': true,
                    'usedCount': 0,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã tạo mã khuyến mãi thành công')),
                );
              }
            },
            child: const Text('Tạo mã', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
