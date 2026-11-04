import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

/// Màn hình Web Admin Giám sát Đơn hàng KTX phong cách Greenova / Full-width Table
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
      final list = await widget.orderService.fetchMyOrders();
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
        paymentMethod: 'COD',
        paymentStatus: 'PAID',
        subtotalAmount: 50000,
        groupDiscountAmount: 5000,
        deliveryFee: 5000,
        finalAmount: 50000,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        items: const [
          OrderItemModel(
            id: 2,
            menuItemId: 4,
            itemName: 'Bún bò tái nạm gầu',
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
        pickupLocation: 'Cổng 1 KTX Khu A (Bàn 2)',
        pickupPin: '7392',
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
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ chứa toàn bộ giao diện bảng dữ liệu
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header của Bảng: Tìm kiếm & Bộ lọc Tab
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bộ lọc Tab phong cách Greenova
                        Row(
                          children: [
                            _buildFilterPill('ALL', 'Tất cả đơn (${_orders.length})'),
                            const SizedBox(width: 8),
                            _buildFilterPill('DELIVERING', 'Đang giao'),
                            const SizedBox(width: 8),
                            _buildFilterPill('DELIVERED', 'Đã nhận'),
                            const SizedBox(width: 8),
                            _buildFilterPill('PENDING', 'Chờ xử lý'),
                          ],
                        ),

                        // Tìm kiếm nhỏ & Nút Reload
                        Row(
                          children: [
                            Container(
                              width: 260,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                onChanged: (val) => setState(() => _searchQuery = val),
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                                  hintText: 'Lọc nhanh bảng...',
                                  hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                              onPressed: _loadOrders,
                              tooltip: 'Làm mới bảng',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFFF1F5F9), height: 1),

                  // Bảng dữ liệu chiếm trọn 100% chiều ngang
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredOrders.isEmpty
                            ? const Center(
                                child: Text('Không tìm thấy đơn hàng nào phù hợp', style: TextStyle(color: Color(0xFF94A3B8))),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    headingTextStyle: const TextStyle(
                                      color: Color(0xFF475569),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                    dataRowMaxHeight: 64,
                                    horizontalMargin: 24,
                                    columnSpacing: 28,
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
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.receipt_rounded, size: 16, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                order.orderCode,
                                                style: const TextStyle(
                                                  color: Color(0xFF0F172A),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            order.storeName,
                                            style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                order.slotTime,
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                order.pickupLocation,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFCBD5E1)),
                                            ),
                                            child: Text(
                                              order.pickupPin,
                                              style: const TextStyle(
                                                fontFamily: 'monospace',
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                letterSpacing: 2,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            currencyFormatter.format(order.finalAmount),
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            order.paymentMethod,
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        DataCell(_buildOrderStatusBadge(order.status)),
                                      ]);
                                    }).toList(),
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
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'Đang giao';
        break;
      case 'DELIVERED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Đã nhận';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Đã hủy';
        break;
      default:
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        label = 'Chờ xử lý';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
