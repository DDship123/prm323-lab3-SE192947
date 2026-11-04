import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_config.dart';

/// Thanh Header trên cùng của Dashboard Admin (Web Top Bar) chuẩn SaaS hiện đại
/// Tích hợp nút đóng mở / thu gọn menu bên trái, tìm kiếm nhanh và giám sát VPS
class WebAdminTopbar extends StatelessWidget {
  final int activeTabIndex;
  final VoidCallback onRefresh;
  final bool isSidebarCollapsed;
  final VoidCallback? onToggleSidebar;

  const WebAdminTopbar({
    super.key,
    required this.activeTabIndex,
    required this.onRefresh,
    this.isSidebarCollapsed = false,
    this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Bảng Điều Khiển Tổng Quan KPI',
      'Trọng Tài Khiếu Nại & Món Hỏng',
      'Giám Sát Toàn Bộ Đơn Hàng KTX',
    ];
    final breadcrumbs = [
      'Hệ thống / Tổng quan KPI',
      'Nghiệp vụ / Xử lý Khiếu nại',
      'Nghiệp vụ / Giám sát Gom ca',
    ];

    final nowStr = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(DateTime.now());

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Nút toggle đóng mở menu bên trái
          if (onToggleSidebar != null) ...[
            IconButton(
              tooltip: isSidebarCollapsed ? 'Mở rộng menu bên trái' : 'Thu gọn menu bên trái',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
                  color: const Color(0xFF0F172A),
                  size: 20,
                ),
              ),
              onPressed: onToggleSidebar,
            ),
            const SizedBox(width: 16),
          ],

          // Tiêu đề trang & Breadcrumb
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                breadcrumbs[activeTabIndex],
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titles[activeTabIndex],
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),

          // Thanh tìm kiếm nhanh phong cách Greenova
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm đơn hàng, mã sinh viên, món ăn...',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Text(
                      'Ctrl K',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Trạng thái kết nối Máy chủ VPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'VPS Online: ${ApiConfig.baseUrl.replaceAll('/api/v1', '')}',
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Ngày hiện tại
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  nowStr,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Nút Refresh
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
            ),
            onPressed: onRefresh,
          ),

          // Nút Chuông thông báo
          Stack(
            children: [
              IconButton(
                tooltip: 'Thông báo hệ thống',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_none_rounded, size: 18, color: Color(0xFF475569)),
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
