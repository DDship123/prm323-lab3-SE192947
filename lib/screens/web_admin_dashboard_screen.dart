import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_dashboard_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/admin_commission_settings_card.dart';
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSmall = width < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isSmall ? AppSpacing.sm : AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= BANNER CHÀO MỪNG CHUẨN BRAND KTX FOOD =================
              _buildBanner(isSmall),

              const SizedBox(height: AppSpacing.lg),

              // ================= 4 THẺ CHỈ SỐ KPI CHÍNH =================
              _buildKpiSection(width, currencyFormatter),

              const SizedBox(height: AppSpacing.lg),

              // ================= CẤU HÌNH CHÍNH SÁCH CHIẾT KHẤU SÀN DÀNH CHO ADMIN =================
              AdminCommissionSettingsCard(totalRevenue: stats.totalRevenue),

              const SizedBox(height: AppSpacing.lg),

              // ================= 2 THẺ CHI TIẾT TIẾN ĐỘ & NHẬT KÝ =================
              if (width < 850) ...[
                _buildProgressPanel(),
                const SizedBox(height: AppSpacing.lg),
                _buildActivityPanel(),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _buildProgressPanel()),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 4, child: _buildActivityPanel()),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner(bool isSmall) {
    final bannerInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hôm nay có 18 đơn gom Ca trưa đang được giao đến các sảnh BA1 và BA2. Đã ghi nhận 3 khiếu nại món hỏng cần xử lý.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );

    final actionBtn = ElevatedButton.icon(
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
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? AppSpacing.md : AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
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
      child: isSmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bannerInfo,
                const SizedBox(height: AppSpacing.md),
                actionBtn,
              ],
            )
          : Row(
              children: [
                Expanded(child: bannerInfo),
                const SizedBox(width: AppSpacing.md),
                actionBtn,
              ],
            ),
    );
  }

  Widget _buildKpiSection(double width, NumberFormat currencyFormatter) {
    final card1 = _buildKpiCard(
      title: 'Tổng doanh thu gom đơn',
      value: currencyFormatter.format(stats.totalRevenue),
      subtitle: 'Tích lũy từ toàn bộ ca KTX',
      icon: Icons.payments_rounded,
      iconColor: AppColors.primary,
      trendText: '+18.4% tuần này',
    );
    final card2 = _buildKpiCard(
      title: 'Tổng đơn hàng đã xử lý',
      value: '${stats.totalOrders} đơn',
      subtitle: '${stats.activeOrders} đơn đang giao ca này',
      icon: Icons.receipt_long_rounded,
      iconColor: AppColors.info,
      trendText: '18 đơn gom ca trưa',
    );
    final card3 = _buildKpiCard(
      title: 'Khiếu nại cần xử lý',
      value: '${stats.pendingDisputes} sự cố',
      subtitle: 'Cần xem ảnh bồi hoàn',
      icon: Icons.assignment_late_rounded,
      iconColor: AppColors.error,
      trendText: 'Yêu cầu xử lý gấp',
      trendIsWarning: true,
    );
    final card4 = _buildKpiCard(
      title: 'Tỉ lệ giải quyết thành công',
      value: '${stats.disputeResolutionRate}%',
      subtitle: 'Sinh viên & Quán ăn hài lòng',
      icon: Icons.verified_rounded,
      iconColor: AppColors.success,
      trendText: 'Đạt chuẩn SLA KTX',
    );

    if (width < 600) {
      return Column(
        children: [
          card1,
          const SizedBox(height: AppSpacing.sm),
          card2,
          const SizedBox(height: AppSpacing.sm),
          card3,
          const SizedBox(height: AppSpacing.sm),
          card4,
        ],
      );
    } else if (width < 1000) {
      return Column(
        children: [
          Row(children: [Expanded(child: card1), const SizedBox(width: AppSpacing.md), Expanded(child: card2)]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [Expanded(child: card3), const SizedBox(width: AppSpacing.md), Expanded(child: card4)]),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(child: card1),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: card2),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: card3),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: card4),
        ],
      );
    }
  }

  Widget _buildProgressPanel() {
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
    );
  }

  Widget _buildActivityPanel() {
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
          Column(
            children: [
              for (int i = 0; i < stats.recentActivities.length; i++) ...[
                if (i > 0) const Divider(height: 16, color: AppColors.border),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivityIcon(stats.recentActivities[i].type),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.recentActivities[i].title,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stats.recentActivities[i].description,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      stats.recentActivities[i].timeAgo,
                      style: const TextStyle(fontSize: 10, color: AppColors.textHint),
                    ),
                  ],
                ),
              ],
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
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            Expanded(
              child: Text(
                shiftName,
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
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
