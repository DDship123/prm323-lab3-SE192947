import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dispute_model.dart';
import '../services/dispute_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_button.dart';

/// Màn hình Web Admin Xử lý Khiếu nại Món hỏng - Chuẩn Design System KTX Food (Figma Lab 2 & 3)
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

  String _formatDateTime(DateTime dt) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật'
    ];
    final wd = weekdays[dt.weekday - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    return '$h:$min • $wd, $d/$m/$y';
  }

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
          _disputes = list;
          if (_selectedDispute == null && _disputes.isNotEmpty) {
            _selectedDispute = _disputes.first;
          } else if (_selectedDispute != null) {
            _selectedDispute = _disputes.firstWhere(
              (d) => d.id == _selectedDispute!.id,
              orElse: () => _disputes.isNotEmpty ? _disputes.first : _selectedDispute!,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _disputes = [];
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        title: Row(
          children: [
            Icon(
              approved ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: approved ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              approved ? 'Xác nhận Duyệt hoàn tiền' : 'Xác nhận Từ chối khiếu nại',
              style: AppTypography.heading3,
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
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.roundedSm,
              ),
              child: Text(
                'Ghi chú xử lý: $note',
                style: AppTypography.caption.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approved ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
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
                const SizedBox(width: AppSpacing.sm),
                Text(approved ? 'Đã duyệt hoàn tiền thành công!' : 'Đã từ chối khiếu nại.'),
              ],
            ),
            backgroundColor: approved ? AppColors.success : AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: AppColors.error,
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
      builder: (ctx) {
        final screenHeight = MediaQuery.of(ctx).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 850,
              maxHeight: screenHeight * 0.85,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Chuẩn dark surface #0F172A
              borderRadius: AppRadius.roundedLg,
              border: Border.all(color: const Color(0xFF1E293B)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Ảnh bằng chứng độ phân giải cao (Cloud Storage Verified)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                const SizedBox(height: AppSpacing.sm),
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: AppRadius.roundedMd,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          padding: const EdgeInsets.all(48),
                          color: const Color(0xFF1E293B),
                          child: const Center(
                            child: Text(
                              'Không thể tải ảnh bằng chứng',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Dùng cuộn chuột hoặc thao tác kéo để phóng to / thu nhỏ kiểm tra chi tiết bằng chứng',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _disputes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (isMobile) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _selectedDispute != null
                ? _buildDetailPanel(_selectedDispute!, isMobile: true)
                : _buildMasterList(isMobile: true),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== CỘT TRÁI: MASTER LIST KHIẾU NẠI ====================
              SizedBox(
                width: 380,
                child: _buildMasterList(isMobile: false),
              ),

              const SizedBox(width: AppSpacing.lg),

              // ==================== CỘT PHẢI: CHI TIẾT & BẰNG CHỨNG HÌNH ẢNH ====================
              Expanded(
                child: _selectedDispute == null
                    ? _buildEmptyDetailState()
                    : _buildDetailPanel(_selectedDispute!, isMobile: false),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasterList({required bool isMobile}) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header danh sách
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.4),
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: const Icon(
                        Icons.assignment_late_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Xử Lý Khiếu Nại',
                                style: AppTypography.heading3.copyWith(fontSize: 16),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: AppRadius.roundedFull,
                                ),
                                child: Text(
                                  '${_disputes.where((d) => d.status == DisputeStatus.pending).length} chờ',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Xử lý bồi hoàn & sự cố món KTX',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                      tooltip: 'Tải lại danh sách',
                      onPressed: _loadDisputes,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Thanh lọc trạng thái phong cách KTX Food
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.roundedSm,
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
                        'Đã xử lý',
                        'RESOLVED',
                        _disputes.where((d) => d.status != DisputeStatus.pending).length,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Danh sách thẻ khiếu nại
          Expanded(
            child: _filteredDisputes.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 44, color: AppColors.textHint),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Không có khiếu nại nào theo bộ lọc',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: _filteredDisputes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _filteredDisputes[index];
                      final isSelected = _selectedDispute?.id == item.id;

                      return _buildDisputeItemCard(item, isSelected);
                    },
                  ),
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
        borderRadius: AppRadius.roundedSm,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: AppRadius.roundedSm,
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
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.border,
                  borderRadius: AppRadius.roundedFull,
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
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
    final timeStr = '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')} • ${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDispute = item;
          _noteController.clear();
        });
      },
      borderRadius: AppRadius.roundedSm,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: AppRadius.roundedSm,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Text(
                    '#DIS-${item.id}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Đơn #${item.orderId}',
                  style: AppTypography.caption,
                ),
                const Spacer(),
                _buildStatusPill(item.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.reason,
              style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.storefront_rounded, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.storeName ?? 'Quán KTX',
                    style: AppTypography.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormatter.format(item.requestedRefundAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: AppColors.textHint),
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
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        icon = Icons.schedule_rounded;
        break;
      case DisputeStatus.approved:
        bg = AppColors.successLight;
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case DisputeStatus.rejected:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      case DisputeStatus.refunded:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        icon = Icons.account_balance_wallet_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.roundedFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            status.label,
            style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetailState() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 56, color: AppColors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Chọn khiếu nại để tiến hành xử lý',
              style: AppTypography.heading3.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              'Xem ảnh chụp bằng chứng từ Sinh viên và ra quyết định hoàn tiền.',
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPanel(DisputeModel item, {bool isMobile = false}) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final formattedDate = _formatDateTime(item.createdAt);

    final mini1 = _buildMetricMiniCard(
      title: 'Số tiền yêu cầu hoàn',
      value: currencyFormatter.format(item.requestedRefundAmount),
      icon: Icons.monetization_on_rounded,
      color: AppColors.error,
    );
    final mini2 = _buildMetricMiniCard(
      title: 'Lý do khiếu nại',
      value: item.reason,
      icon: Icons.report_problem_rounded,
      color: AppColors.warning,
    );
    final mini3 = _buildMetricMiniCard(
      title: 'Kênh hoàn tiền',
      value: 'Ví KTX Pay',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.primary,
    );

    return Container(
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
      child: ClipRRect(
        borderRadius: AppRadius.roundedMd,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                TextButton.icon(
                  onPressed: () => setState(() => _selectedDispute = null),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Quay lại danh sách khiếu nại', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // ================= HEADER HỒ SƠ =================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: const Icon(Icons.fact_check_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Hồ Sơ Xử Lý Khiếu Nại #DIS-${item.id}',
                                style: AppTypography.heading2.copyWith(fontSize: isMobile ? 16 : 20),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _buildStatusPill(item.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã đơn hàng: #${item.orderId} • Cửa hàng: ${item.storeName ?? "Quán KTX"} • $formattedDate',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.lg),

              // ================= 3 THẺ TỔNG HỢP NHANH =================
              if (isMobile) ...[
                mini1,
                const SizedBox(height: AppSpacing.sm),
                mini2,
                const SizedBox(height: AppSpacing.sm),
                mini3,
              ] else ...[
                Row(
                  children: [
                    Expanded(child: mini1),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: mini2),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: mini3),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ================= MÔ TẢ TỪ SINH VIÊN =================
              Text(
                'Nội dung phản ánh từ Sinh viên KTX',
                style: AppTypography.heading3.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.roundedSm,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.textHint, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.description.isNotEmpty
                            ? item.description
                            : 'Sinh viên không nhập thêm mô tả chi tiết.',
                        style: AppTypography.bodyMedium.copyWith(height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ================= KHU VỰC ẢNH BẰNG CHỨNG CLOUDINARY =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Ảnh Bằng Chứng Món Hỏng',
                        style: AppTypography.heading3.copyWith(fontSize: 14),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Cloudinary CDN Verified',
                              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (item.evidenceImageUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showZoomImage(item.evidenceImageUrl),
                      icon: const Icon(Icons.zoom_in_rounded, size: 16),
                      label: const Text('Phóng to toàn màn hình', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (item.evidenceImageUrl.isNotEmpty)
                InkWell(
                  onTap: () => _showZoomImage(item.evidenceImageUrl),
                  borderRadius: AppRadius.roundedMd,
                  child: Container(
                    height: 320,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          item.evidenceImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Center(
                            child: Text('Không thể tải ảnh bằng chứng', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
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
                                const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 15),
                                const SizedBox(width: 6),
                                const Text(
                                  'Chụp thực tế lúc nhận đơn tại Sảnh KTX',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: AppRadius.roundedFull,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.zoom_in, color: Colors.white, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        'Nhấn để phóng to',
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: const Center(
                    child: Text('Sinh viên không gửi kèm hình ảnh bằng chứng.'),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // ================= KHU VỰC PHÁN QUYẾT XỬ LÝ =================
              if (item.status == DisputeStatus.pending) ...[
                Text(
                  'Quyết Định Xử Lý Khiếu Nại (Ban Quản Lý KTX)',
                  style: AppTypography.heading3.copyWith(fontSize: 14),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickNoteChip('Ảnh món ăn bị đổ bung nắp hợp lệ'),
                    _buildQuickNoteChip('Giao sai khẩu phần so với hóa đơn'),
                    _buildQuickNoteChip('Bằng chứng mờ không đủ căn cứ xử lý'),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Nhập lý do xử lý hoặc chọn ghi chú nhanh bên trên...',
                    hintStyle: AppTypography.caption.copyWith(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: KtxButton(
                        label: 'Từ chối khiếu nại',
                        variant: KtxButtonVariant.danger,
                        icon: Icons.cancel_outlined,
                        onPressed: () => _resolveDispute(false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: KtxButton(
                        label: 'Duyệt hoàn tiền ${currencyFormatter.format(item.requestedRefundAmount)}',
                        variant: KtxButtonVariant.primary,
                        icon: Icons.check_circle_rounded,
                        onPressed: () => _resolveDispute(true),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Banner thông báo kết quả đã xử lý
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: item.status == DisputeStatus.approved
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(
                      color: item.status == DisputeStatus.approved
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.status == DisputeStatus.approved
                              ? AppColors.success
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.status == DisputeStatus.approved
                              ? Icons.verified_rounded
                              : Icons.cancel_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.status == DisputeStatus.approved
                                  ? 'Đã duyệt bồi hoàn thành công vào Ví KTX Pay'
                                  : 'Đã từ chối khiếu nại',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: item.status == DisputeStatus.approved
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.adminNote ??
                                  (item.status == DisputeStatus.approved
                                      ? 'Số tiền ${currencyFormatter.format(item.requestedRefundAmount)} đã được ghi có vào tài khoản sinh viên.'
                                      : 'Khiếu nại không hợp lệ theo quy chế gom đơn KTX.'),
                              style: TextStyle(
                                fontSize: 12,
                                color: item.status == DisputeStatus.approved
                                    ? AppColors.success
                                    : AppColors.error,
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.roundedSm,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
      backgroundColor: AppColors.surfaceVariant,
      side: const BorderSide(color: AppColors.border),
      onPressed: () {
        setState(() {
          _noteController.text = note;
        });
      },
    );
  }
}
