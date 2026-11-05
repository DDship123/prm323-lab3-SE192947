import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../models/order_model.dart';
import '../theme/ktx_design_system.dart';
import '../viewmodels/dispute_vm.dart';
import '../widgets/screen_state.dart';
import 'dispute_history_screen.dart';

/// Màn hình S8: Khiếu nại & Hoàn tiền KTX theo tài liệu Thông số thiết kế (Figma Frame 8 - Node 766:7810)
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tải ảnh bằng chứng sự cố món ăn',
                style: AppTypography.heading3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Chụp rõ tem niêm phong hoặc ảnh món ăn gặp sự cố.',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
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
              uploadStatus: 'success',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gửi khiếu nại thành công! Trưởng bàn gom KTX sẽ xử lý trong 30 phút.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
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
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Khiếu Nại & Hoàn Tiền',
        subtitle: 'Bảo vệ quyền lợi Sinh viên ĐHQG',
        actions: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.headerBtnBackground,
              shape: BoxShape.circle,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DisputeHistoryScreen(),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: const Center(
                  child: Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. BANNER CAM KẾT (Theo Figma Node 766:7810: Bảo đảm 100%)
            KtxCard(
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.iconBoxBackground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xử lý nhanh bàn giao • Bù tiền thỏa đáng',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Quán và Trưởng bàn KTX Khu B sẽ trích xuất camera để giải quyết trong 30 phút.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const KtxPill(
                    label: '100%',
                    variant: KtxPillVariant.done,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. CHỌN ĐƠN HÀNG GẶP SỰ CỐ
            KtxCard(
              isFormCard: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. CHỌN ĐƠN HÀNG GẶP SỰ CỐ', style: AppTypography.heading3),
                  const SizedBox(height: 8),
                  if (vm.availableOrders.isEmpty)
                    const Text('Đang tải danh sách đơn hàng đã nhận...')
                  else
                    DropdownButtonFormField<OrderSummaryModel>(
                      value: vm.selectedOrder,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.roundedMd,
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: vm.availableOrders.map((order) {
                        return DropdownMenuItem(
                          value: order,
                          child: Text(
                            '#${order.id} - ${order.storeName} (${currencyFormatter.format(order.totalPrice)})',
                            style: AppTypography.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (order) {
                        if (order != null) vm.selectOrder(order);
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. CHỌN LÝ DO KHIẾU NẠI (Chip co giãn Wrap)
            KtxCard(
              isFormCard: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('2. BẠN ĐANG GẶP SỰ CỐ GÌ?', style: AppTypography.heading3),
                      const KtxPill(
                        label: '*BẮT BUỘC',
                        variant: KtxPillVariant.rejected,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vm.commonReasons.map((reason) {
                      final isSelected = vm.selectedReason == reason;
                      return GestureDetector(
                        onTap: () => vm.setReason(reason),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
                            borderRadius: AppRadius.roundedFull,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            reason,
                            style: AppTypography.chipLabel.copyWith(
                              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. MÔ TẢ CHI TIẾT SỰ CỐ & SỐ TIỀN HOÀN
            KtxCard(
              isFormCard: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KtxTextField(
                    label: '3. MÔ TẢ CHI TIẾT SỰ CỐ',
                    hintText: 'Lúc nhận tại Bàn 2 mở túi thấy thiếu món hoặc đổ tràn...',
                    controller: vm.descriptionController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  KtxTextField(
                    label: '4. SỐ TIỀN ĐỀ XUẤT HOÀN (VND)',
                    hintText: 'Ví dụ: 35000',
                    controller: vm.refundAmountController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. BẰNG CHỨNG HÌNH ẢNH
            KtxCard(
              isFormCard: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('5. BẰNG CHỨNG HÌNH ẢNH', style: AppTypography.heading3),
                      const KtxPill(
                        label: 'BẮT BUỘC',
                        variant: KtxPillVariant.waiting,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Túi gom có tem niêm phong nhiệt. Chụp rõ tem giúp duyệt hoàn tiền sau 15–30 phút.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: 8),

                  if (vm.selectedImageBytes != null) ...[
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: AppRadius.roundedMd,
                            border: Border.all(color: AppColors.primary),
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
                          top: 6,
                          right: 6,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: isSubmitting ? null : vm.clearSelectedImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    InkWell(
                      onTap: isSubmitting ? null : () => _showImageSourcePicker(context, vm),
                      borderRadius: AppRadius.roundedMd,
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+ Thêm ảnh / Chụp tem bill',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Hỗ trợ JPG, PNG (Tối đa 10MB)',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (isSubmitting) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    loadingMsg,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // NÚT CHÍNH DUY NHẤT TRÊN TRANG (Mục 5: Nền #ff5722, cao 44, bo 12)
            KtxButton(
              label: 'Gửi Yêu Cầu Hoàn Tiền',
              variant: KtxButtonVariant.primary,
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
