import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/cart_checkout_vm.dart';

/// Màn hình Giỏ Hàng Sinh Viên KTX (S3b - Cart Screen chuẩn Figma)
/// Cho phép xem món đã chọn kèm Size/Topping, điều chỉnh số lượng, chọn món và tiến hành Thanh toán.
class CartScreen extends StatelessWidget {
  final VoidCallback onProceedToCheckout;
  final VoidCallback onExploreMenu;

  const CartScreen({
    super.key,
    required this.onProceedToCheckout,
    required this.onExploreMenu,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  void _confirmClearCart(BuildContext context, CartCheckoutViewModel cartVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Xóa toàn bộ giỏ hàng?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả món ăn trong giỏ hàng không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Giữ lại', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              cartVm.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa hết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartVm = context.watch<CartCheckoutViewModel>();
    final voucherService = context.watch<VoucherService>();
    final items = cartVm.items;
    final selectedCount = cartVm.selectedItemCount;
    final selectedSubtotal = cartVm.selectedSubtotalAmount;
    final defaultVoucher = voucherService.findByCode('SINHVIENKTX');
    const double shipFee = 5000.0;
    final double voucherDiscount = (defaultVoucher != null && defaultVoucher.isValidForStudent)
        ? defaultVoucher.calculateActualDiscount(itemsSubtotal: selectedSubtotal, deliveryFee: shipFee)
        : 0.0;
    final double effectiveShipFee = (shipFee - voucherDiscount).clamp(0, double.infinity);
    final double estimatedFinal = selectedCount > 0 ? (selectedSubtotal + effectiveShipFee) : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF521B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Giỏ Hàng Gom Đơn',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Xóa toàn bộ giỏ hàng',
              icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFF64748B)),
              onPressed: () => _confirmClearCart(context, cartVm),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmptyState(context)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Banner Thông tin Quán ăn
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF521B), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartVm.storeName.isNotEmpty ? cartVm.storeName : 'Quán Ăn KTX Khu B',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  const Row(
                                    children: [
                                      Icon(Icons.flash_on_rounded, size: 13, color: Color(0xFFFF521B)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Đơn gom ca KTX • Tiết kiệm 65% ship',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFC2410C),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Danh sách món ăn trong giỏ
                      ...List.generate(items.length, (index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isSelected ? const Color(0xFFFF521B).withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
                              width: item.isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkbox chọn món
                                  Semantics(
                                    identifier: 'checkbox_cart_item_$index',
                                    label: 'Chọn món ${item.itemName}',
                                    child: Checkbox(
                                      value: item.isSelected,
                                      activeColor: const Color(0xFFFF521B),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (_) => cartVm.toggleItemSelection(index),
                                    ),
                                  ),
                                  // Ảnh món
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                                      width: 68,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 68,
                                        height: 68,
                                        color: Colors.grey.shade100,
                                        child: const Icon(Icons.fastfood_rounded, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Tên món và giá đơn vị
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(item.unitPriceWithOptions),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFFFF521B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Nút xóa món
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    tooltip: 'Bỏ món ${item.itemName}',
                                    onPressed: () => cartVm.removeItem(index),
                                  ),
                                ],
                              ),

                              // Chi tiết Topping / Tùy chọn đã chọn
                              if (item.selectedOptions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: item.selectedOptions.map((opt) {
                                      final priceTag = opt.extraPrice > 0 ? ' (+${_formatCurrency(opt.extraPrice)})' : '';
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${opt.choice}$priceTag',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],

                              // Ghi chú riêng cho món ăn
                              if (item.itemNote != null && item.itemNote!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFEDD5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_note_rounded, size: 14, color: Color(0xFFFF521B)),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            'Ghi chú: ${item.itemNote}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFFC2410C),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 8),

                              // Thành tiền & Bộ điều khiển số lượng
                              Padding(
                                padding: const EdgeInsets.only(left: 48),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Thành tiền: ${_formatCurrency(item.totalPrice)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    // Bộ đếm [-] [Qty] [+]
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Semantics(
                                            identifier: 'btn_cart_decrease_$index',
                                            button: true,
                                            label: 'Giảm số lượng ${item.itemName}',
                                            excludeSemantics: true,
                                            onTap: () => cartVm.updateQuantity(index, -1),
                                            child: InkWell(
                                              onTap: () => cartVm.updateQuantity(index, -1),
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(Icons.remove_rounded, size: 16, color: Color(0xFF475569)),
                                              ),
                                            ),
                                          ),
                                          Semantics(
                                            identifier: 'text_cart_qty_$index',
                                            label: 'Số lượng ${item.itemName}: ${item.quantity}',
                                            excludeSemantics: true,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              child: Text(
                                                '${item.quantity}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          ),
                                          Semantics(
                                            identifier: 'btn_cart_increase_$index',
                                            button: true,
                                            label: 'Tăng số lượng ${item.itemName}',
                                            excludeSemantics: true,
                                            onTap: () => cartVm.updateQuantity(index, 1),
                                            child: InkWell(
                                              onTap: () => cartVm.updateQuantity(index, 1),
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF521B)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Nút chọn thêm món khác
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF521B),
                          side: const BorderSide(color: Color(0xFFFF521B)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: onExploreMenu,
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('+ Thêm món khác từ thực đơn', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),

                      // Tóm tắt chi phí dự kiến
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chi tiết thanh toán',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 10),
                            _buildPriceRow('Tiền món ($selectedCount món đã chọn)', _formatCurrency(selectedSubtotal)),
                            const SizedBox(height: 6),
                            _buildPriceRow('Phí ship gom đơn KTX', _formatCurrency(shipFee), subtitle: '(Tiết kiệm 10k so với ship riêng)'),
                            if (voucherDiscount > 0) ...[
                              const SizedBox(height: 6),
                              _buildPriceRow('Voucher giảm phí ship KTX', '-${_formatCurrency(voucherDiscount)}', highlightColor: const Color(0xFF059669)),
                            ],
                            const Divider(height: 18, color: Color(0xFFF1F5F9)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tạm tính:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(
                                  _formatCurrency(estimatedFinal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFFFF521B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Sticky Bar: Checkbox Chọn tất cả & Nút Thanh Toán
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Chọn tất cả
                        InkWell(
                          onTap: () => cartVm.toggleSelectAll(!cartVm.isAllSelected),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: cartVm.isAllSelected,
                                activeColor: const Color(0xFFFF521B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (val) => cartVm.toggleSelectAll(val ?? false),
                              ),
                              const Text('Tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Cột hiển thị tổng tiền
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Tổng thanh toán', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              _formatCurrency(estimatedFinal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFFFF521B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // Nút Thanh Toán
                        Semantics(
                          identifier: 'btn_cart_checkout',
                          child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selectedCount > 0 ? const Color(0xFFFF521B) : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: selectedCount > 0 ? onProceedToCheckout : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng tích chọn ít nhất 1 món ăn để thanh toán'),
                                backgroundColor: AppColors.error,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            'Thanh toán ($selectedCount)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPriceRow(String label, String value, {String? subtitle, Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            if (subtitle != null) ...[
              const SizedBox(width: 4),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            ],
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: highlightColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 52,
                color: Color(0xFFFF521B),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Giỏ hàng của bạn đang trống',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Chưa có món ăn nào trong giỏ. Hãy dạo một vòng quanh các quán ăn KTX Khu A & Khu B để chọn những món ăn hấp dẫn cho ca gom nhé!',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF521B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: onExploreMenu,
              icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
              label: const Text(
                'Khám phá thực đơn ngay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
