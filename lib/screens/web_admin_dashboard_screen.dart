import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/admin_dashboard_model.dart';

/// Màn hình Web Admin Dashboard thiết kế lại theo phong cách Greenova / Modern SaaS
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
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner chào đón cao cấp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2B20), Color(0xFF1B4D3E)], // Greenova deep gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F2B20).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                            ),
                            child: const Text(
                              'HỆ THỐNG GOM ĐƠN KTX ĐHQG',
                              style: TextStyle(
                                color: Color(0xFF34D399),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Ca gom trưa đang hoạt động',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Xin chào, Ban Quản Lý KTX ĐHQG 👋',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hôm nay có 18 đơn gom Ca trưa đang được giao đến các sảnh BA1 và BA2. Đã ghi nhận 3 khiếu nại món hỏng cần thẩm định.',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onNavigateDisputes,
                  icon: const Icon(Icons.gavel_rounded, size: 16),
                  label: const Text('Xử lý Khiếu nại ngay'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Lưới 4 Thẻ KPI Chỉ số hiện đại
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 960;
              final cardWidth = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildModernKpiCard(
                    title: 'TỔNG DOANH THU',
                    value: currencyFormatter.format(stats.totalRevenue),
                    subtitle: '+18.4% so với tuần trước',
                    isPositive: true,
                    icon: Icons.account_balance_wallet_rounded,
                    gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                    width: cardWidth,
                  ),
                  _buildModernKpiCard(
                    title: 'ĐƠN HÀNG ĐÃ XỬ LÝ',
                    value: '${stats.totalOrders} đơn',
                    subtitle: '${stats.activeOrders} đơn đang giao ca này',
                    isPositive: true,
                    icon: Icons.shopping_bag_rounded,
                    gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    width: cardWidth,
                    onTap: onNavigateOrders,
                  ),
                  _buildModernKpiCard(
                    title: 'KHIẾU NẠI CẦN PHÂN XỬ',
                    value: '${stats.pendingDisputes} vụ việc',
                    subtitle: 'Yêu cầu thẩm định ảnh',
                    isPositive: false,
                    icon: Icons.warning_amber_rounded,
                    gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                    width: cardWidth,
                    onTap: onNavigateDisputes,
                  ),
                  _buildModernKpiCard(
                    title: 'TỈ LỆ HÒA GIẢI THÀNH CÔNG',
                    value: '${stats.disputeResolutionRate}%',
                    subtitle: '+2.1% tỉ lệ hài lòng',
                    isPositive: true,
                    icon: Icons.verified_rounded,
                    gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    width: cardWidth,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // 2 Khối nội dung chính: Tiến độ ca gom KTX & Nhật ký hoạt động
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRecentActivitiesSection()),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildCampusSlotsSummarySection()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRecentActivitiesSection(),
                    const SizedBox(height: 24),
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

  Widget _buildModernKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required bool isPositive,
    required IconData icon,
    required List<Color> gradient,
    required double width,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 16,
              offset: Offset(0, 4),
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
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                const SizedBox(width: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_toggle_off_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Nhật Ký Hoạt Động Thời Gian Thực',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Live Feed', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 12),
          ...stats.recentActivities.map((act) => _buildActivityItem(act)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AdminRecentActivityItem item) {
    IconData icon;
    Color color;
    String typeBadge;
    switch (item.type) {
      case AdminActivityType.dispute:
        icon = Icons.gavel_rounded;
        color = const Color(0xFFEF4444);
        typeBadge = 'Khiếu nại';
        break;
      case AdminActivityType.delivery:
        icon = Icons.local_shipping_rounded;
        color = const Color(0xFF3B82F6);
        typeBadge = 'Vận chuyển';
        break;
      case AdminActivityType.store:
        icon = Icons.storefront_rounded;
        color = const Color(0xFFF59E0B);
        typeBadge = 'Cửa hàng';
        break;
      case AdminActivityType.system:
        icon = Icons.shield_rounded;
        color = const Color(0xFF8B5CF6);
        typeBadge = 'Hệ thống';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeBadge,
                            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampusSlotsSummarySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 8),
              Text(
                'Tiến Độ Gom Đơn Theo Ca',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Phục vụ mô hình Lab 3 gom đơn theo khung giờ để tối ưu phí ship',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 20),
          _buildProgressSlot(
            title: 'Ca Trưa Khu B (11:30 - 12:30)',
            location: 'Sảnh Tòa BA1 & BA2',
            badge: 'Đang giao (12 đơn)',
            color: const Color(0xFF3B82F6),
            progress: 0.85,
          ),
          const SizedBox(height: 18),
          _buildProgressSlot(
            title: 'Ca Chiều Khu A (17:30 - 18:30)',
            location: 'Cổng 1 KTX Khu A',
            badge: 'Chờ chốt sổ (6 đơn)',
            color: const Color(0xFFF59E0B),
            progress: 0.45,
          ),
          const SizedBox(height: 18),
          _buildProgressSlot(
            title: 'Ca Tối KTX (20:00 - 21:00)',
            location: 'Toàn bộ Khu A & B',
            badge: 'Mở nhận đơn (3 đơn)',
            color: const Color(0xFF10B981),
            progress: 0.2,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlot({
    required String title,
    required String location,
    required String badge,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(location, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
