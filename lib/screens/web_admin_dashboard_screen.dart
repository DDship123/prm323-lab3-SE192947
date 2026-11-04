import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_dashboard_model.dart';
import '../services/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Dashboard: Thống kê KPI, trạng thái gom đơn KTX và nhật ký sự cố
class WebAdminDashboardScreen extends StatelessWidget {
  final AdminDashboardStatsModel stats;
  final VoidCallback? onNavigateDisputes;
  final VoidCallback? onNavigateOrders;

  const WebAdminDashboardScreen({
    super.key,
    required this.stats,
    this.onNavigateDisputes,
    this.onNavigateOrders,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner chào đón & trạng thái hệ thống
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bảng Điều Khiển Quản Trị KTX', style: AppTypography.heading1),
                  const SizedBox(height: 4),
                  Text(
                    'Giám sát hoạt động gom đơn, tài xế, quán ăn và trọng tài sự cố trên Web',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: AppColors.success, size: 10),
                    const SizedBox(width: 8),
                    Text(
                      'Backend: ${ApiConfig.baseUrl}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Lưới các thẻ KPI chỉ số chính
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _buildKpiCard(
                    title: 'Tổng doanh thu gom đơn',
                    value: currencyFormatter.format(stats.totalRevenue),
                    subtitle: 'Cập nhật từ toàn bộ đơn KTX',
                    icon: Icons.payments_rounded,
                    color: Colors.green,
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                  ),
                  _buildKpiCard(
                    title: 'Tổng đơn hàng đã xử lý',
                    value: '${stats.totalOrders} đơn',
                    subtitle: '${stats.activeOrders} đơn đang giao ca này',
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.primary,
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    onTap: onNavigateOrders,
                  ),
                  _buildKpiCard(
                    title: 'Khiếu nại cần phân xử',
                    value: '${stats.pendingDisputes} vụ việc',
                    subtitle: 'Yêu cầu Admin xem ảnh bằng chứng',
                    icon: Icons.gavel_rounded,
                    color: stats.pendingDisputes > 0 ? AppColors.error : AppColors.success,
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                    onTap: onNavigateDisputes,
                  ),
                  _buildKpiCard(
                    title: 'Tỉ lệ giải quyết thành công',
                    value: '${stats.disputeResolutionRate}%',
                    subtitle: 'Sinh viên & quán ăn hài lòng',
                    icon: Icons.verified_rounded,
                    color: Colors.teal,
                    width: isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Phần nội dung 2 cột: Hoạt động gần đây & Giám sát ca gom KTX
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRecentActivitiesSection()),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 2, child: _buildCampusSlotsSummarySection()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRecentActivitiesSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildCampusSlotsSummarySection(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTypography.heading2.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(subtitle, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Container(
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
              Text('Nhật Ký Hoạt Động Hệ Thống', style: AppTypography.heading3),
              const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...stats.recentActivities.map((act) => _buildActivityRow(act)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(AdminRecentActivityItem item) {
    IconData icon;
    Color color;
    switch (item.type) {
      case AdminActivityType.dispute:
        icon = Icons.warning_amber_rounded;
        color = AppColors.error;
        break;
      case AdminActivityType.delivery:
        icon = Icons.local_shipping_rounded;
        color = Colors.blue;
        break;
      case AdminActivityType.store:
        icon = Icons.store_rounded;
        color = Colors.orange;
        break;
      case AdminActivityType.system:
        icon = Icons.info_outline;
        color = Colors.purple;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    Text(item.timeAgo, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusSlotsSummarySection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tình Trạng Gom Đơn Theo Ca', style: AppTypography.heading3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Phục vụ mô hình Lab 3 gom đơn theo khung giờ để tối ưu phí ship',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSlotRow('Ca Trưa Khu B (11:30 - 12:30)', 'Đang giao (12 đơn)', Colors.blue, 0.8),
          const SizedBox(height: 14),
          _buildSlotRow('Ca Chiều Khu A (17:30 - 18:30)', 'Chờ chốt sổ (6 đơn)', Colors.orange, 0.4),
          const SizedBox(height: 14),
          _buildSlotRow('Ca Tối KTX (20:00 - 21:00)', 'Mở đặt (3 đơn)', Colors.green, 0.2),
        ],
      ),
    );
  }

  Widget _buildSlotRow(String title, String status, Color color, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            Text(status, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }
}
