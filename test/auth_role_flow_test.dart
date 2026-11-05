import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_lab03_se192947/models/user_role_enum.dart';
import 'package:prm393_lab03_se192947/services/api_config.dart';

void main() {
  group('Auth & Role Switching Tests', () {
    test('UserAppRole enum contains exactly 4 roles with correct label and default email', () {
      expect(UserAppRole.values.length, 4);

      expect(UserAppRole.student.labelVi, 'Sinh viên KTX');
      expect(UserAppRole.student.defaultEmail, 'student@fpt.edu.vn');

      expect(UserAppRole.storeOwner.labelVi, 'Chủ Quán (Cơm Tấm Cô Ba)');
      expect(UserAppRole.storeOwner.defaultEmail, 'coba.owner@fpt.edu.vn');

      expect(UserAppRole.shipper.labelVi, 'Tài xế Gom Đơn (Shipper)');
      expect(UserAppRole.shipper.defaultEmail, 'shipper.hung@fpt.edu.vn');

      expect(UserAppRole.admin.labelVi, 'Ban Quản Lý KTX (Admin)');
      expect(UserAppRole.admin.defaultEmail, 'admin.ktx@fpt.edu.vn');
    });

    test('ApiConfig headers reflect currentBackendUserId correctly', () {
      ApiConfig.currentBackendUserId = 2; // Store Owner (Cô Ba)
      final ownerHeaders = ApiConfig.headers();
      expect(ownerHeaders['X-User-Id'], '2');

      ApiConfig.currentBackendUserId = 3; // Shipper (Nguyễn Hùng)
      final shipperHeaders = ApiConfig.headers();
      expect(shipperHeaders['X-User-Id'], '3');

      ApiConfig.currentBackendUserId = 4; // Admin
      final adminHeaders = ApiConfig.headers();
      expect(adminHeaders['X-User-Id'], '4');

      ApiConfig.currentBackendUserId = 1; // Student
      final studentHeaders = ApiConfig.headers();
      expect(studentHeaders['X-User-Id'], '1');
    });
  });
}
