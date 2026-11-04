import 'package:flutter/material.dart';

/// Menu thanh bên (Left Vertical Sidebar) chuẩn phong cách Quản trị Hiện đại Greenova / SaaS
/// Hỗ trợ chế độ Mở rộng (Expanded 280px) và Thu gọn / Đóng mở (Collapsed 76px)
class WebAdminSidebar extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const WebAdminSidebar({
    super.key,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 76 : 280,
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
          // ================= 1. HEADER & THƯƠNG HIỆU & NÚT ĐÓNG/MỞ =================
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 16 : 20,
              vertical: 20,
            ),
            child: isCollapsed
                ? Center(
                    child: InkWell(
                      onTap: onToggleCollapse,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
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
                          Icons.menu_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
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
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'KTX ADMIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Greenova Portal v2.0',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Thu gọn menu bên trái',
                        icon: const Icon(Icons.menu_open_rounded, color: Color(0xFF94A3B8), size: 20),
                        onPressed: onToggleCollapse,
                      ),
                    ],
                  ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFF1E293B), height: 1),
          ),
          const SizedBox(height: 12),

          // ================= 2. DANH SÁCH MỤC ĐIỀU HƯỚNG =================
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 10 : 14),
              children: [
                if (!isCollapsed) _buildSectionLabel('TỔNG QUAN'),
                _buildMenuItem(
                  index: 0,
                  title: 'Bảng Điều Khiển',
                  icon: Icons.dashboard_rounded,
                ),
                SizedBox(height: isCollapsed ? 10 : 16),

                if (!isCollapsed) _buildSectionLabel('NGHIỆP VỤ QUẢN TRỊ'),
                _buildMenuItem(
                  index: 1,
                  title: 'Xử Lý Khiếu Nại',
                  icon: Icons.assignment_late_rounded,
                  badgeText: '3 chờ',
                  badgeColor: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 6),
                _buildMenuItem(
                  index: 2,
                  title: 'Giám Sát Đơn Hàng',
                  icon: Icons.receipt_long_rounded,
                  badgeText: 'Ca trưa',
                  badgeColor: const Color(0xFF10B981),
                ),
                SizedBox(height: isCollapsed ? 10 : 16),

                if (!isCollapsed) ...[
                  _buildSectionLabel('HỆ THỐNG & KẾT NỐI'),
                  _buildStaticMenuItem(
                    title: 'Máy Chủ VPS TP.HCM',
                    subtitle: '103.179.189.120',
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
                ] else ...[
                  Tooltip(
                    message: 'VPS Online: 103.179.189.120',
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13221C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dns_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ================= 3. THẺ PROFILE ADMIN Ở CHÂN SIDEBAR =================
          isCollapsed
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: PopupMenuButton<String>(
                    tooltip: 'Ban Quản Lý KTX',
                    offset: const Offset(60, -80),
                    color: const Color(0xFF152620),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF233E35)),
                    ),
                    itemBuilder: (ctx) => [
                      if (onSwitchRole != null)
                        const PopupMenuItem(
                          value: 'role',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 8),
                              Text('Đổi vai trò', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 16, color: Color(0xFFEF4444)),
                            SizedBox(width: 8),
                            Text('Đăng xuất', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'role') onSwitchRole?.call();
                      if (val == 'logout') onSignOut();
                    },
                    child: Container(
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
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152620),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF233E35)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'BQL',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
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
                      const SizedBox(height: 10),
                      const Divider(color: Color(0xFF233E35), height: 1),
                      const SizedBox(height: 6),
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
                          if (onSwitchRole != null)
                            Container(width: 1, height: 16, color: const Color(0xFF233E35)),
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
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required String title,
    required IconData icon,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = selectedIndex == index;

    if (isCollapsed) {
      return Tooltip(
        message: title,
        preferBelow: false,
        child: InkWell(
          onTap: () => onTabSelected(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  size: 22,
                ),
                if (badgeText != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeColor ?? const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981).withValues(alpha: 0.8) : Colors.transparent,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF13221C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF13221C).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E352B), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFF1E352B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusDot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(statusText, style: TextStyle(color: statusDot, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
