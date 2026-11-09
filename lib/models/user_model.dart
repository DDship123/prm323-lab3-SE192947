/// Mô hình dữ liệu người dùng sinh viên KTX (UserResponse)
class UserModel {
  final int id;
  final String firebaseUid;
  final String email;
  final String displayName;
  final String? phone;
  final String role;
  final String? avatarUrl;
  final String? ktxBuilding;
  final String? ktxRoom;
  final double? ratingAvg;
  final int? ratingCount;
  final bool isBanned;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    this.phone,
    this.role = 'STUDENT',
    this.avatarUrl,
    this.ktxBuilding,
    this.ktxRoom,
    this.ratingAvg,
    this.ratingCount,
    this.isBanned = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      firebaseUid: json['firebaseUid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Sinh viên KTX',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'STUDENT',
      avatarUrl: json['avatarUrl'] as String?,
      ktxBuilding: json['ktxBuilding'] as String?,
      ktxRoom: json['ktxRoom'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      isBanned: json['isBanned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSyncJson() => {
        'firebaseUid': firebaseUid,
        'email': email,
        'displayName': displayName,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (ktxBuilding != null) 'ktxBuilding': ktxBuilding,
        if (ktxRoom != null) 'ktxRoom': ktxRoom,
      };
}
