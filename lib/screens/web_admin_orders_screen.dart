import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Giám sát Toàn Bộ Đơn Hàng KTX - Chuẩn Figma Lab 2 & 3
/// Mở rộng bảng 100% full width, không khoảng trắng thừa, hỗ trợ phân trang & lọc chi tiết
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
  List<OrderDetailModel> _orders = [];
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  // Quản lý phân trang
  int _currentPage = 1;
  int _rowsPerPage = 8;
  final List<int> _availableRowsPerPage = [5, 8, 10, 15];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.orderService.fetchAllOrdersForAdmin();
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

  List<OrderDetailModel> _mockOrders() {
    return [
      OrderDetailModel(
        id: 1,
        orderCode: 'KTX-ORD-1001',
        userId: 1,
        storeId: 1,
        storeName: 'Cơm Tấm Cô Ba KTX',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Sảnh Tòa BA1 - KTX Khu B',
        pickupPin: '4829',
        pickupQrCode: 'QR_1001',
        status: 'DELIVERING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 90000,
        groupDiscountAmount: 10000,
        deliveryFee: 5000,
        finalAmount: 85000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        items: const [
          OrderItemModel(
            id: 1,
            menuItemId: 1,
            itemName: 'Cơm sườn bì chả đặc biệt',
            quantity: 2,
            unitPrice: 45000,
            itemTotalAmount: 90000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 2,
        orderCode: 'KTX-ORD-1002',
        userId: 1,
        storeId: 2,
        storeName: 'Bún Bò Huế O Phượng',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Sảnh Tòa BA2 - KTX Khu B',
        pickupPin: '1934',
        pickupQrCode: 'QR_1002',
        status: 'DELIVERED',
        paymentMethod: 'TIỀN MẶT',
        paymentStatus: 'PAID',
        subtotalAmount: 50000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 50000,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        items: const [
          OrderItemModel(
            id: 2,
            menuItemId: 2,
            itemName: 'Bún bò tái nạm chả',
            quantity: 1,
            unitPrice: 50000,
            itemTotalAmount: 50000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 3,
        orderCode: 'KTX-ORD-1003',
        userId: 1,
        storeId: 1,
        storeName: 'Cơm Tấm Cô Ba KTX',
        slotTime: 'Ca chiều 17:30 - 18:30',
        pickupLocation: 'Trụ A1-A2 - KTX Khu A',
        pickupPin: '6521',
        pickupQrCode: 'QR_1003',
        status: 'PENDING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'UNPAID',
        subtotalAmount: 45000,
        groupDiscountAmount: 0,
        deliveryFee: 5000,
        finalAmount: 50000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        items: const [
          OrderItemModel(
            id: 3,
            menuItemId: 1,
            itemName: 'Cơm sườn trứng ốp la',
            quantity: 1,
            unitPrice: 45000,
            itemTotalAmount: 45000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 4,
        orderCode: 'KTX-ORD-1004',
        userId: 2,
        storeId: 3,
        storeName: 'Bánh Mì Chảo Cô Út',
        slotTime: 'Ca sáng 07:00 - 08:00',
        pickupLocation: 'Sảnh Tòa C3 - KTX Khu A',
        pickupPin: '8812',
        pickupQrCode: 'QR_1004',
        status: 'DELIVERED',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 35000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 35000,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        items: const [
          OrderItemModel(
            id: 4,
            menuItemId: 3,
            itemName: 'Bánh mì chảo xíu mại trứng lòng đào',
            quantity: 1,
            unitPrice: 35000,
            itemTotalAmount: 35000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 5,
        orderCode: 'KTX-ORD-1005',
        userId: 3,
        storeId: 4,
        storeName: 'Trà Sữa TocoToco KTX',
        slotTime: 'Ca chiều 15:00 - 16:00',
        pickupLocation: 'Sảnh Tòa BA4 - KTX Khu B',
        pickupPin: '3145',
        pickupQrCode: 'QR_1005',
        status: 'DELIVERING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 62000,
        groupDiscountAmount: 6000,
        deliveryFee: 5000,
        finalAmount: 61000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        items: const [
          OrderItemModel(
            id: 5,
            menuItemId: 4,
            itemName: 'Trà sữa Ba Anh Em (Size L)',
            quantity: 2,
            unitPrice: 31000,
            itemTotalAmount: 62000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 6,
        orderCode: 'KTX-ORD-1006',
        userId: 4,
        storeId: 5,
        storeName: 'Hủ Tiếu Nam Vang Dì Năm',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Cổng KTX Khu B - Điểm Hẹn 1',
        pickupPin: '9021',
        pickupQrCode: 'QR_1006',
        status: 'DELIVERED',
        paymentMethod: 'TIỀN MẶT',
        paymentStatus: 'PAID',
        subtotalAmount: 45000,
        groupDiscountAmount: 0,
        deliveryFee: 5000,
        finalAmount: 50000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        items: const [
          OrderItemModel(
            id: 6,
            menuItemId: 5,
            itemName: 'Hủ tiếu khô tôm thịt',
            quantity: 1,
            unitPrice: 45000,
            itemTotalAmount: 45000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 7,
        orderCode: 'KTX-ORD-1007',
        userId: 5,
        storeId: 6,
        storeName: 'Cơm Gà Xối Mỡ 142',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Sảnh Tòa BB1 - KTX Khu B',
        pickupPin: '7734',
        pickupQrCode: 'QR_1007',
        status: 'DELIVERING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 55000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 55000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        items: const [
          OrderItemModel(
            id: 7,
            menuItemId: 6,
            itemName: 'Cơm đùi gà xối mỡ giòn rụm',
            quantity: 1,
            unitPrice: 55000,
            itemTotalAmount: 55000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 8,
        orderCode: 'KTX-ORD-1008',
        userId: 6,
        storeId: 7,
        storeName: 'Bún Đậu Mắm Tôm A Chảnh',
        slotTime: 'Ca tối 19:00 - 20:00',
        pickupLocation: 'Sảnh Tòa A2 - KTX Khu A',
        pickupPin: '2341',
        pickupQrCode: 'QR_1008',
        status: 'PENDING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 65000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 65000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
        items: const [
          OrderItemModel(
            id: 8,
            menuItemId: 7,
            itemName: 'Mẹt bún đậu thập cẩm đặc biệt',
            quantity: 1,
            unitPrice: 65000,
            itemTotalAmount: 65000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 9,
        orderCode: 'KTX-ORD-1009',
        userId: 7,
        storeId: 8,
        storeName: 'Cà Phê Muối Chú Long',
        slotTime: 'Ca sáng 08:00 - 09:00',
        pickupLocation: 'Trụ B1-B2 - KTX Khu B',
        pickupPin: '5612',
        pickupQrCode: 'QR_1009',
        status: 'DELIVERED',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 30000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 30000,
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        items: const [
          OrderItemModel(
            id: 9,
            menuItemId: 8,
            itemName: 'Cà phê muối kem béo thơm',
            quantity: 1,
            unitPrice: 30000,
            itemTotalAmount: 30000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 10,
        orderCode: 'KTX-ORD-1010',
        userId: 8,
        storeId: 9,
        storeName: 'Nem Nướng Nha Trang Cô Ba',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Sảnh Tòa BA3 - KTX Khu B',
        pickupPin: '4019',
        pickupQrCode: 'QR_1010',
        status: 'DELIVERING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 70000,
        groupDiscountAmount: 7000,
        deliveryFee: 5000,
        finalAmount: 68000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        items: const [
          OrderItemModel(
            id: 10,
            menuItemId: 9,
            itemName: 'Phần nem nướng cuốn bánh tráng rau sống',
            quantity: 1,
            unitPrice: 70000,
            itemTotalAmount: 70000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 11,
        orderCode: 'KTX-ORD-1011',
        userId: 9,
        storeId: 10,
        storeName: 'Chè Bưởi & Trà Trái Cây',
        slotTime: 'Ca chiều 16:30 - 17:30',
        pickupLocation: 'Sảnh Tòa A5 - KTX Khu A',
        pickupPin: '1198',
        pickupQrCode: 'QR_1011',
        status: 'DELIVERED',
        paymentMethod: 'TIỀN MẶT',
        paymentStatus: 'PAID',
        subtotalAmount: 38000,
        groupDiscountAmount: 0,
        deliveryFee: 5000,
        finalAmount: 43000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        items: const [
          OrderItemModel(
            id: 11,
            menuItemId: 10,
            itemName: 'Chè bưởi An Giang cốt dừa',
            quantity: 1,
            unitPrice: 38000,
            itemTotalAmount: 38000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 12,
        orderCode: 'KTX-ORD-1012',
        userId: 10,
        storeId: 1,
        storeName: 'Cơm Tấm Cô Ba KTX',
        slotTime: 'Ca tối 18:30 - 19:30',
        pickupLocation: 'Sảnh Tòa BA2 - KTX Khu B',
        pickupPin: '6670',
        pickupQrCode: 'QR_1012',
        status: 'PENDING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'UNPAID',
        subtotalAmount: 48000,
        groupDiscountAmount: 0,
        deliveryFee: 5000,
        finalAmount: 53000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        items: const [
          OrderItemModel(
            id: 12,
            menuItemId: 1,
            itemName: 'Cơm sườn nướng mỡ hành',
            quantity: 1,
            unitPrice: 48000,
            itemTotalAmount: 48000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 13,
        orderCode: 'KTX-ORD-1013',
        userId: 11,
        storeId: 11,
        storeName: 'Mì Quảng Phố Hội',
        slotTime: 'Ca trưa 11:30 - 12:30',
        pickupLocation: 'Cổng KTX Khu A - Điểm Hẹn 2',
        pickupPin: '8342',
        pickupQrCode: 'QR_1013',
        status: 'DELIVERED',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 45000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 45000,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        items: const [
          OrderItemModel(
            id: 13,
            menuItemId: 11,
            itemName: 'Mì Quảng tôm thịt trứng cút',
            quantity: 1,
            unitPrice: 45000,
            itemTotalAmount: 45000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 14,
        orderCode: 'KTX-ORD-1014',
        userId: 12,
        storeId: 12,
        storeName: 'Gà Rán & Khoai Lắc KTX',
        slotTime: 'Ca tối 20:00 - 21:00',
        pickupLocation: 'Sảnh Tòa BA5 - KTX Khu B',
        pickupPin: '9514',
        pickupQrCode: 'QR_1014',
        status: 'DELIVERING',
        paymentMethod: 'VIETQR',
        paymentStatus: 'PAID',
        subtotalAmount: 92000,
        groupDiscountAmount: 10000,
        deliveryFee: 5000,
        finalAmount: 87000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        items: const [
          OrderItemModel(
            id: 14,
            menuItemId: 12,
            itemName: 'Combo 2 miếng gà cay + khoai lắc phô mai',
            quantity: 1,
            unitPrice: 92000,
            itemTotalAmount: 92000,
          ),
        ],
      ),
      OrderDetailModel(
        id: 15,
        orderCode: 'KTX-ORD-1015',
        userId: 13,
        storeId: 13,
        storeName: 'Bún Riêu Cua Đồng 79',
        slotTime: 'Ca sáng 07:30 - 08:30',
        pickupLocation: 'Trụ A3 - KTX Khu A',
        pickupPin: '3022',
        pickupQrCode: 'QR_1015',
        status: 'DELIVERED',
        paymentMethod: 'TIỀN MẶT',
        paymentStatus: 'PAID',
        subtotalAmount: 40000,
        groupDiscountAmount: 0,
        deliveryFee: 5000,
        finalAmount: 45000,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        items: const [
          OrderItemModel(
            id: 15,
            menuItemId: 13,
            itemName: 'Bún riêu ốc đậu hũ chả lụa',
            quantity: 1,
            unitPrice: 40000,
            itemTotalAmount: 40000,
          ),
        ],
      ),
    ];
  }

  List<OrderDetailModel> get _filteredOrders {
    return _orders.where((o) {
      final matchesFilter =
          _selectedFilter == 'ALL' || o.status.toUpperCase() == _selectedFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          o.orderCode.toLowerCase().contains(query) ||
          o.storeName.toLowerCase().contains(query) ||
          o.pickupLocation.toLowerCase().contains(query) ||
          o.pickupPin.contains(query) ||
          o.slotTime.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
    });
  }

  void _showOrderDetailDialog(OrderDetailModel order) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final timeStr = DateFormat('HH:mm - dd/MM/yyyy').format(order.createdAt);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          width: 580,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.roundedLg,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header modal
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết đơn: ${order.orderCode}',
                          style: AppTypography.heading3.copyWith(fontSize: 16),
                        ),
                        Text(
                          'Tạo lúc: $timeStr',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  _buildOrderStatusBadge(order.status),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Thông tin giao nhận & Ca gom
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.storeName,
                                  style: AppTypography.bodySmall
                                      .copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(order.slotTime,
                                  style: AppTypography.caption),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.pickupLocation,
                                  style: AppTypography.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Column(
                        children: [
                          const Text('MÃ PIN NHẬN',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEA580C))),
                          const SizedBox(height: 4),
                          Text(
                            order.pickupPin,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 2,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text('DANH SÁCH MÓN ĂN',
                  style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 8),

              // Danh sách món ăn
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  separatorBuilder: (_, _) => const Divider(height: 8),
                  itemBuilder: (_, idx) {
                    final it = order.items[idx];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${it.quantity}x ${it.itemName}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(it.itemTotalAmount),
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const Divider(height: 24),

              // Tổng tiền & Thanh toán
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phương thức: ${order.paymentMethod}',
                          style: AppTypography.caption),
                      Text('Trạng thái TT: ${order.paymentStatus}',
                          style: AppTypography.caption.copyWith(
                            color: order.paymentStatus == 'PAID'
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TỔNG THANH TOÁN',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold)),
                      Text(
                        currencyFormatter.format(order.finalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final allFiltered = _filteredOrders;
    final totalCount = allFiltered.length;
    final totalPages = math.max(1, (totalCount / _rowsPerPage).ceil());

    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = math.min(startIndex + _rowsPerPage, totalCount);
    final pagedOrders = totalCount > 0
        ? allFiltered.sublist(startIndex, endIndex)
        : <OrderDetailModel>[];

    // Đếm số lượng theo status
    final deliveringCount =
        _orders.where((o) => o.status.toUpperCase() == 'DELIVERING').length;
    final deliveredCount =
        _orders.where((o) => o.status.toUpperCase() == 'DELIVERED').length;
    final pendingCount =
        _orders.where((o) => o.status.toUpperCase() == 'PENDING').length;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ chứa toàn bộ bảng dữ liệu giám sát
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 1. Header Bảng: Bộ lọc Tab & Ô tìm kiếm
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tabs bộ lọc
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterPill(
                                'ALL', 'Tất cả (${_orders.length})'),
                            _buildFilterPill(
                                'DELIVERING', 'Đang giao ($deliveringCount)'),
                            _buildFilterPill(
                                'DELIVERED', 'Đã nhận ($deliveredCount)'),
                            _buildFilterPill(
                                'PENDING', 'Chờ xử lý ($pendingCount)'),
                          ],
                        ),

                        // Thanh tìm kiếm nhanh & Reload
                        Row(
                          children: [
                            Container(
                              width: 260,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: AppRadius.roundedSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.search,
                                      size: 16, color: AppColors.textHint),
                                  hintText:
                                      'Lọc theo mã, quán, điểm hẹn, PIN...',
                                  hintStyle: AppTypography.caption
                                      .copyWith(color: AppColors.textHint),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded,
                                  size: 18, color: AppColors.textSecondary),
                              onPressed: _loadOrders,
                              tooltip: 'Làm mới bảng',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppColors.border, height: 1),

                  // 2. Thân bảng dữ liệu - Mở rộng 100% full width, không khoảng trắng thừa
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary))
                        : allFiltered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.inbox_rounded,
                                        size: 48, color: AppColors.textHint),
                                    const SizedBox(height: 8),
                                    Text('Không tìm thấy đơn hàng nào phù hợp',
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                                color:
                                                    AppColors.textSecondary)),
                                  ],
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: math.max(
                                              constraints.maxWidth, 1050),
                                        ),
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                                  const Color(0xFFF8FAFC)),
                                          headingTextStyle:
                                              AppTypography.caption.copyWith(
                                            color: const Color(0xFF475569),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            letterSpacing: 0.5,
                                          ),
                                          dataRowMinHeight: 56,
                                          dataRowMaxHeight: 64,
                                          horizontalMargin: 20,
                                          columnSpacing: 20,
                                          columns: const [
                                            DataColumn(
                                                label: Text('MÃ ĐƠN HÀNG')),
                                            DataColumn(
                                                label: Text('CỬA HÀNG')),
                                            DataColumn(
                                                label: Text(
                                                    'CA GOM & ĐIỂM HẸN')),
                                            DataColumn(
                                                label: Text('MÃ PIN')),
                                            DataColumn(
                                                label: Text('TỔNG TIỀN')),
                                            DataColumn(
                                                label: Text('THANH TOÁN')),
                                            DataColumn(
                                                label: Text('TRẠNG THÁI')),
                                            DataColumn(
                                                label: Text('THAO TÁC')),
                                          ],
                                          rows: pagedOrders.map((order) {
                                            return DataRow(
                                              cells: [
                                                // Mã đơn hàng
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(6),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: AppColors
                                                              .surfaceVariant,
                                                          borderRadius:
                                                              AppRadius
                                                                  .roundedSm,
                                                        ),
                                                        child: const Icon(
                                                          Icons
                                                              .receipt_rounded,
                                                          size: 15,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        order.orderCode,
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Cửa hàng
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .storefront_outlined,
                                                        size: 15,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        order.storeName,
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Ca gom & Điểm hẹn
                                                DataCell(
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        order.slotTime,
                                                        style: AppTypography
                                                            .bodySmall
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        order.pickupLocation,
                                                        style: AppTypography
                                                            .caption
                                                            .copyWith(
                                                                fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Mã PIN
                                                DataCell(
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 9,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFFFF7ED),
                                                      borderRadius:
                                                          AppRadius.roundedSm,
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFFFFEDD5)),
                                                    ),
                                                    child: Text(
                                                      order.pickupPin,
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        letterSpacing: 2,
                                                        color:
                                                            Color(0xFFEA580C),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Tổng tiền
                                                DataCell(
                                                  Text(
                                                    currencyFormatter
                                                        .format(order
                                                            .finalAmount),
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors
                                                          .textPrimary,
                                                    ),
                                                  ),
                                                ),

                                                // Thanh toán
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        order.paymentMethod,
                                                        style: AppTypography
                                                            .caption
                                                            .copyWith(
                                                          color: AppColors
                                                              .textSecondary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Icon(
                                                        order.paymentStatus ==
                                                                'PAID'
                                                            ? Icons
                                                                .check_circle_rounded
                                                            : Icons
                                                                .pending_rounded,
                                                        size: 13,
                                                        color:
                                                            order.paymentStatus ==
                                                                    'PAID'
                                                                ? AppColors
                                                                    .success
                                                                : AppColors
                                                                    .warning,
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Trạng thái
                                                DataCell(
                                                    _buildOrderStatusBadge(
                                                        order.status)),

                                                // Thao tác xem chi tiết
                                                DataCell(
                                                  InkWell(
                                                    onTap: () =>
                                                        _showOrderDetailDialog(
                                                            order),
                                                    borderRadius:
                                                        AppRadius.roundedSm,
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 5),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .surfaceVariant,
                                                        borderRadius:
                                                            AppRadius.roundedSm,
                                                        border: Border.all(
                                                            color: AppColors
                                                                .border),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .visibility_outlined,
                                                            size: 14,
                                                            color: AppColors
                                                                .primary,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            'Chi tiết',
                                                            style: AppTypography
                                                                .caption
                                                                .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .primary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),

                  // 3. Footer Thanh Phân Trang (Pagination Control)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Thông tin số lượng hiển thị
                        Text(
                          totalCount == 0
                              ? 'Không có đơn hàng nào'
                              : 'Hiển thị ${startIndex + 1} - $endIndex trên tổng số $totalCount đơn hàng (Trang $_currentPage/$totalPages)',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Bộ điều khiển phân trang
                        Row(
                          children: [
                            // Chọn số dòng / trang
                            Text('Số dòng: ', style: AppTypography.caption),
                            Container(
                              height: 30,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: AppRadius.roundedSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _rowsPerPage,
                                  isDense: true,
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  items: _availableRowsPerPage.map((val) {
                                    return DropdownMenuItem<int>(
                                      value: val,
                                      child: Text('$val'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _rowsPerPage = val;
                                        _currentPage = 1;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),

                            // Nút Trang trước
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded,
                                  size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              onPressed: _currentPage > 1
                                  ? () => setState(() => _currentPage--)
                                  : null,
                              tooltip: 'Trang trước',
                            ),

                            // Các nút số trang
                            ...List.generate(totalPages, (idx) {
                              final pageNum = idx + 1;
                              final isCurrent = pageNum == _currentPage;
                              return InkWell(
                                onTap: () =>
                                    setState(() => _currentPage = pageNum),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: isCurrent
                                        ? null
                                        : Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    '$pageNum',
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Nút Trang sau
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded,
                                  size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 32, minHeight: 32),
                              onPressed: _currentPage < totalPages
                                  ? () => setState(() => _currentPage++)
                                  : null,
                              tooltip: 'Trang sau',
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedFilter == key;

    return InkWell(
      onTap: () => _onFilterChanged(key),
      borderRadius: AppRadius.roundedFull,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: AppRadius.roundedFull,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'DELIVERING':
        bg = AppColors.info.withValues(alpha: 0.12);
        fg = AppColors.info;
        label = 'Đang giao';
        break;
      case 'DELIVERED':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'Đã nhận';
        break;
      case 'CANCELLED':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'Đã hủy';
        break;
      default:
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = 'Chờ xử lý';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style:
                TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
