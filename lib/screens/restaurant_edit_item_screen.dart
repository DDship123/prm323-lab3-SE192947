import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/menu_item_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class RestaurantEditItemScreen extends StatefulWidget {
  final MenuItemModel item;

  const RestaurantEditItemScreen({super.key, required this.item});

  @override
  State<RestaurantEditItemScreen> createState() => _RestaurantEditItemScreenState();
}

class _RestaurantEditItemScreenState extends State<RestaurantEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late bool _isAvailable;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController = TextEditingController(text: widget.item.basePrice.toStringAsFixed(0));
    _descController = TextEditingController(text: widget.item.description);
    _isAvailable = widget.item.isAvailable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Chỉnh sửa Món & Topping KTX'),
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
                      labelText: 'Tên món ăn',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Tên món không được để trống' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá bán cơ bản (VNĐ)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Giá bán không được để trống' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả món ăn',
                      border: OutlineInputBorder(),
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
            const SizedBox(height: AppSpacing.lg),
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
                      Text('Danh sách Topping KTX', style: AppTypography.heading2),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                        label: const Text('Thêm Topping', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildToppingTile('Trứng ốp la lòng đào', 5000, true),
                  _buildToppingTile('Chả trứng hấp thịt', 7000, true),
                  _buildToppingTile('Cơm thêm hạt dẻo', 5000, true),
                  _buildToppingTile('Canh khổ qua dồn thịt', 12000, false),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            KtxButton(
              label: 'Lưu thay đổi món & Topping',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật món ăn và topping thành công')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToppingTile(String name, double price, bool available) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: AppTypography.bodyMedium),
      subtitle: Text(
        '+${currencyFormatter.format(price)}',
        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      trailing: Chip(
        label: Text(
          available ? 'Còn Topping' : 'Hết Topping',
          style: TextStyle(
            color: available ? AppColors.success : AppColors.error,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: available ? AppColors.successLight : AppColors.errorLight,
      ),
    );
  }
}
