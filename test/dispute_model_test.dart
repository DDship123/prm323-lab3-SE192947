import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/dispute_model.dart';

void main() {
  group('DisputeModel & DTO Tests', () {
    test('Parse DisputeModel from JSON thành công với đầy đủ thuộc tính', () {
      final json = {
        'id': 10,
        'orderId': 101,
        'storeName': 'Cơm tấm KTX',
        'reason': 'Món ăn có dị vật / Hỏng vị',
        'description': 'Món ăn có mùi lạ',
        'evidenceImageUrl': 'https://firebasestorage.googleapis.com/v0/b/app/o/evidence.jpg',
        'requestedRefundAmount': 35000.0,
        'approvedRefundAmount': 35000.0,
        'status': 'APPROVED',
        'adminNote': 'Đã hoàn tất duyệt',
        'createdAt': '2026-11-03T10:00:00Z',
      };

      final dispute = DisputeModel.fromJson(json);

      expect(dispute.id, 10);
      expect(dispute.orderId, 101);
      expect(dispute.storeName, 'Cơm tấm KTX');
      expect(dispute.status, DisputeStatus.approved);
      expect(dispute.status.label, 'Đã chấp thuận');
      expect(dispute.requestedRefundAmount, 35000.0);
      expect(dispute.evidenceImageUrl, contains('evidence.jpg'));
    });

    test('DisputeStatus mapper nhận diện đúng status code hoặc fallback về PENDING', () {
      expect(DisputeStatus.fromCode('PENDING'), DisputeStatus.pending);
      expect(DisputeStatus.fromCode('APPROVED'), DisputeStatus.approved);
      expect(DisputeStatus.fromCode('REJECTED'), DisputeStatus.rejected);
      expect(DisputeStatus.fromCode('REFUNDED'), DisputeStatus.refunded);
      expect(DisputeStatus.fromCode('UNKNOWN_CODE'), DisputeStatus.pending);
      expect(DisputeStatus.fromCode(null), DisputeStatus.pending);
    });

    test('CreateDisputeDto chuyển đổi sang JSON đúng schema gửi Backend', () {
      const dto = CreateDisputeDto(
        orderId: 202,
        reason: 'Giao thiếu món',
        description: 'Thiếu 01 ly trà tắc',
        evidenceImageUrl: 'https://firebasestorage.googleapis.com/reports/user1/pic.jpg',
        requestedRefundAmount: 15000.0,
      );

      final json = dto.toJson();

      expect(json['orderId'], 202);
      expect(json['reason'], 'Giao thiếu món');
      expect(json['description'], 'Thiếu 01 ly trà tắc');
      expect(json['evidenceImageUrl'], contains('reports/user1/pic.jpg'));
      expect(json['requestedRefundAmount'], 15000.0);
    });
  });
}

