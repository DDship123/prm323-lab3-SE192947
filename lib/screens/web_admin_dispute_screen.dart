import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dispute_model.dart';
import '../services/dispute_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_button.dart';

/// Màn hình Web Admin Trọng tài Khiếu nại Món hỏng: Xem ảnh bằng chứng phân giải cao và quyết định hoàn tiền
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

  @override
  void initState() {
    super.initState();
    _loadDisputes();
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
        orderId: 1,
        userId: 1,
        reason: 'Hộp cơm bị vỡ nát khi nhận',
        description: 'Món cơm sườn bị bung nắp, nước mắm đổ lênh láng ra túi đựng khi shipper giao tới sảnh KTX BA1.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
        status: DisputeStatus.pending,
        refundAmount: 45000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      DisputeModel(
        id: 102,
        orderId: 2,
        userId: 1,
        reason: 'Giao nhầm món ăn',
        description: 'Đặt Bún bò gân giòn nhưng nhận được Bún chả cua, không đúng khẩu phần đặt.',
        evidenceImageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600',
        status: DisputeStatus.pending,
        refundAmount: 50000,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<DisputeModel> get _filteredDisputes {
    if (_statusFilter == 'ALL') return _disputes;
    return _disputes.where((d) => d.status.name.toUpperCase() == _statusFilter).toList();
  }

  Future<void> _resolveDispute(bool approved) async {
    if (_selectedDispute == null) return;
    final id = _selectedDispute!.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approved ? 'Duyệt hoàn tiền cho Sinh viên?' : 'Từ chối khiếu nại?'),
        content: Text(
          approved
              ? 'Số tiền ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_selectedDispute!.refundAmount)} sẽ được hoàn vào ví của Sinh viên KTX.'
              : 'Khiếu nại sẽ bị đóng với lý do bằng chứng chưa đủ xác thực.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: approved ? AppColors.success : AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(approved ? 'Xác nhận Hoàn tiền' : 'Xác nhận Từ chối'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await widget.disputeService.resolveDispute(
        id,
        isApproved: approved,
        adminNotes: approved ? 'Admin Web BQL duyệt: Ảnh chụp món hỏng hợp lệ' : 'Admin Web BQL: Ảnh chưa chứng minh lỗi từ cửa hàng',
      );
      if (mounted) {
        setState(() {
          final idx = _disputes.indexWhere((d) => d.id == id);
          if (idx != -1) {
            _disputes[idx] = updated;
            _selectedDispute = updated;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Đã duyệt hoàn tiền thành công!' : 'Đã từ chối khiếu nại.'),
            backgroundColor: approved ? AppColors.success : AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: AppColors.error),
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
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Text('Không thể tải ảnh bằng chứng'),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (_isLoading && _disputes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột bên trái: Danh sách khiếu nại (Master)
            SizedBox(
              width: isDesktop ? 380 : constraints.maxWidth * 0.45,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  children: [
                    // Header bộ lọc
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Khiếu Nại Đơn Hàng', style: AppTypography.heading3),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, size: 20),
                                onPressed: _loadDisputes,
                                tooltip: 'Tải lại',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'ALL', label: Text('Tất cả', style: TextStyle(fontSize: 12))),
                              ButtonSegment(value: 'PENDING', label: Text('Chờ duyệt', style: TextStyle(fontSize: 12))),
                              ButtonSegment(value: 'APPROVED', label: Text('Đã duyệt', style: TextStyle(fontSize: 12))),
                            ],
                            selected: {_statusFilter},
                            onSelectionChanged: (set) => setState(() => _statusFilter = set.first),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Danh sách item khiếu nại
                    Expanded(
                      child: _filteredDisputes.isEmpty
                          ? const Center(child: Text('Không có khiếu nại nào'))
                          : ListView.separated(
                              itemCount: _filteredDisputes.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _filteredDisputes[index];
                                final isSelected = _selectedDispute?.id == item.id;

                                return ListTile(
                                  selected: isSelected,
                                  selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
                                  title: Text(
                                    '#DIS-${item.id} • Đơn #${item.orderId}',
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    item.reason,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption,
                                  ),
                                  trailing: _buildStatusBadge(item.status),
                                  onTap: () => setState(() => _selectedDispute = item),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Cột bên phải: Chi tiết Khiếu nại & Xem ảnh bằng chứng món hỏng (Detail)
            Expanded(
              child: _selectedDispute == null
                  ? const Center(child: Text('Chọn một khiếu nại từ danh sách để xem chi tiết'))
                  : Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header chi tiết
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Chi Tiết Trọng Tài #DIS-${_selectedDispute!.id}', style: AppTypography.heading2),
                                    const SizedBox(height: 4),
                                    Text('Đơn hàng: #${_selectedDispute!.orderId} • Người gửi: Sinh viên KTX', style: AppTypography.bodySmall),
                                  ],
                                ),
                                _buildStatusBadge(_selectedDispute!.status, isLarge: true),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Thẻ thông tin sự cố & số tiền hoàn
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Lý do: ${_selectedDispute!.reason}', style: AppTypography.heading3.copyWith(fontSize: 16)),
                                      Text(
                                        'Yêu cầu hoàn: ${currencyFormatter.format(_selectedDispute!.refundAmount)}',
                                        style: AppTypography.heading3.copyWith(color: AppColors.error, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(_selectedDispute!.description, style: AppTypography.bodyMedium),
                                  const SizedBox(height: 16),

                                  // Khu vực hiển thị Ảnh bằng chứng món hỏng (Lab 3 requirement)
                                  Text(
                                    'Ảnh bằng chứng món hỏng (Cloud Storage / Cloudinary):',
                                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_selectedDispute!.evidenceImageUrl != null && _selectedDispute!.evidenceImageUrl!.isNotEmpty)
                                    InkWell(
                                      onTap: () => _showZoomImage(_selectedDispute!.evidenceImageUrl!),
                                      child: Container(
                                        height: 240,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              _selectedDispute!.evidenceImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Center(child: Text('Không thể tải ảnh')),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                                    SizedBox(width: 4),
                                                    Text('Nhấn để phóng to kiểm tra', style: TextStyle(color: Colors.white, fontSize: 12)),
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
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceVariant,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Sinh viên không đính kèm ảnh bằng chứng.'),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Các nút hành động Admin ra phán quyết
                            if (_selectedDispute!.status == DisputeStatus.pending)
                              Row(
                                children: [
                                  Expanded(
                                    child: KtxButton(
                                      label: 'Từ chối khiếu nại',
                                      variant: KtxButtonVariant.outline,
                                      icon: Icons.cancel_outlined,
                                      onPressed: () => _resolveDispute(false),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: KtxButton(
                                      label: 'Duyệt hoàn tiền cho Sinh viên',
                                      variant: KtxButtonVariant.primary,
                                      icon: Icons.check_circle_outline,
                                      onPressed: () => _resolveDispute(true),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: AppColors.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Khiếu nại này đã được phân xử với kết quả ${_selectedDispute!.status.label}.',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(DisputeStatus status, {bool isLarge = false}) {
    Color bg;
    Color fg;
    switch (status) {
      case DisputeStatus.pending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
        break;
      case DisputeStatus.approved:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case DisputeStatus.rejected:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      case DisputeStatus.cancelled:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 12 : 8, vertical: isLarge ? 6 : 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: isLarge ? 13 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
