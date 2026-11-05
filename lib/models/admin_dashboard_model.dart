/// Mô hình thống kê hoạt động tổng quan cho Cổng Web Quản trị KTX (Web Admin Portal)
class AdminDashboardStatsModel {
  final double totalRevenue;
  final int totalOrders;
  final int activeOrders;
  final int pendingDisputes;
  final int totalUsers;
  final double disputeResolutionRate;
  final List<AdminRecentActivityItem> recentActivities;

  const AdminDashboardStatsModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.activeOrders,
    required this.pendingDisputes,
    required this.totalUsers,
    required this.disputeResolutionRate,
    this.recentActivities = const [],
  });

  factory AdminDashboardStatsModel.mockData() {
    return const AdminDashboardStatsModel(
      totalRevenue: 28540000,
      totalOrders: 642,
      activeOrders: 18,
      pendingDisputes: 3,
      totalUsers: 1250,
      disputeResolutionRate: 94.5,
      recentActivities: [
        AdminRecentActivityItem(
          id: 'ACT-01',
          title: 'Khiếu nại món hỏng mới',
          description: 'Sinh viên Ngô Trường Đạt gửi ảnh món bún bò bị đổ tại KTX Khu B',
          timeAgo: '5 phút trước',
          type: AdminActivityType.dispute,
        ),
        AdminRecentActivityItem(
          id: 'ACT-02',
          title: 'Gom đơn Ca trưa hoàn tất',
          description: 'Shipper Nguyễn Hùng đã giao 12 đơn thành công tại Tòa BA1',
          timeAgo: '20 phút trước',
          type: AdminActivityType.delivery,
        ),
        AdminRecentActivityItem(
          id: 'ACT-03',
          title: 'Quán ăn mới đăng ký',
          description: 'Cơm Tấm Cô Ba vừa hoàn tất xác minh mở bán Ca tối',
          timeAgo: '1 giờ trước',
          type: AdminActivityType.store,
        ),
      ],
    );
  }

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    final list = json['recentActivities'] as List<dynamic>? ?? [];
    return AdminDashboardStatsModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      activeOrders: json['activeOrders'] as int? ?? 0,
      pendingDisputes: json['pendingDisputes'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
      disputeResolutionRate: (json['disputeResolutionRate'] as num?)?.toDouble() ?? 0.0,
      recentActivities: list
          .map((item) => AdminRecentActivityItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'activeOrders': activeOrders,
        'pendingDisputes': pendingDisputes,
        'totalUsers': totalUsers,
        'disputeResolutionRate': disputeResolutionRate,
        'recentActivities': recentActivities.map((a) => a.toJson()).toList(),
      };
}

enum AdminActivityType { dispute, delivery, store, system }

class AdminRecentActivityItem {
  final String id;
  final String title;
  final String description;
  final String timeAgo;
  final AdminActivityType type;

  const AdminRecentActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.type,
  });

  factory AdminRecentActivityItem.fromJson(Map<String, dynamic> json) {
    return AdminRecentActivityItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      type: AdminActivityType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AdminActivityType.system,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'timeAgo': timeAgo,
        'type': type.name,
      };
}

