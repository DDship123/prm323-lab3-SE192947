import 'package:flutter/material.dart';
import '../models/shipper_batch_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class ShipperPickupDetailScreen extends StatefulWidget {
  final ShipperBatchItemModel order;
  final VoidCallback onPickupConfirmed;

  const ShipperPickupDetailScreen({
    super.key,
    required this.order,
    required this.onPickupConfirmed,
  });

  @override
  State<ShipperPickupDetailScreen> createState() => _ShipperPickupDetailScreenState();
}

class _ShipperPickupDetailScreenState extends State<ShipperPickupDetailScreen> {
  final Map<int, bool> _checkedItems = {};

  final List<String> _itemsToPack = [
    '01 x Cơm Tấm Sườn Nướng (Hộp xốp giữ nhiệt)',
    '01 x Bịch mỡ hành + nước mắm tỏi ớt riêng',
    '01 x Canh rong biển nóng kèm muỗng đũa',
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _itemsToPack.length; i++) {
      _checkedItems[i] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Chi tiết Lấy hàng tại Quán'),
      body: ListView(
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
                    Text(o.storeName, style: AppTypography.heading2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text('#${o.orderCode}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(o.storeAddress, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('0918765432 (Chủ quán Cô Ba)', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
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
                Text('Kiểm tra món cần lấy vào túi giữ nhiệt', style: AppTypography.heading3),
                const SizedBox(height: AppSpacing.sm),
                ...List.generate(_itemsToPack.length, (i) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_itemsToPack[i], style: AppTypography.bodySmall),
                    value: _checkedItems[i] ?? false,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _checkedItems[i] = val ?? false);
                    },
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đảm bảo xếp đúng túi giữ nhiệt để giữ độ nóng và không làm đổ canh khi di chuyển về cổng KTX.',
                    style: TextStyle(color: AppColors.primaryDark, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          KtxButton(
            label: 'Xác nhận đã nhận đủ món',
            onPressed: () {
              widget.onPickupConfirmed();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã nhận món từ quán, sẵn sàng giao đến cổng KTX!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
