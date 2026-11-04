import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Giám sát toàn bộ Đơn hàng KTX theo Ca gom và Tòa nhà
class WebAdminOrdersScreen extends StatefulWidget {
  final OrderService orderService;

  const WebAdminOrdersScreen({
    super.key,
    required this.orderService,
  });

  @override
  State<WebAdminOrdersScreen> createState() => _WebAdminOrdersScreenState();
}

class _WebAdminOrdersScreenState extends State<WebAdminOrdersScreen> {
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.orderService.fetchOrderHistory();
      if (mounted) {
        setState(() {
          _orders = list.isNotEmpty ? list : _mockOrders();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _orders = _mockOrders();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<OrderModel> _mockOrders() {
    return [
      OrderModel(
        id: 1,
        orderCode: 'KTX-ORD-1001',
        storeId: 1,
        storeName: 'Cơm Tấm Cô Ba KTX',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Sảnh Tòa BA1 - KTX Khu B',
        pickupPin: '4829',
        status: OrderStatus.delivering,
        paymentStatus: PaymentStatus.paid,
        subtotalAmount: 90000,
        groupDiscountAmount: 10000,
        deliveryFee: 5000,
        finalAmount: 85000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        items: [
          const OrderItemModel(
            menuItemId: 1,
            name: 'Cơm sườn bì chả đặc biệt',
            quantity: 2,
            unitPrice: 45000,
            totalPrice: 90000,
          ),
        ],
      ),
      OrderModel(
        id: 2,
        orderCode: 'KTX-ORD-1002',
        storeId: 2,
        storeName: 'Bún Bò Huế O Phượng',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Sảnh Tòa BA2 - KTX Khu B',
        pickupPin: '1934',
        status: OrderStatus.completed,
        paymentStatus: PaymentStatus.paid,
        subtotalAmount: 50000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 50000,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        items: [
          const OrderItemModel(
            menuItemId: 4,
            name: 'Bún bò tái nạm gầu',
            quantity: 1,
            unitPrice: 50000,
            totalPrice: 50000,
          ),
        ],
      ),
    ];
  }

  List<OrderModel> get _filteredOrders {
    if (_selectedFilter == 'ALL') return _orders;
    return _orders.where((o) => o.status.name.toUpperCase() == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Giám Sát Toàn Bộ Đơn Hàng KTX', style: AppTypography.heading1),
                  const SizedBox(height: 4),
                  Text('Theo dõi trạng thái các ca gom đơn tập trung tại các tòa nhà', style: AppTypography.bodySmall),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadOrders,
                tooltip: 'Làm mới danh sách',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bộ lọc trạng thái
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Tất cả (${_orders.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('DELIVERING', 'Đang giao'),
                const SizedBox(width: 8),
                _buildFilterChip('COMPLETED', 'Đã nhận'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING', 'Chờ xác nhận'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Bảng danh sách đơn hàng chuẩn Web
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                        columns: const [
                          DataColumn(label: Text('Mã Đơn', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Quán Ăn', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Ca Gom & Địa Điểm', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Mã PIN', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Tổng Tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Trạng Thái', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _filteredOrders.map((order) {
                          return DataRow(cells: [
                            DataCell(Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(order.storeName)),
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(order.slotTime, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(order.pickupLocation, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            )),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(order.pickupPin, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            )),
                            DataCell(Text(currencyFormatter.format(order.finalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(_buildOrderStatusBadge(order.status)),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOrderStatusBadge(OrderStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case OrderStatus.delivering:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case OrderStatus.completed:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case OrderStatus.cancelled:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      default:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
