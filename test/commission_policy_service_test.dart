import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/services/commission_policy_service.dart';

void main() {
  group('CommissionPolicyService Dynamic Rate Tests', () {
    late CommissionPolicyService service;

    setUp(() {
      service = CommissionPolicyService();
    });

    test('Mặc định tỷ lệ hoa hồng sàn là 10% và quán thực nhận 90%', () async {
      await service.updateCommissionRate(10.0);
      expect(service.commissionRate, equals(10.0));
      expect(service.storePayoutRate, equals(90.0));
    });

    test('Tính đúng tiền phí sàn và thực nhận với giá 35.000đ ở mức 10%', () async {
      await service.updateCommissionRate(10.0);
      const price = 35000.0;
      final fee = service.calculatePlatformFee(price);
      final net = service.calculateNetPayout(price);

      expect(fee, equals(3500.0));
      expect(net, equals(31500.0));
      expect(fee + net, equals(price));
    });

    test('Admin đổi chiết khấu sang 8%: quán thực nhận 92%', () async {
      final success = await service.updateCommissionRate(8.0);
      expect(success, isTrue);
      expect(service.commissionRate, equals(8.0));
      expect(service.storePayoutRate, equals(92.0));

      const price = 50000.0;
      final fee = service.calculatePlatformFee(price);
      final net = service.calculateNetPayout(price);

      expect(fee, equals(4000.0));
      expect(net, equals(46000.0));
    });

    test('Admin đổi chiết khấu sang 0% (ưu đãi kích cầu): quán thực nhận 100%', () async {
      final success = await service.updateCommissionRate(0.0);
      expect(success, isTrue);
      expect(service.commissionRate, equals(0.0));
      expect(service.storePayoutRate, equals(100.0));

      const price = 40000.0;
      expect(service.calculatePlatformFee(price), equals(0.0));
      expect(service.calculateNetPayout(price), equals(40000.0));
    });

    test('Từ chối tỷ lệ không hợp lệ (< 0% hoặc > 50%)', () async {
      final failNegative = await service.updateCommissionRate(-5.0);
      expect(failNegative, isFalse);

      final failTooHigh = await service.updateCommissionRate(60.0);
      expect(failTooHigh, isFalse);
    });
  });
}
