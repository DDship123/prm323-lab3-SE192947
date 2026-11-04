import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/admin_dashboard_model.dart';

void main() {
  group('Web Admin Dashboard Model Tests', () {
    test('AdminDashboardStatsModel.mockData khởi tạo đầy đủ chỉ số', () {
      final mock = AdminDashboardStatsModel.mockData();

      expect(mock.totalRevenue, greaterThan(0));
      expect(mock.totalOrders, greaterThan(0));
      expect(mock.pendingDisputes, greaterThanOrEqualTo(0));
      expect(mock.disputeResolutionRate, inInclusiveRange(0.0, 100.0));
      expect(mock.recentActivities.isNotEmpty, isTrue);
    });

    test('AdminDashboardStatsModel JSON serialization và deserialization chính xác', () {
      final original = AdminDashboardStatsModel.mockData();
      final json = original.toJson();

      expect(json['totalRevenue'], original.totalRevenue);
      expect(json['totalOrders'], original.totalOrders);
      expect(json['recentActivities'], isA<List>());

      final reconstructed = AdminDashboardStatsModel.fromJson(json);
      expect(reconstructed.totalRevenue, original.totalRevenue);
      expect(reconstructed.totalOrders, original.totalOrders);
      expect(reconstructed.recentActivities.length, original.recentActivities.length);
      expect(reconstructed.recentActivities.first.id, original.recentActivities.first.id);
      expect(reconstructed.recentActivities.first.type, original.recentActivities.first.type);
    });

    test('AdminRecentActivityItem phân loại enum activity chính xác', () {
      const item = AdminRecentActivityItem(
        id: 'TEST-01',
        title: 'Món hỏng',
        description: 'Chi tiết khiếu nại',
        timeAgo: '1 phút trước',
        type: AdminActivityType.dispute,
      );

      final json = item.toJson();
      expect(json['type'], 'dispute');

      final parsed = AdminRecentActivityItem.fromJson(json);
      expect(parsed.type, AdminActivityType.dispute);
    });
  });
}
