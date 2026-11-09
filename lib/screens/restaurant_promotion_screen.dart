import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';

/// Màn hình Quản lý Khuyến mãi & Voucher của Quán Ăn
/// Hỗ trợ Quán cấu hình CRUD, Bật/Tắt (Active/Inactive), giới hạn số lượt và Nạp thêm lượt phát hành
class RestaurantPromotionScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantPromotionScreen({super.key, required this.ownerId});

  @override
  State<RestaurantPromotionScreen> createState() => _RestaurantPromotionScreenState();
}

class _RestaurantPromotionScreenState extends State<RestaurantPromotionScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    final voucherService = context.watch<VoucherService>();
    final vouchers = voucherService.vouchers;

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
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _showAddPromotionDialog(context, voucherService),
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Tạo mã mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (vouchers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Chưa có mã khuyến mãi nào', style: AppTypography.bodyMedium),
              ),
            )
          else
            ...vouchers.map((v) => _buildVoucherCard(context, voucherService, v)),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(BuildContext context, VoucherService service, VoucherModel v) {
    final bool isActive = v.isActive;
    final bool isExhausted = v.isExhausted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isExhausted
              ? Colors.red.shade200
              : (isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
          width: isActive ? 1.5 : 1,
        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      v.code,
                      style: TextStyle(
                        color: isActive ? AppColors.primary : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: v.type == VoucherType.order ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      v.type == VoucherType.order ? 'Giảm món ăn' : 'Giảm ship KTX',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: v.type == VoucherType.order ? const Color(0xFF2563EB) : const Color(0xFF059669),
                      ),
                    ),
                  ),
                  if (isExhausted) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Text(
                        'HẾT LƯỢT',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
              Switch(
                value: isActive,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  service.toggleVoucherStatus(v.code, val);
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(v.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            v.discountPercent != null && v.discountPercent! > 0
                ? 'Giảm ${v.discountPercent!.toInt()}% tổng tiền món (Tối đa ${currencyFormatter.format(v.discountAmount)})'
                : 'Giảm ${currencyFormatter.format(v.discountAmount)}',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Đơn tối thiểu: ${currencyFormatter.format(v.minOrderValue)}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Đã dùng: ${v.usedCount} / ${v.usageLimit > 0 ? v.usageLimit : "∞"} lượt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isExhausted ? Colors.red : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trạng thái: ${!isActive ? "Tạm ngưng (Ẩn SV)" : (isExhausted ? "Hết lượt (Vô hiệu SV)" : "Đang hoạt động")}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: !isActive ? const Color(0xFF94A3B8) : (isExhausted ? Colors.red : const Color(0xFF059669)),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _showTopupQuotaDialog(context, service, v),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppColors.primary),
                label: const Text('Nạp thêm lượt', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTopupQuotaDialog(BuildContext context, VoucherService service, VoucherModel v) {
    final qtyCtrl = TextEditingController(text: '50');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Nạp thêm lượt dùng cho ${v.code}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hiện tại: đã dùng ${v.usedCount} / ${v.usageLimit} lượt.', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số lượt muốn nạp thêm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.add),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final added = int.tryParse(qtyCtrl.text.trim()) ?? 0;
              if (added > 0) {
                service.replenishVoucherQuota(v.code, added);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã nạp thêm +$added lượt cho mã ${v.code}')),
                );
              }
            },
            child: const Text('Xác nhận nạp', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPromotionDialog(BuildContext context, VoucherService service) {
    final codeCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '10');
    final maxCapCtrl = TextEditingController(text: '15000');
    final minOrderCtrl = TextEditingController(text: '35000');
    final limitCtrl = TextEditingController(text: '50');
    VoucherType selectedType = VoucherType.order;
    bool isPercent = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Tạo khuyến mãi mới cho Quán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Mã voucher (VD: COMNGON10)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên khuyến mãi (VD: Giảm 10% đơn trưa)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Loại mã:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Giảm món'),
                        selected: selectedType == VoucherType.order,
                        onSelected: (val) => setDialogState(() => selectedType = VoucherType.order),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Giảm ship'),
                        selected: selectedType == VoucherType.shipping,
                        onSelected: (val) => setDialogState(() => selectedType = VoucherType.shipping),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: isPercent ? 'Mức giảm (%)' : 'Số tiền giảm (đ)',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setDialogState(() => isPercent = !isPercent),
                        child: Text(isPercent ? 'Đổi sang đ' : 'Đổi sang %'),
                      ),
                    ],
                  ),
                  if (isPercent) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: maxCapCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Giảm tối đa (đ)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: minOrderCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Đơn tối thiểu (đ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số lượt phát hành tối đa (quota)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final code = codeCtrl.text.trim().toUpperCase();
                  if (code.isEmpty) return;

                  final discountVal = double.tryParse(discountCtrl.text.trim()) ?? 0;
                  final maxCap = double.tryParse(maxCapCtrl.text.trim()) ?? 0;
                  final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0;
                  final limit = int.tryParse(limitCtrl.text.trim()) ?? 50;

                  final newVoucher = VoucherModel(
                    code: code,
                    title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Ưu đãi $code',
                    description: isPercent
                        ? 'Giảm ${discountVal.toInt()}% (tối đa ${currencyFormatter.format(maxCap)})'
                        : 'Giảm trực tiếp ${currencyFormatter.format(discountVal)}',
                    type: selectedType,
                    discountPercent: isPercent ? discountVal : null,
                    discountAmount: isPercent ? maxCap : discountVal,
                    minOrderValue: minOrder,
                    usageLimit: limit,
                    usedCount: 0,
                    isActive: true,
                    storeId: 1,
                  );

                  final ok = await service.createVoucher(newVoucher);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã tạo mã khuyến mãi $code thành công')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mã voucher này đã tồn tại trong hệ thống!')),
                      );
                    }
                  }
                },
                child: const Text('Tạo mã', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
