import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Menu thanh bên (Left Vertical Sidebar) chuẩn phong cách Quản trị Hiện đại Greenova / SaaS
class WebAdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const WebAdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF0E1A16), // Dark Forest / Greenova deep slate
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Thương hiệu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)], // Greenova emerald
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'KTX ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Greenova Portal v2.0',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0xFF1E293B), height: 1),
          ),
          const SizedBox(height: 16),

          // Danh sách các danh mục điều hướng
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildSectionLabel('TỔNG QUAN'),
                _buildMenuItem(
                  index: 0,
                  title: 'Bảng Điều Khiển',
                  subtitle: 'KPI & Doanh thu gom ca',
                  icon: Icons.dashboard_rounded,
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('NGHIỆP VỤ QUẢN TRỊ'),
                _buildMenuItem(
                  index: 1,
                  title: 'Trọng Tài Khiếu Nại',
                  subtitle: 'Xem ảnh món hỏng',
                  icon: Icons.gavel_rounded,
                  badgeText: '3',
                  badgeColor: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 6),
                _buildMenuItem(
                  index: 2,
                  title: 'Giám Sát Đơn Hàng',
                  subtitle: 'Tiến độ gom ca KTX',
                  icon: Icons.receipt_long_rounded,
                  badgeText: 'Ca trưa',
                  badgeColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 20),

                _buildSectionLabel('HỆ THỐNG & KẾT NỐI'),
                _buildStaticMenuItem(
                  title: 'Máy Chủ VPS TP.HCM',
                  subtitle: 'IP: 103.179.189.120',
                  icon: Icons.dns_rounded,
                  statusDot: const Color(0xFF10B981),
                  statusText: 'Online',
                ),
                const SizedBox(height: 6),
                _buildStaticMenuItem(
                  title: 'Firebase Crashlytics',
                  subtitle: 'Giám sát lỗi di động',
                  icon: Icons.bug_report_rounded,
                  statusDot: const Color(0xFF38BDF8),
                  statusText: 'Active',
                ),
              ],
            ),
          ),

          // Thẻ Profile Admin & Nút Đăng xuất ở chân Sidebar
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF152620), // Tối hơn một chút
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF233E35)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'BQL',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ban Quản Lý KTX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'admin.ktx@fpt.edu.vn',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF233E35), height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onSwitchRole != null)
                      Expanded(
                        child: InkWell(
                          onTap: onSwitchRole,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF94A3B8)),
                                SizedBox(width: 4),
                                Text(
                                  'Đổi vai trò',
                                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: InkWell(
                        onTap: onSignOut,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 14, color: Color(0xFFEF4444)),
                              SizedBox(width: 4),
                              Text(
                                'Đăng xuất',
                                style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1)
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFF1E2D27),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF34D399) : const Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor ?? AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticMenuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color statusDot,
    required String statusText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF13201C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: statusDot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(color: statusDot, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

