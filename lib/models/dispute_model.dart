/// Trạng thái thẩm định khiếu nại
enum DisputeStatus {
  pending('PENDING', 'Đang thẩm định'),
  approved('APPROVED', 'Đã chấp thuận'),
  rejected('REJECTED', 'Đã từ chối'),
  refunded('REFUNDED', 'Đã hoàn tiền');

  final String code;
  final String label;

  const DisputeStatus(this.code, this.label);

  static DisputeStatus fromCode(String? code) {
    return DisputeStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == (code ?? '').toUpperCase(),
      orElse: () => DisputeStatus.pending,
    );
  }
}

/// Thực thể khiếu nại sự cố và hoàn tiền (Dispute Entity)
class DisputeModel {
  final int id;
  final int orderId;
  final int userId;
  final String? storeName;
  final String reason;
  final String description;
  final String evidenceImageUrl;
  final List<String> evidenceImages;
  final double requestedRefundAmount;
  final double? approvedRefundAmount;
  final DisputeStatus status;
  final String? adminNote;
  final DateTime createdAt;

  const DisputeModel({
    required this.id,
    required this.orderId,
    this.userId = 1,
    this.storeName,
    required this.reason,
    required this.description,
    required this.evidenceImageUrl,
    this.evidenceImages = const [],
    required this.requestedRefundAmount,
    this.approvedRefundAmount,
    required this.status,
    this.adminNote,
    required this.createdAt,
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    String evUrl = json['evidenceImageUrl'] as String? ?? '';
    final rawImgs = json['evidenceImages'] as List<dynamic>?;
    List<String> evList = [];
    if (rawImgs != null && rawImgs.isNotEmpty) {
      evList = rawImgs.map((e) => e.toString()).toList();
      if (evUrl.isEmpty) {
        evUrl = evList.first;
      }
    } else if (evUrl.isNotEmpty) {
      evList = [evUrl];
    }

    final reqAmt = (json['requestedRefundAmount'] as num?)?.toDouble() ??
        (json['refundRequestedAmount'] as num?)?.toDouble() ??
        0.0;
    final appAmt = (json['approvedRefundAmount'] as num?)?.toDouble() ??
        (json['refundApprovedAmount'] as num?)?.toDouble();
    final note = (json['adminNote'] as String?) ?? (json['resolutionNote'] as String?);

    return DisputeModel(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 1,
      storeName: json['storeName'] as String?,
      reason: json['reason']?.toString() ?? 'Sự cố món ăn',
      description: json['description'] as String? ?? '',
      evidenceImageUrl: evUrl,
      evidenceImages: evList,
      requestedRefundAmount: reqAmt,
      approvedRefundAmount: appAmt,
      status: DisputeStatus.fromCode(json['status'] as String?),
      adminNote: note,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final images = evidenceImages.isNotEmpty
        ? evidenceImages
        : (evidenceImageUrl.trim().isNotEmpty ? [evidenceImageUrl.trim()] : <String>[]);

    return {
      'orderId': orderId,
      'userId': userId,
      'reason': reason,
      'description': description,
      'evidenceImages': images,
      'evidenceImageUrl': evidenceImageUrl,
      'refundRequestedAmount': requestedRefundAmount,
      'requestedRefundAmount': requestedRefundAmount,
    };
  }
}

/// DTO gửi yêu cầu tạo khiếu nại kèm link ảnh Cloud Storage
class CreateDisputeDto {
  final int orderId;
  final String reason;
  final String description;
  final String evidenceImageUrl;
  final double requestedRefundAmount;

  const CreateDisputeDto({
    required this.orderId,
    required this.reason,
    required this.description,
    required this.evidenceImageUrl,
    required this.requestedRefundAmount,
  });

  Map<String, dynamic> toJson() {
    final images = evidenceImageUrl.trim().isNotEmpty ? [evidenceImageUrl.trim()] : <String>[];

    return {
      'orderId': orderId,
      'reason': reason,
      'description': description,
      'evidenceImages': images,
      'evidenceImageUrl': evidenceImageUrl,
      'refundRequestedAmount': requestedRefundAmount,
      'requestedRefundAmount': requestedRefundAmount,
    };
  }
}
