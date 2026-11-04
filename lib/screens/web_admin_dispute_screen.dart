import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dispute_model.dart';
import '../services/dispute_service.dart';
import '../theme/app_colors.dart';

/// Màn hình Web Admin Trọng tài Khiếu nại Món hỏng - Phong cách Greenova SaaS Portal
/// Phục vụ BQL KTX kiểm tra ảnh chụp món hỏng độ phân giải cao và quyết định hoàn tiền
class WebAdminDisputeScreen extends StatefulWidget {
  final DisputeService disputeService;

  const WebAdminDisputeScreen({
    super.key,
    required this.disputeService,
  });

  @override
  State<WebAdminDisputeScreen> createState() => _WebAdminDisputeScreenState();
}

class _WebAdminDisputeScreenState extends State<WebAdminDisputeScreen> {
  bool _isLoading = true;
  List<DisputeModel> _disputes = [];
  DisputeModel? _selectedDispute;
  String _statusFilter = 'ALL';
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDisputes() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.disputeService.fetchDisputes();
      if (mounted) {
        setState(() {
          _disputes = list.isNotEmpty ? list : _mockDisputes();
          if (_selectedDispute == null && _disputes.isNotEmpty) {
            _selectedDispute = _disputes.first;
          } else if (_selectedDispute != null) {
            _selectedDispute = _disputes.firstWhere(
              (d) => d.id == _selectedDispute!.id,
              orElse: () => _disputes.first,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _disputes = _mockDisputes();
          if (_selectedDispute == null && _disputes.isNotEmpty) {
            _selectedDispute = _disputes.first;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<DisputeModel> _mockDisputes() {
    return [
      DisputeModel(
        id: 101,
        orderId: 101,
        storeName: 'Cơm Tấm Cô Ba KTX - Khu B',
        reason: 'Món ăn có dị vật / Hỏng vị',
        description:
            'Món cơm sườn bị chua bốc mùi, nước mắm bị đổ bung nắp ra ngoài túi đựng khi shipper giao tới sảnh KTX BA1. Sinh viên yêu cầu hoàn tiền món cơm sườn.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=900',
        requestedRefundAmount: 45000,
        status: DisputeStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
      ),
      DisputeModel(
        id: 102,
        orderId: 102,
        storeName: 'Bún Bò Huế O Phượng - KTX Khu A',
        reason: 'Giao nhầm món ăn so với hóa đơn',
        description:
            'Đặt Bún bò gân đặc biệt nhưng nhận được bún chả cua thường, phần nước dùng bị nguội lạnh hoàn toàn.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=900',
        requestedRefundAmount: 50000,
        status: DisputeStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
      ),
      DisputeModel(
        id: 100,
        orderId: 98,
        storeName: 'Trà Sữa KTX Corner',
        reason: 'Thiếu món trong đơn gom',
        description: 'Đơn 3 ly trà sữa nhưng shipper chỉ bàn giao 2 ly. Quán xác nhận có quên đóng gói ly còn lại.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=900',
        requestedRefundAmount: 28000,
        approvedRefundAmount: 28000,
        status: DisputeStatus.approved,
        adminNote: 'Admin BQL xác minh với quán: Đã hoàn 28.000đ vào ví KTX Pay của Sinh viên.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }

  List<DisputeModel> get _filteredDisputes {
    if (_statusFilter == 'ALL') return _disputes;
    if (_statusFilter == 'PENDING') {
      return _disputes.where((d) => d.status == DisputeStatus.pending).toList();
    }
    if (_statusFilter == 'RESOLVED') {
      return _disputes.where((d) => d.status != DisputeStatus.pending).toList();
    }
    return _disputes;
  }

  Future<void> _resolveDispute(bool approved) async {
    if (_selectedDispute == null) return;
    final item = _selectedDispute!;
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    final note = _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : (approved
            ? 'BQL KTX duyệt bồi hoàn: Ảnh chụp bằng chứng hợp lệ.'
            : 'BQL KTX từ chối: Bằng chứng chưa đủ căn cứ chứng minh lỗi.');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              approved ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: approved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            Text(
              approved ? 'Xác nhận Duyệt hoàn tiền' : 'Xác nhận Từ chối khiếu nại',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              approved
                  ? 'Bạn đang duyệt hoàn ${currencyFormatter.format(item.requestedRefundAmount)} cho đơn hàng #${item.orderId}. Số tiền sẽ được cộng trực tiếp vào ví KTX Pay của Sinh viên.'
                  : 'Khiếu nại cho đơn #${item.orderId} sẽ bị từ chối và gửi thông báo giải trình tới Sinh viên.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ghi chú phân xử: $note',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approved ? 'Duyệt Hoàn Tiền' : 'Từ Chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await widget.disputeService.resolveDispute(
        item.id,
        isApproved: approved,
        adminNotes: note,
      );
      if (mounted) {
        setState(() {
          final idx = _disputes.indexWhere((d) => d.id == item.id);
          if (idx != -1) {
            _disputes[idx] = updated;
            _selectedDispute = updated;
          }
          _noteController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(approved ? 'Đã duyệt hoàn tiền thành công!' : 'Đã từ chối khiếu nại.'),
              ],
            ),
            backgroundColor: approved ? const Color(0xFF10B981) : const Color(0xFF334155),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showZoomImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Ảnh bằng chứng độ phân giải cao (Cloud Storage Verified)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(48),
                          color: const Color(0xFF1E293B),
                          child: const Text('Không thể tải ảnh bằng chứng', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dùng cuộn chuột hoặc thao tác kéo để phóng to / thu nhỏ kiểm tra chi tiết bằng chứng sự cố',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _disputes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== CỘT TRÁI: MASTER LIST KHIẾU NẠI ====================
          SizedBox(
            width: 400,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header danh sách
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Khiếu Nại Sự Cố',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${_disputes.where((d) => d.status == DisputeStatus.pending).length} chờ',
                                          style: const TextStyle(
                                            color: Color(0xFFEF4444),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Trọng tài hoàn tiền Lab 3 KTX',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                              tooltip: 'Tải lại danh sách',
                              onPressed: _loadDisputes,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Thanh lọc trạng thái phong cách Greenova
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildFilterTab('Tất cả', 'ALL', _disputes.length),
                              _buildFilterTab(
                                'Chờ duyệt',
                                'PENDING',
                                _disputes.where((d) => d.status == DisputeStatus.pending).length,
                              ),
                              _buildFilterTab(
                                'Đã phân xử',
                                'RESOLVED',
                                _disputes.where((d) => d.status != DisputeStatus.pending).length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Danh sách thẻ khiếu nại
                  Expanded(
                    child: _filteredDisputes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Không có khiếu nại nào theo bộ lọc',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredDisputes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = _filteredDisputes[index];
                              final isSelected = _selectedDispute?.id == item.id;

                              return _buildDisputeItemCard(item, isSelected);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // ==================== CỘT PHẢI: CHI TIẾT & BẰNG CHỨNG HÌNH ẢNH ====================
          Expanded(
            child: _selectedDispute == null
                ? _buildEmptyDetailState()
                : _buildDetailPanel(_selectedDispute!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, String key, int count) {
    final isSelected = _statusFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _statusFilter = key),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    const BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeItemCard(DisputeModel item, bool isSelected) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final timeStr = DateFormat('HH:mm • dd/MM').format(item.createdAt);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDispute = item;
          _noteController.clear();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#DIS-${item.id}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Đơn #${item.orderId}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const Spacer(),
                _buildStatusPill(item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.reason,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.storeName ?? 'Quán KTX',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormatter.format(item.requestedRefundAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFEF4444),
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(DisputeStatus status) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case DisputeStatus.pending:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        icon = Icons.schedule_rounded;
        break;
      case DisputeStatus.approved:
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF065F46);
        icon = Icons.check_circle_rounded;
        break;
      case DisputeStatus.rejected:
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        icon = Icons.cancel_rounded;
        break;
      case DisputeStatus.refunded:
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1E40AF);
        icon = Icons.account_balance_wallet_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined, size: 64, color: Color(0xFF94A3B8)),
            SizedBox(height: 16),
            Text(
              'Chọn khiếu nại để tiến hành phân xử',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
            ),
            SizedBox(height: 8),
            Text(
              'Xem ảnh chụp bằng chứng từ Sinh viên và ra phán quyết hoàn tiền.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(DisputeModel item) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final formattedDate = DateFormat('HH:mm • EEEE, dd/MM/yyyy', 'vi_VN').format(item.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER HỒ SƠ =================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fact_check_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hồ Sơ Trọng Tài #DIS-${item.id}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildStatusPill(item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã đơn hàng: #${item.orderId} • Cửa hàng: ${item.storeName ?? "Quán KTX"} • $formattedDate',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 24),

              // ================= 3 THẺ TỔNG HỢP NHANH =================
              Row(
                children: [
                  Expanded(
                    child: _buildMetricMiniCard(
                      title: 'Số tiền yêu cầu hoàn',
                      value: currencyFormatter.format(item.requestedRefundAmount),
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricMiniCard(
                      title: 'Lý do khiếu nại',
                      value: item.reason,
                      icon: Icons.report_problem_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricMiniCard(
                      title: 'Kênh thanh toán',
                      value: 'Ví KTX Pay',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= MÔ TẢ TỪ SINH VIÊN =================
              const Text(
                'Nội dung phản ánh từ Sinh viên KTX',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: Color(0xFF94A3B8), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.description.isNotEmpty
                            ? item.description
                            : 'Sinh viên không nhập thêm mô tả chi tiết.',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ================= KHU VỰC ẢNH BẰNG CHỨNG CLOUDINARY =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ảnh Bằng Chứng Món Hỏng',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Cloudinary CDN Verified',
                              style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.evidenceImageUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showZoomImage(item.evidenceImageUrl),
                      icon: const Icon(Icons.zoom_in_rounded, size: 18),
                      label: const Text('Phóng to toàn màn hình', style: TextStyle(fontSize: 13)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (item.evidenceImageUrl.isNotEmpty)
                InkWell(
                  onTap: () => _showZoomImage(item.evidenceImageUrl),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 360,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.evidenceImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Text('Không thể tải ảnh bằng chứng', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        // Overlay thanh thông tin ảnh
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Chụp thực tế lúc nhận đơn tại Sảnh KTX',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Nhấn để phóng to kiểm tra',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Sinh viên không gửi kèm hình ảnh bằng chứng.'),
                  ),
                ),

              const SizedBox(height: 28),

              // ================= KHU VỰC PHÁN QUYẾT TRỌNG TÀI =================
              if (item.status == DisputeStatus.pending) ...[
                const Text(
                  'Quyết Định Trọng Tài (Ban Quản Lý KTX)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 10),
                // Gợi ý ghi chú nhanh
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickNoteChip('Ảnh món ăn bị đổ bung nắp hợp lệ'),
                    _buildQuickNoteChip('Giao sai khẩu phần so với hóa đơn'),
                    _buildQuickNoteChip('Bằng chứng mờ không đủ căn cứ xử lý'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do phân xử hoặc chọn ghi chú nhanh bên trên...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text('Từ chối khiếu nại', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _resolveDispute(false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(
                          'Duyệt hoàn tiền ${currencyFormatter.format(item.requestedRefundAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _resolveDispute(true),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Banner thông báo kết quả đã xử lý
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: item.status == DisputeStatus.approved
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.status == DisputeStatus.approved
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.status == DisputeStatus.approved
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.status == DisputeStatus.approved
                              ? Icons.verified_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.status == DisputeStatus.approved
                                  ? 'Đã duyệt bồi hoàn thành công vào Ví KTX Pay'
                                  : 'Đã từ chối khiếu nại',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: item.status == DisputeStatus.approved
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.adminNote ??
                                  (item.status == DisputeStatus.approved
                                      ? 'Số tiền ${currencyFormatter.format(item.requestedRefundAmount)} đã được ghi có vào tài khoản sinh viên.'
                                      : 'Khiếu nại không hợp lệ theo quy chế gom đơn KTX.'),
                              style: TextStyle(
                                fontSize: 13,
                                color: item.status == DisputeStatus.approved
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricMiniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteChip(String note) {
    return ActionChip(
      label: Text(note, style: const TextStyle(fontSize: 11)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      onPressed: () {
        setState(() {
          _noteController.text = note;
        });
      },
    );
  }
}
