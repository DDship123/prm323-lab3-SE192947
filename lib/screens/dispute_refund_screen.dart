import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/dispute_vm.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_text_field.dart';
import '../widgets/screen_state.dart';
import 'dispute_history_screen.dart';

/// Màn hình S8: Báo cáo sự cố đồ ăn, tải ảnh bằng chứng và yêu cầu hoàn tiền
class DisputeRefundScreen extends StatefulWidget {
  final OrderSummaryModel? initialOrder;

  const DisputeRefundScreen({super.key, this.initialOrder});

  @override
  State<DisputeRefundScreen> createState() => _DisputeRefundScreenState();
}

class _DisputeRefundScreenState extends State<DisputeRefundScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final vm = context.read<DisputeViewModel>();
        vm.initDisputeData(userId: user.uid);
        if (widget.initialOrder != null) {
          vm.selectOrder(widget.initialOrder!);
        }
      }
    });
  }

  void _showImageSourcePicker(BuildContext context, DisputeViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tải ảnh bằng chứng sự cố món ăn',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                'Hình ảnh sẽ được tải lên Cloud Storage theo chuẩn reports/{uid}/',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Chụp ảnh mới',
                    onTap: () {
                      Navigator.pop(context);
                      vm.pickEvidenceImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Chọn từ thư viện',
                    onTap: () {
                      Navigator.pop(context);
                      vm.pickEvidenceImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.roundedMd,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit(DisputeViewModel vm) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại.')),
      );
      return;
    }

    final idToken = await user.getIdToken();
    final success = await vm.submitDispute(
      userId: user.uid,
      idToken: idToken,
    );

    if (mounted) {
      if (success) {
        context.read<AnalyticsService>().logUploadDisputeEvidence(
              orderId: vm.selectedOrder != null
                  ? 'ORD_${vm.selectedOrder!.id}'
                  : 'ORD_DEMO',
              reasonCode: vm.selectedReason,
              refundRequested:
                  double.tryParse(vm.refundAmountController.text) ?? 0.0,
              uploadStatus: 'failed',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi khiếu nại thành công! Ảnh bằng chứng đã được lưu vào Cloud Storage.'),
            backgroundColor: AppColors.success,
          ),
        );
        // Chuyển sang màn hình xem lịch sử khiếu nại S8b
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DisputeHistoryScreen()),
        );
      } else {
        if (vm.submitState is StateError) {
          final err = (vm.submitState as StateError).errorMessage;
          context.read<AnalyticsService>().logUploadDisputeEvidence(
              orderId: vm.selectedOrder != null
                  ? 'ORD_${vm.selectedOrder!.id}'
                  : 'ORD_DEMO',
              reasonCode: vm.selectedReason,
              refundRequested:
                  double.tryParse(vm.refundAmountController.text) ?? 0.0,
              uploadStatus: 'failed',
            );
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DisputeViewModel>();
    final isSubmitting = vm.submitState is StateLoading;
    final loadingMsg = vm.submitState is StateLoading
        ? (vm.submitState as StateLoading).message ?? 'Đang xử lý...'
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo sự cố & Hoàn tiền'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Lịch sử khiếu nại',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DisputeHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Chọn đơn hàng
            Text('1. Chọn đơn hàng gặp sự cố tại KTX', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.sm),
            if (vm.availableOrders.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text('Đang tải danh sách đơn hàng đã nhận...'),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OrderSummaryModel>(
                    isExpanded: true,
                    value: vm.selectedOrder,
                    items: vm.availableOrders.map((order) {
                      return DropdownMenuItem(
                        value: order,
                        child: Text(
                          '#${order.id} - ${order.storeName} (${currencyFormatter.format(order.totalPrice)})',
                          style: AppTypography.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (order) {
                      if (order != null) vm.selectOrder(order);
                    },
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // 2. Chọn lý do sự cố
            Text('2. Lý do khiếu nại', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: vm.commonReasons.map((reason) {
                final isSelected = vm.selectedReason == reason;
                return ChoiceChip(
                  label: Text(reason),
                  selected: isSelected,
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  onSelected: (_) => vm.setReason(reason),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 3. Mô tả chi tiết
            Text('3. Mô tả chi tiết sự cố', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.sm),
            KtxTextField(
              controller: vm.descriptionController,
              hintText: 'Mô tả rõ tình trạng món ăn, vị trí nhận tại KTX hoặc món bị thiếu...',
              maxLines: 3,
            ),

            const SizedBox(height: AppSpacing.lg),

            // 4. Số tiền yêu cầu hoàn
            Text('4. Số tiền yêu cầu hoàn (VND)', style: AppTypography.heading3),
            const SizedBox(height: AppSpacing.sm),
            KtxTextField(
              controller: vm.refundAmountController,
              hintText: 'Nhập số tiền hoàn mong muốn',
              prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 5. Khu vực tải ảnh lên Đám mây (Cloud Storage)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5. Bằng chứng hình ảnh', style: AppTypography.heading3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Bắt buộc',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Chụp ảnh trực tiếp món ăn hoặc bao bì để shipper/quán đối soát.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Khung hiển thị ảnh đã chọn hoặc nút bấm tải ảnh
            if (vm.selectedImageBytes != null) ...[
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedMd,
                      child: Image.memory(
                        vm.selectedImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Xóa ảnh',
                        onPressed: isSubmitting ? null : vm.clearSelectedImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Thanh hiển thị tiến trình tải ảnh lên Firebase Cloud Storage
              if (vm.uploadProgress > 0.0 && isSubmitting) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến trình tải lên Cloud Storage:',
                      style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${(vm.uploadProgress * 100).toInt()}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: vm.uploadProgress,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ] else ...[
              InkWell(
                onTap: isSubmitting ? null : () => _showImageSourcePicker(context, vm),
                borderRadius: AppRadius.roundedMd,
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.roundedMd,
                    border: Border.all(
                      color: AppColors.border,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chạm để chụp hoặc chọn ảnh bằng chứng',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hỗ trợ JPG, PNG (Tối đa 10MB)',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            // Thông báo đang gửi
            if (isSubmitting) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    loadingMsg,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // Nút Gửi khiếu nại
            KtxButton(
              label: 'Gửi khiếu nại & Thẩm định hoàn tiền',
              icon: Icons.send_rounded,
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : () => _handleSubmit(vm),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
