import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-019 đến API-022 (Trung tâm Thông báo Đơn hàng & Đếm chưa đọc)
class NotificationService {
  final http.Client _client;

  NotificationService({http.Client? client})
      : _client = client ?? http.Client();

  /// API-019: Lấy danh sách thông báo của sinh viên
  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.notifications), headers: ApiConfig.headers())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'];
        if (data is Map<String, dynamic> && data['content'] is List) {
          final content = data['content'] as List<dynamic>;
          return content
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    return [
      NotificationModel(
        id: 1,
        userId: ApiConfig.currentBackendUserId,
        title: 'Chào mừng đến với KTX Food Ordering',
        body: 'Đặt đơn gom ca trưa 11h30 và ca chiều 18h00 để nhận ưu đãi phí ship chỉ 5.000đ.',
        type: 'SYSTEM',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];
  }

  /// API-022: Đếm nhanh số thông báo chưa đọc
  Future<int> fetchUnreadCount() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.notifications}/unread-count'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        return (data?['unreadCount'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  /// API-020: Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(int notificationId) async {
    try {
      await _client
          .patch(
            Uri.parse('${ApiConfig.notifications}/$notificationId/read'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }

  /// API-021: Đánh dấu toàn bộ thông báo đã đọc
  Future<void> markAllAsRead() async {
    try {
      await _client
          .patch(
            Uri.parse('${ApiConfig.notifications}/read-all'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}
