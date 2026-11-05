import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';
import '../widgets/ktx_dialog.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_text_field.dart';
import '../services/order_service.dart';
import 'online_payment_screen.dart';
import 'pickup_qr_code_screen.dart';

/// Màn hình S4: Giỏ hàng, Chọn Ca gom đơn KTX & Đặt hàng (API-006)
class GroupCartCheckoutScreen extends StatefulWidget {
  final ValueChanged<OrderDetailModel> onOrderCompleted;

  const GroupCartCheckoutScreen({
    super.key,
    required this.onOrderCompleted,
  });

  @override
  State<GroupCartCheckoutScreen> createState() =>
      _GroupCartCheckoutScreenState();
}

class _GroupCartCheckoutScreenState extends State<GroupCartCheckoutScreen> {
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final remoteFee =
          context.read<RemoteConfigService>().groupShipFee.toDouble();
      context.read<CartCheckoutViewModel>().updateDeliveryFee(remoteFee);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  Future<void> _handlePlaceOrder(CartCheckoutViewModel cartVm) async {
    context.read<AnalyticsService>().logBeginCheckout(
          itemCount: cartVm.totalItemCount,
          subtotalAmount: cartVm.subtotalAmount,
          shippingFee: cartVm.deliveryFee,
        );
    cartVm.setNote(_noteCtrl.text);
    final created = await cartVm.placeOrder();
    if (!mounted || created == null) return;

    if (created.paymentMethod == 'VIETQR') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OnlinePaymentScreen(
            order: created,
            onPaymentDone: (ord) {
              Navigator.of(context).pop();
              widget.onOrderCompleted(ord);
            },
          ),
        ),
      );
    } else {
      await KtxDialog.showOrderSuccess(
        context,
        orderCode: created.orderCode,
        onTrackOrder: () {
          Navigator.of(context).pop();
          widget.onOrderCompleted(created);
        },
        onSkipToPickup: () async {
          Navigator.of(context).pop();
          try {
            await OrderService().updateOrderStatus(
              orderId: created.id,
              newStatus: 'DELIVERING',
            );
          } catch (_) {}
          final delivering = created.copyWith(status: 'DELIVERING');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => PickupQrCodeScreen(order: delivering)),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartCheckoutViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Giỏ hàng Gom đơn KTX',
        subtitle: cartVm.storeName.isNotEmpty ? cartVm.storeName : null,
      ),
      body: cartVm.items.isEmpty
          ? KtxEmptyState(
              title: 'Giỏ hàng gom đơn đang trống',
              message:
                  'Hãy chọn món ăn tại các quán liên kết KTX để được hưởng phí ship gom đơn chỉ 5.000đ.',
              actionLabel: 'Quay lại chọn món',
              onAction: () => Navigator.of(context).pop(),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (cartVm.errorMessage != null) ...[
                  KtxErrorState(
                    message: cartVm.errorMessage!,
                    isInlineBanner: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _buildSectionCard(
                  title: '1. Chọn Ca gom đơn KTX (BR-ORD-03)',
                  child: Column(
                    children: CartCheckoutViewModel.ktxShifts.map((shift) {
                      return RadioListTile<String>(
                        value: shift['code']!,
                        groupValue: cartVm.selectedSlotTime,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          shift['label']!,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) cartVm.setSlotTime(val);
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSectionCard(
                  title: '2. Điểm giao nhận chuẩn hóa tại KTX (BR-ORD-04)',
                  child: DropdownButtonFormField<String>(
                    initialValue: cartVm.selectedPickupLocation,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: CartCheckoutViewModel.ktxPickupLocations
                        .map(
                          (loc) => DropdownMenuItem(
                            value: loc,
                            child: Text(
                              loc,
                              style: AppTypography.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) cartVm.setPickupLocation(val);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSectionCard(
                  title: '3. Danh sách món đã chọn (${cartVm.totalItemCount} món)',
                  child: Column(
                    children: List.generate(cartVm.items.length, (idx) {
                      final item = cartVm.items[idx];
                      final optsText = item.selectedOptions
                          .map((o) => '${o.group}: ${o.choice}')
                          .join(', ');
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.itemName,
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (optsText.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      optsText,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(item.totalPrice),
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      cartVm.updateQuantity(idx, -1),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: AppTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      cartVm.updateQuantity(idx, 1),
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSectionCard(
                  title: '4. Ghi chú & Phương thức thanh toán',
                  child: Column(
                    children: [
                      KtxTextField(
                        label: 'Ghi chú cho quán / shipper',
                        hintText: 'Ví dụ: Xin thêm ớt và nước mắm ngọt...',
                        controller: _noteCtrl,
                        prefixIcon: Icons.edit_note_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      RadioListTile<String>(
                        value: 'VIETQR',
                        groupValue: cartVm.selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chuyển khoản VietQR Napas 247'),
                        subtitle: const Text(
                          'Tự động điền số tiền và nội dung ORD_<ID>',
                        ),
                        secondary: const Icon(
                          Icons.qr_code_2_rounded,
                          color: AppColors.primary,
                        ),
                        onChanged: (val) {
                          if (val != null) cartVm.setPaymentMethod(val);
                        },
                      ),
                      RadioListTile<String>(
                        value: 'COD',
                        groupValue: cartVm.selectedPaymentMethod,
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tiền mặt khi nhận tại cổng KTX (COD)'),
                        subtitle: const Text(
                          'Thanh toán trực tiếp cho shipper tại trụ KTX',
                        ),
                        secondary: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.success,
                        ),
                        onChanged: (val) {
                          if (val != null) cartVm.setPaymentMethod(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSectionCard(
                  title: '5. Chi tiết thanh toán',
                  child: Column(
                    children: [
                      _buildPriceRow(
                        'Tạm tính (${cartVm.totalItemCount} phần)',
                        _formatCurrency(cartVm.subtotalAmount),
                      ),
                      const SizedBox(height: 6),
                      _buildPriceRow(
                        'Phí giao hàng gom đơn KTX (đã giảm 10.000đ)',
                        _formatCurrency(cartVm.deliveryFee),
                      ),
                      const Divider(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng thanh toán',
                            style: AppTypography.heading3,
                          ),
                          Text(
                            _formatCurrency(cartVm.finalAmount),
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                KtxButton(
                  label:
                      'Xác nhận đặt đơn • ${_formatCurrency(cartVm.finalAmount)}',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: cartVm.isSubmitting,
                  onPressed: () => _handlePlaceOrder(cartVm),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
