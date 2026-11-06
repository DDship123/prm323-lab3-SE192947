import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Quản Lý Voucher & Khuyến Mãi KTX (Dành cho Ban Quản Lý Admin)
/// Cho phép BQL:
/// 1. Xem danh sách tất cả voucher hệ thống
/// 2. Bật / Tắt (Enable / Disable) tức thì: Khi tắt, sinh viên bị chặn không thể áp dụng
/// 3. Cấu hình số tiền giảm, đơn tối thiểu, số lượt dùng tối đa / tài khoản
/// 4. Phân loại voucher: Giảm phí ship gom đơn vs Giảm tiền món ăn
/// 5. Tạo mới voucher hoặc xóa voucher
class WebAdminVoucherScreen extends StatefulWidget {
  const WebAdminVoucherScreen({super.key});

  @override
  State<WebAdminVoucherScreen> createState() => _WebAdminVoucherScreenState();
}

class _WebAdminVoucherScreenState extends State<WebAdminVoucherScreen> {
  String _searchQuery = '';

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    final voucherService = context.watch<VoucherService>();
    final vouchers = voucherService.vouchers.where((v) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return v.code.toLowerCase().contains(q) ||
          v.title.toLowerCase().contains(q) ||
          v.description.toLowerCase().contains(q);
    }).toList();

    final totalCount = voucherService.vouchers.length;
    final activeCount = voucherService.vouchers.where((v) => v.isActive).length;
    final disabledCount = totalCount - activeCount;
    final totalUsed = voucherService.vouchers.fold<int>(0, (sum, v) => sum + v.usedCount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. STATS OVERVIEW CARDS =================
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      title: 'Tổng Voucher',
                      value: '$totalCount',
                      subtitle: 'Đang lưu trên hệ thống',
                      icon: Icons.confirmation_num_rounded,
                      color: AppColors.primary,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                    _buildStatCard(
                      title: 'Đang Kích Hoạt',
                      value: '$activeCount',
                      subtitle: 'Sinh viên đang dùng được',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                    _buildStatCard(
                      title: 'Đã Tạm Ngưng (Disable)',
                      value: '$disabledCount',
                      subtitle: 'Sinh viên bị chặn áp dụng',
                      icon: Icons.pause_circle_filled_rounded,
                      color: AppColors.error,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                    _buildStatCard(
                      title: 'Lượt SV Đã Dùng',
                      value: '$totalUsed',
                      subtitle: 'Tổng lượt đặt thành công',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.info,
                      width: isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ================= 2. TOOLBAR (SEARCH + ACTIONS) =================
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm voucher theo mã hoặc nội dung...',
                        hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Khôi phục voucher mặc định?'),
                          content: const Text(
                            'Toàn bộ mã sẽ được đặt lại về 3 voucher chuẩn (SINHVIENKTX, FREESHIP5K, KTXDISCOUNT10K).',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await voucherService.resetToDefaults();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã khôi phục danh sách voucher mặc định')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: const Text('Khôi phục gốc'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => _showAddEditVoucherDialog(context),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Tạo Voucher Mới', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ================= 3. BẢNG DANH SÁCH VOUCHER =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.roundedLg,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Danh Sách Mã Giảm Giá Đang Quản Lý (${vouchers.length})',
                          style: AppTypography.heading3.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 6),
                              Text(
                                'Công tắc Bật/Tắt tác động tức thì đến SV trên App',
                                style: AppTypography.caption.copyWith(color: const Color(0xFF1D4ED8), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),

                  if (vouchers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(
                        child: Text('Không tìm thấy voucher nào phù hợp', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        horizontalMargin: AppSpacing.md,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(label: Text('MÃ VOUCHER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('TIÊU ĐỀ & MÔ TẢ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('LOẠI ƯU ĐÃI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('SỐ TIỀN GIẢM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('ĐƠN TỐI THIỂU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('LƯỢT DÙNG / TK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('ĐÃ DÙNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('TRẠNG THÁI (ON/OFF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: vouchers.map((v) {
                          return DataRow(
                            cells: [
                              // Mã voucher
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: v.isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: v.isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    v.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: v.isActive ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ),
                              // Tiêu đề & Mô tả
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 220),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.title,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        v.description,
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Loại ưu đãi
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: v.type == VoucherType.shipping
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    v.type == VoucherType.shipping ? 'Giảm Ship Gom' : 'Giảm Tiền Món',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: v.type == VoucherType.shipping
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFFC2410C),
                                    ),
                                  ),
                                ),
                              ),
                              // Số tiền giảm
                              DataCell(
                                Text(
                                  _formatCurrency(v.discountAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                ),
                              ),
                              // Đơn tối thiểu
                              DataCell(
                                Text(
                                  v.minOrderValue > 0 ? _formatCurrency(v.minOrderValue) : '0đ (Mọi đơn)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              // Lượt dùng / TK
                              DataCell(
                                Text(
                                  '${v.maxUsagePerAccount} lượt/SV',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                              // Đã dùng
                              DataCell(
                                Text(
                                  '${v.usedCount} lần',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ),
                              // Switch On/Off
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: v.isActive,
                                      activeColor: AppColors.success,
                                      inactiveThumbColor: Colors.grey.shade400,
                                      onChanged: (bool newVal) async {
                                        await voucherService.toggleVoucherStatus(v.code, newVal);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                newVal
                                                    ? 'Đã KÍCH HOẠT mã ${v.code} (Sinh viên có thể sử dụng)'
                                                    : 'Đã TẠM NGƯNG mã ${v.code} (Sinh viên bị chặn sử dụng)',
                                              ),
                                              backgroundColor: newVal ? AppColors.success : AppColors.error,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    Text(
                                      v.isActive ? 'Kích hoạt' : 'Tạm ngưng',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: v.isActive ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Thao tác
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Chỉnh sửa voucher',
                                      icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                                      onPressed: () => _showAddEditVoucherDialog(context, existing: v),
                                    ),
                                    IconButton(
                                      tooltip: 'Xóa voucher',
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text('Xác nhận xóa mã ${v.code}?'),
                                            content: const Text('Hành động này sẽ xóa vĩnh viễn voucher khỏi hệ thống.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                                onPressed: () => Navigator.pop(ctx, true),
                                                child: const Text('Xóa ngay', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await voucherService.deleteVoucher(v.code);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Đã xóa mã ${v.code}')),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTypography.heading2.copyWith(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog Thêm mới hoặc Chỉnh sửa Voucher
  void _showAddEditVoucherDialog(BuildContext context, {VoucherModel? existing}) {
    final isEditing = existing != null;
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final discountCtrl = TextEditingController(text: existing?.discountAmount.toInt().toString() ?? '10000');
    final minOrderCtrl = TextEditingController(text: existing?.minOrderValue.toInt().toString() ?? '0');
    final maxUsageCtrl = TextEditingController(text: existing?.maxUsagePerAccount.toString() ?? '3');
    VoucherType selectedType = existing?.type ?? VoucherType.shipping;
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Chỉnh Sửa Voucher' : 'Tạo Voucher Khuyến Mãi Mới',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mã code
                    TextField(
                      controller: codeCtrl,
                      enabled: !isEditing,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Mã Voucher (Code) *',
                        hintText: 'VD: FREESHIP10K, KTXVOUCHER',
                        filled: isEditing,
                        fillColor: isEditing ? const Color(0xFFF1F5F9) : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tiêu đề
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề hiển thị *',
                        hintText: 'VD: Trợ giá ship KTX',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Loại voucher
                    const Text('Loại hình ưu đãi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<VoucherType>(
                            title: const Text('Giảm phí Ship', style: TextStyle(fontSize: 13)),
                            subtitle: const Text('Không trừ vào tiền đồ ăn', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            value: VoucherType.shipping,
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<VoucherType>(
                            title: const Text('Giảm Tiền Món', style: TextStyle(fontSize: 13)),
                            subtitle: const Text('Trừ trực tiếp tiền món', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            value: VoucherType.order,
                            groupValue: selectedType,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (val) => setDialogState(() => selectedType = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Số tiền giảm & Đơn tối thiểu
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: discountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Số tiền giảm (VNĐ) *',
                              suffixText: 'đ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minOrderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Đơn tối thiểu (VNĐ)',
                              suffixText: 'đ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Lượt dùng tối đa mỗi tài khoản
                    TextField(
                      controller: maxUsageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số lượt dùng tối đa / 1 tài khoản SV *',
                        hintText: 'VD: 1, 3, 5 lượt',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Mô tả
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả chi tiết',
                        hintText: 'Mô tả quy tắc áp dụng cho sinh viên xem...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Trạng thái kích hoạt
                    SwitchListTile(
                      title: const Text('Kích hoạt voucher ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(
                        isActive ? 'Sinh viên có thể thấy và sử dụng mã này' : 'Voucher bị khóa, sinh viên không thể dùng',
                        style: TextStyle(fontSize: 11, color: isActive ? AppColors.success : AppColors.error),
                      ),
                      value: isActive,
                      activeColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setDialogState(() => isActive = val),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final code = codeCtrl.text.trim().toUpperCase();
                  final title = titleCtrl.text.trim();
                  final desc = descCtrl.text.trim();
                  final discount = double.tryParse(discountCtrl.text.trim()) ?? 0;
                  final minOrder = double.tryParse(minOrderCtrl.text.trim()) ?? 0;
                  final maxUsage = int.tryParse(maxUsageCtrl.text.trim()) ?? 1;

                  if (code.isEmpty || title.isEmpty || discount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng điền đầy đủ Mã, Tiêu đề và Số tiền giảm hợp lệ')),
                    );
                    return;
                  }

                  final voucher = VoucherModel(
                    code: code,
                    title: title,
                    description: desc.isNotEmpty ? desc : 'Ưu đãi KTX Food',
                    type: selectedType,
                    discountAmount: discount,
                    minOrderValue: minOrder,
                    maxUsagePerAccount: maxUsage,
                    usedCount: existing?.usedCount ?? 0,
                    isActive: isActive,
                  );

                  final service = context.read<VoucherService>();
                  if (isEditing) {
                    await service.updateVoucher(voucher);
                  } else {
                    final ok = await service.createVoucher(voucher);
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mã voucher này đã tồn tại! Vui lòng chọn mã khác.')),
                        );
                      }
                      return;
                    }
                  }

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEditing ? 'Đã cập nhật mã $code' : 'Đã tạo thành công mã $code')),
                    );
                  }
                },
                child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo mới', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}
