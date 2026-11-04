import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_dashboard_model.dart';
import '../services/dispute_service.dart';
import '../services/order_service.dart';
import '../widgets/web_admin_sidebar.dart';
import '../widgets/web_admin_topbar.dart';
import 'web_admin_dashboard_screen.dart';
import 'web_admin_dispute_screen.dart';
import 'web_admin_orders_screen.dart';

/// Khung giao diện Web tổng thể dành cho Ban Quản Lý KTX (Web Admin Portal) phong cách Greenova
class WebAdminShellScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  final VoidCallback? onSwitchRole;

  const WebAdminShellScreen({
    super.key,
    required this.onSignOut,
    this.onSwitchRole,
  });

  @override
  State<WebAdminShellScreen> createState() => _WebAdminShellScreenState();
}

class _WebAdminShellScreenState extends State<WebAdminShellScreen> {
  int _currentTabIndex = 0;
  final AdminDashboardStatsModel _stats = AdminDashboardStatsModel.mockData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Nền xám nhạt hiện đại
      body: Row(
        children: [
          // 1. Menu thanh bên bên trái phong cách Greenova
          WebAdminSidebar(
            selectedIndex: _currentTabIndex,
            onTabSelected: (idx) => setState(() => _currentTabIndex = idx),
            onSignOut: widget.onSignOut,
            onSwitchRole: widget.onSwitchRole,
          ),

          // 2. Khu vực nội dung chính bên phải kèm Topbar
          Expanded(
            child: Column(
              children: [
                WebAdminTopbar(
                  activeTabIndex: _currentTabIndex,
                  onRefresh: () {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật dữ liệu mới nhất từ hệ thống'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: _currentTabIndex,
                    children: [
                      WebAdminDashboardScreen(
                        stats: _stats,
                        onNavigateDisputes: () => setState(() => _currentTabIndex = 1),
                        onNavigateOrders: () => setState(() => _currentTabIndex = 2),
                      ),
                      WebAdminDisputeScreen(
                        disputeService: context.read<DisputeService>(),
                      ),
                      WebAdminOrdersScreen(
                        orderService: context.read<OrderService>(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
