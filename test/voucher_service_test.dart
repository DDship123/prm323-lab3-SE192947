import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/voucher_model.dart';
import 'package:prm393_lab03_se192947/services/voucher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VoucherModel & Logic Tests', () {
    test('Voucher phí ship (10.000đ) chỉ trừ tối đa bằng phí ship (5.000đ), không trừ lẹm vào tiền món', () {
      const voucher = VoucherModel(
        code: 'SINHVIENKTX',
        title: 'Trợ giá ship KTX',
        description: 'Giảm tối đa 10k phí ship',
        type: VoucherType.shipping,
        discountAmount: 10000,
        minOrderValue: 0,
        isActive: true,
      );

      final discount = voucher.calculateActualDiscount(
        itemsSubtotal: 40000, // Tiền món 40k
        deliveryFee: 5000,    // Tiền ship 5k
      );

      expect(discount, 5000.0, reason: 'Chỉ được giảm tối đa 5k phí ship');

      final effectiveShip = (5000.0 - discount).clamp(0.0, double.infinity);
      expect(effectiveShip, 0.0, reason: 'Phí ship sau giảm là 0đ');

      // Tổng thanh toán: 40.000đ tiền món + 0đ ship = 40.000đ (KHÔNG phải 35.000đ)
      final total = 40000.0 + effectiveShip;
      expect(total, 40000.0);
    });

    test('Voucher tiền món (10.000đ) giảm trực tiếp trên tiền món ăn', () {
      const voucher = VoucherModel(
        code: 'KTXDISCOUNT10K',
        title: 'Giảm 10k món',
        description: 'Đơn từ 50k',
        type: VoucherType.order,
        discountAmount: 10000,
        minOrderValue: 50000,
        isActive: true,
      );

      // Đơn 60k món + 5k ship
      final discount = voucher.calculateActualDiscount(
        itemsSubtotal: 60000,
        deliveryFee: 5000,
      );
      expect(discount, 10000.0);

      final finalItems = 60000.0 - discount;
      expect(finalItems, 50000.0);

      final total = finalItems + 5000.0;
      expect(total, 55000.0);
    });

    test('Voucher bị Disable (isActive = false) không được giảm tiền (0đ)', () {
      const voucher = VoucherModel(
        code: 'DISABLED_VOUCHER',
        title: 'Voucher bị khóa',
        description: 'Admin tạm ngưng',
        type: VoucherType.shipping,
        discountAmount: 10000,
        isActive: false, // Bị admin tắt
      );

      final discount = voucher.calculateActualDiscount(
        itemsSubtotal: 40000,
        deliveryFee: 5000,
      );
      expect(discount, 0.0);
    });

    test('Đơn hàng chưa đạt minOrderValue thì không được áp dụng', () {
      const voucher = VoucherModel(
        code: 'MIN50K',
        title: 'Giảm 10k',
        description: 'Tối thiểu 50k',
        type: VoucherType.order,
        discountAmount: 10000,
        minOrderValue: 50000,
        isActive: true,
      );

      final discount = voucher.calculateActualDiscount(
        itemsSubtotal: 40000, // Chưa đủ 50k
        deliveryFee: 5000,
      );
      expect(discount, 0.0);
    });
  });

  group('VoucherService Admin Management Tests', () {
    test('Load voucher mặc định và validate thành công', () async {
      final service = VoucherService();
      await service.resetToDefaults();

      expect(service.vouchers.length, greaterThanOrEqualTo(3));
      final res = service.validateVoucher(
        code: 'SINHVIENKTX',
        itemsSubtotal: 40000,
        deliveryFee: 5000,
      );
      expect(res.isValid, isTrue);
      expect(res.discountApplied, 5000.0);
    });

    test('Admin Disable voucher: Sinh viên bị chặn không được áp dụng', () async {
      final service = VoucherService();
      await service.resetToDefaults();

      // Admin toggle tắt voucher SINHVIENKTX
      await service.toggleVoucherStatus('SINHVIENKTX', false);

      final voucher = service.findByCode('SINHVIENKTX');
      expect(voucher?.isActive, isFalse);

      // Sinh viên cố áp dụng voucher bị disable
      final res = service.validateVoucher(
        code: 'SINHVIENKTX',
        itemsSubtotal: 40000,
        deliveryFee: 5000,
      );
      expect(res.isValid, isFalse);
      expect(res.message, contains('tạm ngưng kích hoạt'));
    });

    test('Admin tạo voucher mới và cấu hình số lượt dùng tối đa', () async {
      final service = VoucherService();
      await service.resetToDefaults();

      const newVoucher = VoucherModel(
        code: 'TET2026',
        title: 'Lì xì KTX Tết',
        description: 'Giảm 15.000đ',
        type: VoucherType.order,
        discountAmount: 15000,
        minOrderValue: 60000,
        maxUsagePerAccount: 2, // Cấu hình 2 lượt
        isActive: true,
      );

      final created = await service.createVoucher(newVoucher);
      expect(created, isTrue);

      final found = service.findByCode('TET2026');
      expect(found, isNotNull);
      expect(found!.maxUsagePerAccount, 2);
      expect(found.discountAmount, 15000.0);
    });
  });
}
