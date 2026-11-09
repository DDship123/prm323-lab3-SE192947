import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../firebase/analytics_service.dart';
import '../models/order_model.dart';
import '../services/crashlytics_service.dart';
import '../services/order_service.dart';
import '../services/store_bank_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../widgets/ktx_dialog.dart';
import 'pickup_qr_code_screen.dart';

/// Màn hình S5: Thanh toán online VietQR Napas 247 chuẩn 100% Figma
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
  Timer? _countdownTimer;
  int _secondsLeft = 9 * 60 + 57; // 09:57 theo Figma

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartCheckoutViewModel>().loadVietQrForOrder(widget.order);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  String get _countdownText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        backgroundColor: const Color(0xFF1E293B),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleConfirmTransfer(CartCheckoutViewModel vm) async {
    final ok = await vm.confirmVietQrPaid(widget.order.id);
    if (!mounted) return;
    if (!ok) {
      context.read<CrashlyticsService>().recordNonFatalError(
        Exception(
            'VietQrVerificationFailedException: Không tìm thấy giao dịch đơn #${widget.order.id} thất bại'),
        StackTrace.current,
        reason:
            'Khách hàng bấm Xác nhận nhưng hệ thống ngân hàng chưa ghi nhận tiền về',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Chưa ghi nhận chuyển khoản. Vui lòng thử lại sau giây lát hoặc chuyển sang COD.'),
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
      onSkipToPickup: () => _skipToQr(widget.order),
    );
  }

  Future<void> _skipToQr(OrderDetailModel order) async {
    Navigator.of(context).pop();
    try {
      await OrderService().updateOrderStatus(
        orderId: order.id,
        newStatus: 'DELIVERING',
      );
    } catch (_) {}
    final delivering =
        order.copyWith(status: 'DELIVERING', paymentStatus: 'PAID');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => PickupQrCodeScreen(order: delivering)),
      );
    }
  }

  Future<void> _handleDirectSkip(CartCheckoutViewModel vm) async {
    await vm.confirmVietQrPaid(widget.order.id);
    if (!mounted) return;
    try {
      await OrderService().updateOrderStatus(
        orderId: widget.order.id,
        newStatus: 'DELIVERING',
      );
    } catch (_) {}
    final delivering =
        widget.order.copyWith(status: 'DELIVERING', paymentStatus: 'PAID');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => PickupQrCodeScreen(order: delivering)),
      );
    }
  }

  Future<void> _handleSwitchToCod(CartCheckoutViewModel vm) async {
    final ok = await vm.switchOrderToCod(widget.order.id);
    if (!mounted) return;
    if (!ok) {
      context.read<CrashlyticsService>().recordNonFatalError(
        Exception(
            'SwitchToCodFailedException: Chuyển sang COD đơn #${widget.order.id} thất bại'),
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
      onSkipToPickup: () => _skipToQr(widget.order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CartCheckoutViewModel>();
    final bank = StoreBankService();

    final orderCode = widget.order.orderCode.isNotEmpty
        ? widget.order.orderCode
        : '#KTX-8829B';
    final transferContent = 'KTX8829B LE THUY LINH';
    final qrPayload = bank.getQrPaymentPayload(
      amount: widget.order.finalAmount > 0 ? widget.order.finalAmount : 45000,
      transferContent: transferContent,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Thanh toán online',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút bấm xác nhận hoàn tất thanh toán
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF521B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: vm.isSubmitting
                        ? null
                        : () => _handleConfirmTransfer(vm),
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 20),
                    label: const Text(
                      'Tôi đã hoàn tất chuyển khoản',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _handleDirectSkip(vm),
                      icon: const Icon(Icons.rocket_launch_rounded,
                          size: 14, color: Color(0xFF2563EB)),
                      label: const Text(
                        'Demo: Nhận hàng ngay',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _handleSwitchToCod(vm),
                      icon: const Icon(Icons.payments_outlined,
                          size: 14, color: Color(0xFF64748B)),
                      label: const Text(
                        'Đổi sang COD',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 5-Tab Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(Icons.explore_outlined, 'Khám phá', false),
                _buildBottomNavItem(
                    Icons.restaurant_outlined, 'Đặt món', false),
                _buildBottomNavItem(
                    Icons.receipt_long_rounded, 'Thanh toán', true),
                _buildBottomNavItem(Icons.history_rounded, 'Lịch sử', false),
                _buildBottomNavItem(
                    Icons.person_outline_rounded, 'Tài khoản', false),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Banner Giữ chỗ đơn gom ca trưa
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'GIỮ CHỖ ĐƠN GOM CA TRƯA',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(
                        _countdownText,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Đơn hàng $orderCode đang được giữ chỗ. Vui lòng thanh toán trước khi đóng ca lúc 11:30 để quán kịp vào bếp!',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF92400E), height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. VietQR Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header VietQR | Napas 247 | • MB Bank
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'VietQR',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF005BAA),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|',
                          style: TextStyle(color: Color(0xFFCBD5E1))),
                    ),
                    const Text(
                      'Napas 247',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('|',
                          style: TextStyle(color: Color(0xFFCBD5E1))),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E40AF),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'MB Bank',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Frame QR có 4 góc focus màu cam
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(
                      painter: const _QrCornerBracketPainter(
                        color: Color(0xFFFF521B),
                        cornerLength: 20,
                        strokeWidth: 3,
                        cornerRadius: 6,
                      ),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              size: 160.0,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF521B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.storefront_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2 nút Lưu ảnh QR & Mở App Bank
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã lưu mã QR vào thư viện ảnh.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded,
                                  size: 16, color: Color(0xFFFF521B)),
                              SizedBox(width: 6),
                              Text(
                                'Lưu ảnh QR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang mở ứng dụng Ngân hàng...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  size: 16, color: Color(0xFFFF521B)),
                              SizedBox(width: 6),
                              Text(
                                'Mở App Bank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thanh trạng thái tự động nhận diện
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: Text(
                          'Tự động nhận diện sau 5 – 15 giây khi chuyển khoản thành công',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Thông tin chuyển khoản
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin chuyển khoản',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ĐỐI SOÁT TỰ ĐỘNG',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Ngân hàng thụ hưởng
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ngân hàng thụ hưởng',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      const Text('MB Bank',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 1),
                      Text(bank.bankName,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      color: Color(0xFF2563EB), size: 20),
                ),
              ],
            ),
          ),

          // Chủ tài khoản thụ hưởng
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chủ tài khoản thụ hưởng',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      bank.accountName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const Icon(Icons.verified_rounded,
                    color: Color(0xFF059669), size: 20),
              ],
            ),
          ),

          // Số tài khoản
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Số tài khoản',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      bank.accountNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                _buildCopyButton(
                  onTap: () =>
                      _copyToClipboard(bank.accountNumber, 'Số tài khoản'),
                ),
              ],
            ),
          ),

          // Số tiền thanh toán chuẩn xác (Khung viền cam nổi bật)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF9),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: const Color(0xFFFF521B), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SỐ TIỀN THANH TOÁN CHUẨN XÁC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF521B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.order.finalAmount > 0
                          ? _formatCurrency(widget.order.finalAmount)
                          : '45.000đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF521B),
                      ),
                    ),
                  ],
                ),
                _buildCopyButton(
                  onTap: () => _copyToClipboard(
                    widget.order.finalAmount > 0
                        ? widget.order.finalAmount.toInt().toString()
                        : '45000',
                    'Số tiền',
                  ),
                ),
              ],
            ),
          ),

          // Nội dung chuyển khoản (bắt buộc)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nội dung chuyển khoản (bắt buộc)',
                      style:
                          TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Không đổi nội dung',
                        style: TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      transferContent,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF521B),
                        fontFamily: 'monospace',
                        letterSpacing: 1.0,
                      ),
                    ),
                    _buildCopyButton(
                      onTap: () => _copyToClipboard(
                          transferContent, 'Nội dung chuyển khoản'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Khung cảnh báo vàng
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD97706), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng giữ nguyên nội dung chuyển khoản $transferContent để hệ thống ghi nhận tự động. Chuyển sai nội dung sẽ bị hoàn tiền muộn.',
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF92400E),
                        height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Tóm tắt đơn gom ca
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tóm tắt đơn gom ca',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '• KTX Khu B',
                        style: TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded,
                        size: 15, color: Color(0xFFFF521B)),
                    const SizedBox(width: 6),
                    Text(
                      widget.order.storeName.isNotEmpty
                          ? widget.order.storeName
                          : 'Quán Cơm Tấm Cô Ba - ĐHQG',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Khung giờ: ${widget.order.slotTime.isNotEmpty ? widget.order.slotTime : '—'}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B))),
                    const Text('Giao đồng loạt',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.order.pickupLocation.isNotEmpty
                            ? widget.order.pickupLocation
                            : '—',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                // Chi tiết món
                // Danh sách món lấy từ đơn hàng thật (không hardcode)
                ...widget.order.items.map((it) {
                  final opts = it.selectedOptions
                      .map((e) => e.choice)
                      .where((c) => c.trim().isNotEmpty)
                      .join(', ');
                  return _buildSummaryItemRow(
                    '${it.quantity}x ${it.itemName}${opts.isNotEmpty ? ' ($opts)' : ''}',
                    _formatCurrency(it.itemTotalAmount),
                  );
                }),
                _buildSummaryItemRow(
                    'Tiền món', _formatCurrency(widget.order.subtotalAmount)),
                _buildSummaryItemRow('Phí gom KTX (Theo Ca)',
                    _formatCurrency(widget.order.deliveryFee)),
                if (widget.order.groupDiscountAmount > 0)
                  _buildSummaryItemRow('Giảm giá',
                      '-${_formatCurrency(widget.order.groupDiscountAmount)}'),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TỔNG CỘNG THANH TOÁN',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Color(0xFF1E293B))),
                    Text(
                      widget.order.finalAmount > 0
                          ? _formatCurrency(widget.order.finalAmount)
                          : '45.000đ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF521B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. 3 Bước thanh toán nhanh
          const Text(
            '3 Bước thanh toán nhanh',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStepCard(
                step: 'BƯỚC 1',
                title: 'Mở app Ngân\nhàng/Ví',
                icon: Icons.smartphone_rounded,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 8),
              _buildStepCard(
                step: 'BƯỚC 2',
                title: 'Quét mã QR\nhoặc dán STK',
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFFFF521B),
              ),
              const SizedBox(width: 8),
              _buildStepCard(
                step: 'BƯỚC 3',
                title: 'Kiểm tra tiền\n& xác nhận',
                icon: Icons.verified_rounded,
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Hotline hỗ trợ bàn giao cổng KTX
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      size: 18, color: Color(0xFF475569)),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cần hỗ trợ giao hàng cổng KTX?',
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Text(
                        'Trưởng Bàn Giao Cổng Khu B',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: const Text(
                    '1900 68xx',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF521B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCopyButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy_rounded, size: 12, color: Color(0xFFFF521B)),
            SizedBox(width: 4),
            Text(
              'Sao chép',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItemRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF475569))),
          Text(price,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              step,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

/// Vẽ 4 góc khung ngắm QR màu cam
class _QrCornerBracketPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double cornerRadius;

  const _QrCornerBracketPainter({
    required this.color,
    required this.cornerLength,
    required this.strokeWidth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final len = cornerLength;

    // Top-left
    final pathTL = Path()
      ..moveTo(0, len)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(len, 0);
    canvas.drawPath(pathTL, paint);

    // Top-right
    final pathTR = Path()
      ..moveTo(w - len, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, len);
    canvas.drawPath(pathTR, paint);

    // Bottom-left
    final pathBL = Path()
      ..moveTo(0, h - len)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(len, h);
    canvas.drawPath(pathBL, paint);

    // Bottom-right
    final pathBR = Path()
      ..moveTo(w - len, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - len);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
