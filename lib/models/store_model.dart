/// Mô hình dữ liệu quán ăn liên kết KTX (StoreResponse)
class StoreModel {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String campusZone;
  final String? phoneNumber;
  final String? avatarUrl;
  final bool isActive;
  final double ratingAvg;
  final int ratingCount;

  const StoreModel({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.campusZone,
    this.phoneNumber,
    this.avatarUrl,
    this.isActive = true,
    this.ratingAvg = 5.0,
    this.ratingCount = 0,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      address: json['address'] as String? ?? '',
      campusZone: json['campusZone'] as String? ?? 'KTX_KHU_B',
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 5.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }

  String get campusZoneLabel {
    switch (campusZone) {
      case 'KTX_KHU_A':
        return 'KTX Khu A';
      case 'KTX_KHU_B':
        return 'KTX Khu B';
      default:
        return campusZone;
    }
  }
}
