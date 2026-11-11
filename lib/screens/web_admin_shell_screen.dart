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
import 'web_admin_voucher_screen.dart';
import 'web_admin_users_screen.dart';
import 'web_admin_stores_screen.dart';
import 'web_admin_cashflow_screen.dart';
import '../services/store_service.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTabIndex = 0;
  bool _isSidebarCollapsed = false;
  AdminDashboardStatsModel _stats = const AdminDashboardStatsModel(
    totalRevenue: 0,
    totalOrders: 0,
    activeOrders: 0,
    pendingDisputes: 0,
    totalUsers: 0,
    disputeResolutionRate: 0,
    recentActivities: [],
  );

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    final sidebar = WebAdminSidebar(
      isCollapsed: isMobile ? false : _isSidebarCollapsed,
      onToggleCollapse: _toggleSidebar,
      selectedIndex: _currentTabIndex,
      pendingDisputes: _stats.pendingDisputes,
      totalOrders: _stats.totalOrders,
      totalUsers: _stats.totalUsers,
      onTabSelected: (idx) {
        setState(() => _currentTabIndex = idx);
        if (isMobile && _scaffoldKey.currentState?.isDrawerOpen == true) {
          Navigator.of(context).pop();
        }
      },
      onSignOut: widget.onSignOut,
      onSwitchRole: widget.onSwitchRole,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isMobile ? Drawer(child: SafeArea(child: sidebar)) : null,
      body: Row(
        children: [
          // 1. Menu thanh bên trái: chỉ hiện dạng fixed column trên màn hình Desktop (>= 900px)
          if (!isMobile) sidebar,

          // 2. Khu vực nội dung chính bên phải (được cô lập RepaintBoundary để giữ FPS mượt mà)
          Expanded(
            child: RepaintBoundary(
              child: Column(
                children: [
                  WebAdminTopbar(
                    activeTabIndex: _currentTabIndex,
                    isMobile: isMobile,
                    onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
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
                        const RepaintBoundary(
                          child: WebAdminVoucherScreen(),
                        ),
                        RepaintBoundary(
                          child: WebAdminUsersScreen(
                            adminService: context.read<AdminApiService>(),
                          ),
                        ),
                        RepaintBoundary(
                          child: WebAdminStoresScreen(
                            storeService: context.read<StoreService>(),
                          ),
                        ),
                        RepaintBoundary(
                          child: WebAdminCashflowScreen(
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
