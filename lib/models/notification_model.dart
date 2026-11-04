/// Mô hình dữ liệu thông báo đơn hàng & hệ thống (NotificationResponse)
class NotificationModel {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? dataPayload;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.dataPayload,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'ORDER_STATUS',
      isRead: json['isRead'] as bool? ?? false,
      dataPayload: json['dataPayload'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
