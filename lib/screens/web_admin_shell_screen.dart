import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_dashboard_model.dart';
import '../services/admin_api_service.dart';
import '../services/dispute_service.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import '../viewmodels/auth_vm.dart';
import '../widgets/web_admin_sidebar.dart';
import '../widgets/web_admin_topbar.dart';
import 'web_admin_dashboard_screen.dart';
import 'web_admin_dispute_screen.dart';
import 'web_admin_orders_screen.dart';

/// Khung giao diện Web tổng thể dành cho Ban Quản Lý KTX (Web Admin Portal)
/// Menu nằm ở bên trái với 1 nút đóng mở duy nhất, tối ưu 60fps mượt mà
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
  bool _isSidebarCollapsed = false;
  AdminDashboardStatsModel _stats = AdminDashboardStatsModel.mockData();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardStats();
    });
  }

  Future<void> _loadDashboardStats() async {
    try {
      final authVm = context.read<AuthViewModel>();
      final adminId = authVm.currentUser?.id.toString() ?? '4';
      final service = AdminApiService();
      final stats = await service.fetchDashboardStats(adminId: adminId);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (_) {}
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // 1. Menu thanh bên trái (chứa duy nhất 1 nút toggle đóng/mở)
          WebAdminSidebar(
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: _toggleSidebar,
            selectedIndex: _currentTabIndex,
            onTabSelected: (idx) => setState(() => _currentTabIndex = idx),
            onSignOut: widget.onSignOut,
            onSwitchRole: widget.onSwitchRole,
          ),

          // 2. Khu vực nội dung chính bên phải (được cô lập RepaintBoundary để giữ FPS mượt mà)
          Expanded(
            child: RepaintBoundary(
              child: Column(
                children: [
                  WebAdminTopbar(
                    activeTabIndex: _currentTabIndex,
                    onRefresh: () async {
                      await _loadDashboardStats();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đã cập nhật dữ liệu mới nhất từ hệ thống'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _currentTabIndex,
                      children: [
                        RepaintBoundary(
                          child: WebAdminDashboardScreen(
                            stats: _stats,
                            onNavigateDisputes: () => setState(() => _currentTabIndex = 1),
                            onNavigateOrders: () => setState(() => _currentTabIndex = 2),
                          ),
                        ),
                        RepaintBoundary(
                          child: WebAdminDisputeScreen(
                            disputeService: context.read<DisputeService>(),
                          ),
                        ),
                        RepaintBoundary(
                          child: WebAdminOrdersScreen(
                            orderService: context.read<OrderService>(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
