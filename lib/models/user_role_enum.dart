enum UserAppRole {
  student,
  storeOwner,
  shipper,
  admin,
}

extension UserAppRoleExtension on UserAppRole {
  String get nameCode {
    switch (this) {
      case UserAppRole.student:
        return 'STUDENT';
      case UserAppRole.storeOwner:
        return 'STORE_OWNER';
      case UserAppRole.shipper:
        return 'SHIPPER';
      case UserAppRole.admin:
        return 'ADMIN';
    }
  }

  String get labelVi {
    switch (this) {
      case UserAppRole.student:
        return 'Sinh viên KTX';
      case UserAppRole.storeOwner:
        return 'Chủ Quán (Cơm Tấm Cô Ba)';
      case UserAppRole.shipper:
        return 'Tài xế Gom Đơn (Shipper)';
      case UserAppRole.admin:
        return 'Ban Quản Lý KTX (Admin)';
    }
  }

  String get defaultEmail {
    switch (this) {
      case UserAppRole.student:
        return 'student@fpt.edu.vn';
      case UserAppRole.storeOwner:
        return 'coba.owner@fpt.edu.vn';
      case UserAppRole.shipper:
        return 'shipper.hung@fpt.edu.vn';
      case UserAppRole.admin:
        return 'admin.ktx@fpt.edu.vn';
    }
  }
}