import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/commission_policy_service.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Theo Dõi Dòng Tiền & Tài Chính KTX
/// Tập trung giám sát toàn bộ dòng tiền thu/chi, đối soát COD, dòng tiền VietQR
/// và tỷ lệ phân bổ doanh thu giữa Sàn KTX, Quán ăn đối tác và Shipper
class WebAdminCashflowScreen extends StatefulWidget {
  final OrderService orderService;

  const WebAdminCashflowScreen({
    super.key,
    required this.orderService,
  });

  @override
  State<WebAdminCashflowScreen> createState() => _WebAdminCashflowScreenState();
}

class _WebAdminCashflowScreenState extends State<WebAdminCashflowScreen> {
  bool _isLoading = true;
  List<OrderDetailModel> _orders = [];
  String _selectedSlotFilter = 'ALL';
  String _selectedPaymentMethod = 'ALL';
  String _selectedPaymentStatus = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  double _commissionRate = 10.0;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final rate = await CommissionPolicyService().loadCommissionRate();
      _commissionRate = rate > 0 ? rate : 10.0;

      final list = await widget.orderService.fetchAllOrdersForAdmin();
      if (mounted) {
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    }
  }

  List<OrderDetailModel> get _filteredOrders {
    return _orders.where((o) {
      if (_selectedSlotFilter != 'ALL') {
        if (_selectedSlotFilter == 'CA_TRUA' && !o.slotTime.contains('TRUA')) return false;
        if (_selectedSlotFilter == 'CA_TOI' && !o.slotTime.contains('TOI')) return false;
      }
      if (_selectedPaymentMethod != 'ALL') {
        if (_selectedPaymentMethod == 'VIETQR' && o.paymentMethod != 'VIETQR') return false;
        if (_selectedPaymentMethod == 'COD' && o.paymentMethod == 'VIETQR') return false;
      }
      if (_selectedPaymentStatus != 'ALL' && o.paymentStatus != _selectedPaymentStatus) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final code = o.orderCode.toLowerCase();
        final store = o.storeName.toLowerCase();
        final loc = o.pickupLocation.toLowerCase();
        return code.contains(q) || store.contains(q) || loc.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1050;

    // Tính toán các chỉ số dòng tiền
    final paidOrders = filtered.where((o) => o.paymentStatus == 'PAID').toList();
    final totalInflow = paidOrders.fold(0.0, (sum, o) => sum + o.finalAmount);
    final vietQrInflow = paidOrders
        .where((o) => o.paymentMethod == 'VIETQR')
        .fold(0.0, (sum, o) => sum + o.finalAmount);
    final codInflow = paidOrders
        .where((o) => o.paymentMethod != 'VIETQR')
        .fold(0.0, (sum, o) => sum + o.finalAmount);

    final totalSubtotal = paidOrders.fold(0.0, (sum, o) => sum + o.subtotalAmount);
    final platformCommission = totalSubtotal * (_commissionRate / 100.0);
    final payableToStores = totalSubtotal - platformCommission;
    final payableToShippers = paidOrders.fold(0.0, (sum, o) => sum + o.deliveryFee);

    final refundedAmount = filtered
        .where((o) => o.paymentStatus == 'REFUNDED')
        .fold(0.0, (sum, o) => sum + o.finalAmount);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSpacing.md),
                  Text('Đang tải dữ liệu dòng tiền hệ thống...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TIÊU ĐỀ & NÚT LÀM MỚI
                  _buildHeader(),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. 6 THẺ CHỈ SỐ DÒNG TIỀN (CASHFLOW METRICS)
                  _buildCashflowCards(
                    totalInflow: totalInflow,
                    vietQrInflow: vietQrInflow,
                    codInflow: codInflow,
                    platformCommission: platformCommission,
                    payableToStores: payableToStores,
                    payableToShippers: payableToShippers,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. THANH TRỰC QUAN PHÂN BỔ DÒNG TIỀN (DISTRIBUTION BAR)
                  _buildDistributionBar(
                    totalInflow: totalInflow,
                    payableToStores: payableToStores,
                    payableToShippers: payableToShippers,
                    platformCommission: platformCommission,
                    refundedAmount: refundedAmount,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 4. THANH TÌM KIẾM & BỘ LỌC GIAO DỊCH
                  _buildFilterBar(),

                  const SizedBox(height: AppSpacing.md),

                  // 5. BẢNG NHẬT KÝ DÒNG TIỀN CHI TIẾT
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else if (isDesktop)
                    _buildCashflowTable(filtered)
                  else
                    _buildCashflowCardList(filtered),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theo Dõi Dòng Tiền & Tài Chính KTX', style: AppTypography.heading2),
            const SizedBox(height: 4),
            Text(
              'Giám sát dòng tiền vào (Inflow), tiền chuyển khoản VietQR, tiền mặt COD và phân bổ doanh thu đối tác',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.roundedSm,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.percent_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Chiết khấu sàn: ${_commissionRate.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'Tải lại dữ liệu',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _loadData,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashflowCards({
    required double totalInflow,
    required double vietQrInflow,
    required double codInflow,
    required double platformCommission,
    required double payableToStores,
    required double payableToShippers,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 950
            ? (constraints.maxWidth - 5 * 12) / 6
            : (constraints.maxWidth > 650 ? (constraints.maxWidth - 2 * 12) / 3 : (constraints.maxWidth - 12) / 2);

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard('Tổng Dòng Tiền Vào', currencyFormatter.format(totalInflow), Icons.account_balance_wallet_rounded, AppColors.success, cardWidth),
            _buildMetricCard('Dòng Tiền VietQR', currencyFormatter.format(vietQrInflow), Icons.qr_code_2_rounded, Colors.indigo, cardWidth),
            _buildMetricCard('Dòng Tiền Mặt COD', currencyFormatter.format(codInflow), Icons.payments_rounded, Colors.teal, cardWidth),
            _buildMetricCard('Thu Chiết Khấu Sàn', currencyFormatter.format(platformCommission), Icons.savings_rounded, AppColors.primary, cardWidth),
            _buildMetricCard('Phải Trả Quán Ăn', currencyFormatter.format(payableToStores), Icons.storefront_rounded, Colors.orange.shade800, cardWidth),
            _buildMetricCard('Phí Ship Trả Fleet', currencyFormatter.format(payableToShippers), Icons.delivery_dining_rounded, Colors.purple, cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.heading3.copyWith(color: color, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar({
    required double totalInflow,
    required double payableToStores,
    required double payableToShippers,
    required double platformCommission,
    required double refundedAmount,
  }) {
    final hasData = totalInflow > 0;
    final storePct = hasData ? (payableToStores / totalInflow) * 100 : 80.0;
    final shipperPct = hasData ? (payableToShippers / totalInflow) * 100 : 10.0;
    final platformPct = hasData ? (platformCommission / totalInflow) * 100 : 10.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text('Tỷ Lệ Phân Bổ Dòng Tiền Thực Nhận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              if (refundedAmount > 0)
                Text(
                  'Đã hoàn tiền sự cố: ${currencyFormatter.format(refundedAmount)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.roundedFull,
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  Expanded(
                    flex: storePct.round(),
                    child: Container(color: Colors.orange.shade700),
                  ),
                  Expanded(
                    flex: shipperPct.round(),
                    child: Container(color: Colors.purple),
                  ),
                  Expanded(
                    flex: platformPct.round(),
                    child: Container(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _buildLegendItem('Quán đối tác: ${storePct.toStringAsFixed(1)}% (${currencyFormatter.format(payableToStores)})', Colors.orange.shade700),
              _buildLegendItem('Đội ngũ Shipper: ${shipperPct.toStringAsFixed(1)}% (${currencyFormatter.format(payableToShippers)})', Colors.purple),
              _buildLegendItem('Chiết khấu Sàn KTX: ${platformPct.toStringAsFixed(1)}% (${currencyFormatter.format(platformCommission)})', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm mã đơn hàng, quán ăn, sảnh KTX...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedPaymentStatus,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    style: AppTypography.bodySmall,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Tất cả trạng thái tiền')),
                      DropdownMenuItem(value: 'PAID', child: Text('Đã thanh toán (PAID)')),
                      DropdownMenuItem(value: 'PENDING', child: Text('Chờ thu tiền (PENDING)')),
                      DropdownMenuItem(value: 'REFUNDED', child: Text('Đã hoàn tiền (REFUNDED)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedPaymentStatus = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'Tất cả phương thức', _selectedPaymentMethod, (v) => setState(() => _selectedPaymentMethod = v)),
                _buildFilterChip('VIETQR', '💳 VietQR (Napas 247)', _selectedPaymentMethod, (v) => setState(() => _selectedPaymentMethod = v)),
                _buildFilterChip('COD', '💵 Tiền mặt (COD)', _selectedPaymentMethod, (v) => setState(() => _selectedPaymentMethod = v)),
                const VerticalDivider(width: 20),
                _buildFilterChip('ALL', 'Mọi ca gom', _selectedSlotFilter, (v) => setState(() => _selectedSlotFilter = v)),
                _buildFilterChip('CA_TRUA', '☀️ Ca gom trưa', _selectedSlotFilter, (v) => setState(() => _selectedSlotFilter = v)),
                _buildFilterChip('CA_TOI', '🌙 Ca gom tối', _selectedSlotFilter, (v) => setState(() => _selectedSlotFilter = v)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String val, String label, String currentVal, ValueChanged<String> onChanged) {
    final isSelected = currentVal == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onChanged(val),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedFull,
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        ),
      ),
    );
  }

  Widget _buildCashflowTable(List<OrderDetailModel> orders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, 1100.0);

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.roundedMd,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.2), // Mã Đơn & Ca gom
                    1: FlexColumnWidth(1.0), // Thời Gian
                    2: FlexColumnWidth(2.3), // Quán Ăn & Sảnh KTX
                    3: FlexColumnWidth(0.9), // Hình Thức
                    4: FlexColumnWidth(1.1), // Dòng Tiền Thu
                    5: FlexColumnWidth(1.0), // Phí Sàn (+)
                    6: FlexColumnWidth(1.1), // Trả Quán (-)
                    7: FlexColumnWidth(0.9), // Trả Ship (-)
                    8: FlexColumnWidth(1.1), // Trạng Thái
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: TableBorder(
                    horizontalInside: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceVariant,
                      ),
                      children: [
                        _buildTableHeaderCell('Mã Đơn'),
                        _buildTableHeaderCell('Thời Gian'),
                        _buildTableHeaderCell('Quán Ăn & Sảnh KTX'),
                        _buildTableHeaderCell('Hình Thức'),
                        _buildTableHeaderCell('Dòng Tiền Thu'),
                        _buildTableHeaderCell('Phí Sàn (+)'),
                        _buildTableHeaderCell('Trả Quán (-)'),
                        _buildTableHeaderCell('Trả Ship (-)'),
                        _buildTableHeaderCell('Trạng Thái'),
                      ],
                    ),
                    for (final order in orders)
                      _buildCashflowTableRow(order),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  TableRow _buildCashflowTableRow(OrderDetailModel order) {
    final isVietQr = order.paymentMethod == 'VIETQR';
    final commFee = order.subtotalAmount * (_commissionRate / 100.0);
    final storePayable = order.subtotalAmount - commFee;

    return TableRow(
      children: [
        // 0. Mã Đơn & Ca gom
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order.orderCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                order.slotTime.contains('TRUA') ? 'Ca trưa 11h30' : 'Ca tối 17h30',
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        // 1. Thời Gian
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            DateFormat('HH:mm • dd/MM').format(order.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ),

        // 2. Quán Ăn & Sảnh KTX
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                order.storeName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                order.pickupLocation,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 3. Hình Thức
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVietQr ? Icons.qr_code_2_rounded : Icons.payments_rounded,
                size: 16,
                color: isVietQr ? Colors.indigo : Colors.teal,
              ),
              const SizedBox(width: 4),
              Text(
                isVietQr ? 'VietQR' : 'COD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isVietQr ? Colors.indigo : Colors.teal,
                ),
              ),
            ],
          ),
        ),

        // 4. Dòng Tiền Thu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            currencyFormatter.format(order.finalAmount),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
          ),
        ),

        // 5. Phí Sàn (+)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            '+${currencyFormatter.format(commFee)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppColors.primary),
          ),
        ),

        // 6. Trả Quán (-)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            '-${currencyFormatter.format(storePayable)}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.orange.shade800),
          ),
        ),

        // 7. Trả Ship (-)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            '-${currencyFormatter.format(order.deliveryFee)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.purple),
          ),
        ),

        // 8. Trạng Thái
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildPaymentStatusBadge(order.paymentStatus),
          ),
        ),
      ],
    );
  }

  Widget _buildCashflowCardList(List<OrderDetailModel> orders) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final order = orders[idx];
        final isVietQr = order.paymentMethod == 'VIETQR';
        final commFee = order.subtotalAmount * (_commissionRate / 100.0);
        final storePayable = order.subtotalAmount - commFee;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(isVietQr ? Icons.qr_code_2_rounded : Icons.payments_rounded, size: 18, color: isVietQr ? Colors.indigo : Colors.teal),
                      const SizedBox(width: 6),
                      Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  _buildPaymentStatusBadge(order.paymentStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text('${order.storeName} ➔ ${order.pickupLocation}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dòng tiền thu khách:', style: AppTypography.bodySmall),
                  Text(currencyFormatter.format(order.finalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phí sàn thu (+${_commissionRate.toStringAsFixed(0)}%):', style: AppTypography.caption),
                  Text('+${currencyFormatter.format(commFee)}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trả quán đối tác:', style: AppTypography.caption),
                  Text('-${currencyFormatter.format(storePayable)}', style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Phí ship trả fleet:', style: AppTypography.caption),
                  Text('-${currencyFormatter.format(order.deliveryFee)}', style: const TextStyle(fontSize: 12, color: Colors.purple)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'PAID':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'ĐÃ THU TIỀN';
        break;
      case 'REFUNDED':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'ĐÃ HOÀN TIỀN';
        break;
      case 'PENDING':
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        label = 'CHỜ THU';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.roundedSm),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Không có giao dịch dòng tiền nào phù hợp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Hãy thử thay đổi điều kiện tìm kiếm hoặc đổi bộ lọc phương thức thanh toán', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedSlotFilter = 'ALL';
                _selectedPaymentMethod = 'ALL';
                _selectedPaymentStatus = 'ALL';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Đặt lại bộ lọc'),
          ),
        ],
      ),
    );
  }
}
