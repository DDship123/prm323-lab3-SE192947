import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/shipper_batch_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/shipper_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class ShipperHandoverConfirmScreen extends StatefulWidget {
  final ShipperBatchItemModel order;
  final String shipperId;

  const ShipperHandoverConfirmScreen({
    super.key,
    required this.order,
    required this.shipperId,
  });

  @override
  State<ShipperHandoverConfirmScreen> createState() => _ShipperHandoverConfirmScreenState();
}

class _ShipperHandoverConfirmScreenState extends State<ShipperHandoverConfirmScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _pinController.text = widget.order.pickupPin ?? '4567';
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmDelivery() async {
    setState(() => _isLoading = true);
    final success = await context.read<ShipperViewModel>().confirmDelivery(
          orderId: widget.order.orderId,
          shipperId: widget.shipperId,
        );
    setState(() => _isLoading = false);

    if (mounted && success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã giao thành công đơn #${widget.order.orderCode} cho ${widget.order.customerName}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _openQrScanner() {
    final expectedQr = widget.order.pickupQrCode ?? 'QR_KTX_${widget.order.orderId}';
    final expectedPin = widget.order.pickupPin ?? '4567';
    final scanController = TextEditingController(text: expectedQr);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Quét Mã QR Sinh Viên', style: AppTypography.heading2),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Khung mô phỏng kính ngắm Camera Scanner
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.5),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const Positioned(
                    top: 24,
                    child: Text(
                      'Hướng camera vào mã QR của sinh viên',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  const Icon(Icons.camera_alt_outlined, color: Colors.white24, size: 64),
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.roundedFull,
                      ),
                      child: const Text(
                        'ĐANG QUÉT TỰ ĐỘNG...',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Mã QR hợp lệ của đơn: $expectedQr (Mã PIN: $expectedPin)',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            KtxButton(
              label: '📱 Giả lập Quét thành công Mã QR',
              icon: Icons.check_circle_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                _pinController.text = expectedPin;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Đã nhận diện mã QR: $expectedQr! Đang xác thực đơn hàng...'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
                _handleConfirmDelivery();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nhập mã PIN thủ công'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isCod = o.paymentMethod.toUpperCase() == 'COD';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Xác nhận Trao hàng & Thu tiền',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Quét mã QR',
            onPressed: _openQrScanner,
          ),
        ],
      ),
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
                    Text('Đơn hàng #${o.orderCode}', style: AppTypography.heading2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCod ? AppColors.warningLight : AppColors.successLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        isCod ? 'Thu tiền mặt COD' : 'VietQR - Đã thanh toán',
                        style: TextStyle(
                          color: isCod ? AppColors.warning : AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.person, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(o.customerName, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(o.customerPhone, style: AppTypography.bodyMedium),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.call, size: 16, color: AppColors.primary),
                      label: const Text('Gọi sinh viên', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(o.pickupLocation, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ),
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
                Text('Số tiền cần thu', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  isCod ? currencyFormatter.format(o.finalAmount) : '0đ (Đã thanh toán Online)',
                  style: AppTypography.heading1.copyWith(
                    color: isCod ? AppColors.warning : AppColors.success,
                    fontSize: 26,
                  ),
                ),
                const Divider(height: 24),
                KtxButton(
                  label: 'Quét Mã QR Nhận Hàng của Sinh viên',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: _openQrScanner,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('HOẶC NHẬP MÃ PIN (BR-ORD-05)', style: AppTypography.caption.copyWith(color: AppColors.textHint, fontWeight: FontWeight.bold)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Mã PIN nhận hàng (4 số sinh viên cung cấp)', style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '----',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          KtxButton(
            label: 'Xác nhận trao hàng & Hoàn tất đơn',
            isLoading: _isLoading,
            onPressed: _handleConfirmDelivery,
          ),
        ],
      ),
    );
  }
}

