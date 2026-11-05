import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/menu_item_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../services/commission_policy_service.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class RestaurantEditItemScreen extends StatefulWidget {
  final MenuItemModel? item;
  final int storeId;

  const RestaurantEditItemScreen({
    super.key,
    this.item,
    this.storeId = 1,
  });

  @override
  State<RestaurantEditItemScreen> createState() => _RestaurantEditItemScreenState();
}

class _RestaurantEditItemScreenState extends State<RestaurantEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;
  late bool _isAvailable;
  String _selectedCategory = 'COM';
  bool _isSaving = false;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool get isCreateMode => widget.item == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(text: widget.item != null ? widget.item!.basePrice.toStringAsFixed(0) : '35000');
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _imageUrlController = TextEditingController(
      text: widget.item?.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
    );
    _isAvailable = widget.item?.isAvailable ?? true;
    _selectedCategory = widget.item?.category ?? 'COM';
    CommissionPolicyService().loadCommissionRate().then((_) {
      if (mounted) setState(() {});
    });
    _priceController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 35000.0;
      final desc = _descController.text.trim();
      final img = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c';

      final service = StoreService();
      if (isCreateMode) {
        await service.createMenuItem(
          storeId: widget.storeId,
          name: name,
          basePrice: price,
          category: _selectedCategory,
          description: desc,
          imageUrl: img,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCreateMode ? 'Đã thêm món "$name" vào thực đơn quán thành công!' : 'Đã cập nhật món ăn thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(title: isCreateMode ? 'Thêm Món Mới KTX' : 'Chỉnh sửa Món & Topping'),
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
                  Text('Thông tin món ăn', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên món ăn (*)',
                      hintText: 'VD: Cơm sườn nướng đặc biệt',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Tên món không được để trống' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá bán cơ bản (VNĐ) (*)',
                            hintText: '35000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Giá bán không được để trống' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'COM', child: Text('Cơm')),
                            DropdownMenuItem(value: 'BUN_PHO', child: Text('Bún / Phở')),
                            DropdownMenuItem(value: 'DO_UONG', child: Text('Đồ uống')),
                            DropdownMenuItem(value: 'AN_VAT', child: Text('Ăn vặt')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildCommissionCalculationBox(),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Đường dẫn ảnh món (URL)',
                      hintText: 'https://...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.image),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả món ăn',
                      hintText: 'Nguyên liệu, hương vị đặc trưng...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Còn món phục vụ hôm nay', style: AppTypography.bodyMedium),
                      Switch(
                        value: _isAvailable,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Topping section
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
                      Text('Tùy chọn Topping KTX', style: AppTypography.heading2),
                      const Chip(
                        label: Text('Mặc định', style: TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.surfaceVariant,
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildToppingTile('Trứng ốp la lòng đào', 6000, true),
                  _buildToppingTile('Chả trứng hấp thịt', 8000, true),
                  _buildToppingTile('Thêm tóp mỡ giòn', 3000, true),
                  _buildToppingTile('Canh chua thịt bằm', 5000, true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            KtxButton(
              label: isCreateMode ? 'Thêm món vào thực đơn' : 'Lưu thay đổi món',
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToppingTile(String name, double price, bool available) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: AppTypography.bodyMedium),
      subtitle: Text(
        '+${currencyFormatter.format(price)}',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      trailing: Chip(
        label: Text(
          available ? 'Còn Topping' : 'Hết Topping',
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.successLight,
      ),
    ),
    );
  }

  Widget _buildCommissionCalculationBox() {
    final policy = CommissionPolicyService();
    final rate = policy.commissionRate;
    final storeRate = policy.storePayoutRate;
    final rawPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final platformFee = policy.calculatePlatformFee(rawPrice);
    final netPayout = policy.calculateNetPayout(rawPrice);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Dự toán Thực nhận của Quán',
                    style: AppTypography.heading3.copyWith(fontSize: 13, color: AppColors.primaryDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Chiết khấu sàn: ${rate.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá niêm yết cho Sinh viên:', style: AppTypography.bodySmall),
              Text(currencyFormatter.format(rawPrice), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí sàn KTX Food (${rate.toStringAsFixed(0)}% theo Admin):', style: AppTypography.bodySmall),
              Text('-${currencyFormatter.format(platformFee)}', style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '💵 Quán thực nhận (${storeRate.toStringAsFixed(0)}%):',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                currencyFormatter.format(netPayout),
                style: AppTypography.heading3.copyWith(color: AppColors.success, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '* Tỷ lệ chiết khấu ${rate.toStringAsFixed(0)}% được thiết lập tập trung bởi Ban Quản Lý KTX.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 11),
          ),
        ],
      ),
    );
  }

}
