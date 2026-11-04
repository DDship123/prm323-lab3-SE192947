import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class RestaurantStoreSettingsScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantStoreSettingsScreen({super.key, required this.ownerId});

  @override
  State<RestaurantStoreSettingsScreen> createState() => _RestaurantStoreSettingsScreenState();
}

class _RestaurantStoreSettingsScreenState extends State<RestaurantStoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Cơm Tấm Cô Ba - ĐHQG');
  final _addressController = TextEditingController(text: 'Cổng B2 KTX ĐHQG, Phường Đông Hòa, Dĩ An');
  final _phoneController = TextEditingController(text: '0918765432');
  final _hoursController = TextEditingController(text: '06:30 - 21:00');
  bool _isOpen = true;
  bool _serveZoneA = true;
  bool _serveZoneB = true;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KtxAppBar(title: 'Thiết lập cửa hàng'),
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
              label: 'Lưu cấu hình cửa hàng',
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thiết lập cửa hàng thành công')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
