import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../firebase/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../models/order_model.dart';
import '../services/store_bank_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_dialog.dart';

/// Màn hình S5: Thanh toán VietQR Napas 247 & Cơ chế Dự phòng Chuyển sang COD (API-012, API-013)
class OnlinePaymentScreen extends StatefulWidget {
  final OrderDetailModel order;
  final ValueChanged<OrderDetailModel> onPaymentDone;

  const OnlinePaymentScreen({
    super.key,
    required this.order,
    required this.onPaymentDone,
  });

  @override
  State<OnlinePaymentScreen> createState() => _OnlinePaymentScreenState();
}

class _OnlinePaymentScreenState extends State<OnlinePaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartCheckoutViewModel>().loadVietQrForOrder(widget.order);
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  Future<void> _handleConfirmTransfer(CartCheckoutViewModel vm) async {
    final ok = await vm.confirmVietQrPaid(widget.order.id);
    if (!mounted) return;
    if (!ok) {
      context.read<CrashlyticsService>().recordNonFatalError(
        Exception('VietQrVerificationFailedException: Không tìm thấy giao dịch đơn #${widget.order.id} thất bại'),
        StackTrace.current,
        reason: 'Khách hàng bấm Xác nhận nhưng hệ thống ngân hàng chưa ghi nhận tiền về',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa ghi nhận chuyển khoản. Vui lòng thử lại sau giây lát hoặc chuyển sang COD.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AnalyticsService>().logPurchase(
      orderId: widget.order.id.toString(),
      totalValue: widget.order.finalAmount,
      paymentMethod: 'VIETQR',
    );
    await KtxDialog.showOrderSuccess(
      context,
      orderCode: widget.order.orderCode,
      onTrackOrder: () {
        Navigator.of(context).pop();
        widget.onPaymentDone(widget.order);
      },
    );
  }

  Future<void> _handleSwitchToCod(CartCheckoutViewModel vm) async {
    final ok = await vm.switchOrderToCod(widget.order.id);
    if (!mounted) return;
    if (!ok) {
      context.read<CrashlyticsService>().recordNonFatalError(
        Exception('SwitchToCodFailedException: Chuyển sang COD đơn #${widget.order.id} thất bại'),
        StackTrace.current,
        reason: 'Không thể cập nhật phương thức thanh toán sang tiền mặt COD',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chuyển đổi sang COD thất bại. Vui lòng thử lại.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã chuyển phương thức thanh toán sang Tiền mặt (COD) thành công!',
        ),
      ),
    );

    context.read<AnalyticsService>().logPurchase(
      orderId: widget.order.id.toString(),
      totalValue: widget.order.finalAmount,
      paymentMethod: 'VIETQR',
    );
    await KtxDialog.showOrderSuccess(
      context,
      orderCode: widget.order.orderCode,
      onTrackOrder: () {
        Navigator.of(context).pop();
        widget.onPaymentDone(widget.order);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartCheckoutViewModel>();
    final payment = vm.currentPayment;
    final transferContent = payment?.vietqrContent ?? 'ORD_${widget.order.id}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Thanh toán VietQR',
        subtitle: widget.order.orderCode,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  Text(
                    'Quét mã VietQR Napas 247',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mở ứng dụng Ngân hàng hoặc MoMo để quét mã tự động',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final bankService = StoreBankService();
                      final qrPayload = bankService.getQrPaymentPayload(
                        amount: widget.order.finalAmount,
                        transferContent: transferContent,
                      );
                      return Container(
                        width: 240,
                        height: 240,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Center(
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 210.0,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                          ),
                        ),
                      );
                    },                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow(
                    'Ngân hàng thụ hưởng',
                    StoreBankService().bankName,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Số tài khoản',
                    StoreBankService().accountNumber,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Chủ tài khoản',
                    StoreBankService().accountName,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Số tiền chuẩn (BR-PAY-01)',
                    _formatCurrency(widget.order.finalAmount),
                    highlight: true,
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Nội dung chuyển khoản bắt buộc',
                    transferContent,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            KtxButton(
              label: 'Tôi đã chuyển khoản thành công',
              icon: Icons.verified_rounded,
              isLoading: vm.isSubmitting,
              onPressed: () => _handleConfirmTransfer(vm),
            ),
            const SizedBox(height: AppSpacing.sm + 4),
            KtxButton(
              label: 'App ngân hàng lỗi? Đổi sang Tiền mặt (COD)',
              variant: KtxButtonVariant.outline,
              icon: Icons.payments_outlined,
              isLoading: vm.isSubmitting,
              onPressed: () => _handleSwitchToCod(vm),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: highlight ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
