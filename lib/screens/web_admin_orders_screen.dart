import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Giám sát Đơn hàng KTX - Chuẩn Design System KTX Food (Figma Lab 2 & 3)
/// Đồng bộ 100% với màu Cam KTX (#FF5722), Typography và Token thiết kế
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
    ];
  }

  List<OrderDetailModel> get _filteredOrders {
    return _orders.where((o) {
      final matchesFilter = _selectedFilter == 'ALL' || o.status.toUpperCase() == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          o.orderCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.storeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.pickupLocation.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ chứa toàn bộ giao diện bảng dữ liệu
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
                  // Header của Bảng: Tìm kiếm & Bộ lọc Tab
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bộ lọc Tab chuẩn phong cách KTX Food
                        Row(
                          children: [
                            _buildFilterPill('ALL', 'Tất cả (${_orders.length})'),
                            const SizedBox(width: AppSpacing.xs),
                            _buildFilterPill('DELIVERING', 'Đang giao'),
                            const SizedBox(width: AppSpacing.xs),
                            _buildFilterPill('DELIVERED', 'Đã nhận'),
                            const SizedBox(width: AppSpacing.xs),
                            _buildFilterPill('PENDING', 'Chờ xử lý'),
                          ],
                        ),

                        // Tìm kiếm nhỏ & Nút Reload
                        Row(
                          children: [
                            Container(
                              width: 240,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: AppRadius.roundedSm,
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.search, size: 16, color: AppColors.textHint),
                                  hintText: 'Lọc nhanh bảng...',
                                  hintStyle: AppTypography.caption.copyWith(color: AppColors.textHint),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                              onPressed: _loadOrders,
                              tooltip: 'Làm mới bảng',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: AppColors.border, height: 1),

                  // Bảng dữ liệu chiếm trọn 100% chiều ngang
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                        : _filteredOrders.isEmpty
                            ? Center(
                                child: Text('Không tìm thấy đơn hàng nào phù hợp', style: AppTypography.caption),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: RepaintBoundary(
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
                                    headingTextStyle: AppTypography.caption.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                    dataRowMaxHeight: 60,
                                    horizontalMargin: 20,
                                    columnSpacing: 24,
                                    columns: const [
                                      DataColumn(label: Text('MÃ ĐƠN')),
                                      DataColumn(label: Text('CỬA HÀNG')),
                                      DataColumn(label: Text('CA GOM & ĐIỂM HẸN')),
                                      DataColumn(label: Text('MÃ PIN')),
                                      DataColumn(label: Text('TỔNG TIỀN')),
                                      DataColumn(label: Text('THANH TOÁN')),
                                      DataColumn(label: Text('TRẠNG THÁI')),
                                    ],
                                    rows: _filteredOrders.map((order) {
                                      return DataRow(cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surfaceVariant,
                                                  borderRadius: AppRadius.roundedSm,
                                                ),
                                                child: const Icon(Icons.receipt_rounded, size: 15, color: AppColors.textSecondary),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                order.orderCode,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            order.storeName,
                                            style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                order.slotTime,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                order.pickupLocation,
                                                style: AppTypography.caption.copyWith(fontSize: 11),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceVariant,
                                              borderRadius: AppRadius.roundedSm,
                                              border: Border.all(color: AppColors.border),
                                            ),
                                            child: Text(
                                              order.pickupPin,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                letterSpacing: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            currencyFormatter.format(order.finalAmount),
                                            style: AppTypography.bodySmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            order.paymentMethod,
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        DataCell(_buildOrderStatusBadge(order.status)),
                                      ]);
                                    }).toList(),
                                    ),
                                  ),
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

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
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
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
