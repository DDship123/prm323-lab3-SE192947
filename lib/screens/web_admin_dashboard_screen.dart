import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_dashboard_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Dashboard chuẩn Design System KTX Food (Figma Lab 2 & 3)
/// Đồng bộ 100% với Brand Primary Orange (#FF5722) và Typography hệ thống
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= BANNER CHÀO MỪNG CHUẨN BRAND KTX FOOD =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.roundedLg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: AppRadius.roundedFull,
                            ),
                            child: const Text(
                              'HỆ THỐNG GOM ĐƠN KTX ĐHQG',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            'Ca gom trưa đang hoạt động',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Xin chào, Ban Quản Lý KTX ĐHQG 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hôm nay có 18 đơn gom Ca trưa đang được giao đến các sảnh BA1 và BA2. Đã ghi nhận 3 khiếu nại món hỏng cần xử lý.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: onNavigateDisputes,
                  icon: const Icon(Icons.assignment_late_rounded, size: 16),
                  label: const Text('Xử lý Khiếu nại ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ================= 4 THẺ CHỈ SỐ KPI CHÍNH =================
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Tổng doanh thu gom đơn',
                  value: currencyFormatter.format(stats.totalRevenue),
                  subtitle: 'Tích lũy từ toàn bộ ca KTX',
                  icon: Icons.payments_rounded,
                  iconColor: AppColors.primary,
                  trendText: '+18.4% tuần này',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildKpiCard(
                  title: 'Tổng đơn hàng đã xử lý',
                  value: '${stats.totalOrders} đơn',
                  subtitle: '${stats.activeOrders} đơn đang giao ca này',
                  icon: Icons.receipt_long_rounded,
                  iconColor: AppColors.info,
                  trendText: '18 đơn gom ca trưa',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildKpiCard(
                  title: 'Khiếu nại cần xử lý',
                  value: '${stats.pendingDisputes} sự cố',
                  subtitle: 'Cần xem ảnh bồi hoàn',
                  icon: Icons.assignment_late_rounded,
                  iconColor: AppColors.error,
                  trendText: 'Yêu cầu xử lý gấp',
                  trendIsWarning: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildKpiCard(
                  title: 'Tỉ lệ giải quyết thành công',
                  value: '${stats.disputeResolutionRate}%',
                  subtitle: 'Sinh viên & Quán ăn hài lòng',
                  icon: Icons.verified_rounded,
                  iconColor: AppColors.success,
                  trendText: 'Đạt chuẩn SLA KTX',
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // ================= 2 THẺ CHI TIẾT TIẾN ĐỘ & NHẬT KÝ =================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ tiến độ gom đơn theo ca
              Expanded(
                flex: 5,
                child: Container(
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
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                                  borderRadius: AppRadius.roundedSm,
                                ),
                                child: const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 18),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Tiến Độ Gom Đơn Theo Ca', style: AppTypography.heading3.copyWith(fontSize: 16)),
                            ],
                          ),
                          TextButton(
                            onPressed: onNavigateOrders,
                            child: Text(
                              'Xem toàn bộ đơn',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mô hình gom đơn Lab 3 theo khung giờ cố định để tối ưu phí vận chuyển 5.000đ/đơn.',
                        style: AppTypography.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildShiftProgressRow(
                        shiftName: 'Ca Trưa KTX Khu B (11:30 - 12:30)',
                        status: 'Đang giao (12 đơn)',
                        progress: 0.85,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildShiftProgressRow(
                        shiftName: 'Ca Chiều KTX Khu A (17:30 - 18:30)',
                        status: 'Chờ chốt sổ (6 đơn)',
                        progress: 0.45,
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildShiftProgressRow(
                        shiftName: 'Ca Tối KTX Toàn Khu (20:00 - 21:00)',
                        status: 'Mở đặt (3 đơn)',
                        progress: 0.15,
                        color: AppColors.info,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              // Thẻ nhật ký hoạt động hệ thống
              Expanded(
                flex: 4,
                child: Container(
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
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.roundedSm,
                                ),
                                child: const Icon(Icons.bolt_rounded, color: AppColors.info, size: 18),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text('Nhật Ký Thời Gian Thực', style: AppTypography.heading3.copyWith(fontSize: 16)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              borderRadius: AppRadius.roundedFull,
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.circle, color: AppColors.success, size: 6),
                                SizedBox(width: 4),
                                Text('Live Sync', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.recentActivities.length,
                        separatorBuilder: (context, index) => const Divider(height: 16, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final act = stats.recentActivities[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildActivityIcon(act.type),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      act.title,
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      act.description,
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                act.timeAgo,
                                style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    required Color iconColor,
    required String trendText,
    bool trendIsWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.heading1.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: trendIsWarning ? AppColors.errorLight : AppColors.surfaceVariant,
              borderRadius: AppRadius.roundedSm,
            ),
            child: Text(
              trendText,
              style: TextStyle(
                color: trendIsWarning ? AppColors.error : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftProgressRow({
    required String shiftName,
    required String status,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(shiftName, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.roundedFull,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityIcon(AdminActivityType type) {
    IconData icon;
    Color color;
    switch (type) {
      case AdminActivityType.dispute:
        icon = Icons.assignment_late_rounded;
        color = AppColors.error;
        break;
      case AdminActivityType.delivery:
        icon = Icons.local_shipping_rounded;
        color = AppColors.primary;
        break;
      case AdminActivityType.store:
        icon = Icons.storefront_rounded;
        color = AppColors.warning;
        break;
      case AdminActivityType.system:
        icon = Icons.settings_rounded;
        color = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}
