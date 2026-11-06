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

  String get priceRange {
    if (name.contains('Cơm Tấm')) return '28.000đ - 45.000đ';
    if (name.contains('Bún')) return 'Từ 35.000đ';
    if (name.contains('Trà Sữa')) return 'Từ 18.000đ';
    return '25.000đ - 50.000đ';
  }

  String get priceSubtitle {
    if (name.contains('Cơm Tấm')) return 'Mức giá sinh viên';
    if (name.contains('Bún')) return 'Phần tiêu chuẩn';
    if (name.contains('Trà Sữa')) return 'Giá học sinh sinh viên';
    return 'Mức giá sinh viên';
  }

  List<String> get promoBadges {
    if (name.contains('Cơm Tấm')) return ['🔥 Bán chạy', '🌿 Freeship theo ca'];
    if (name.contains('Bún')) return ['Đang nhận ca trưa'];
    if (name.contains('Trà Sữa')) return ['🔖 Mua 2 tặng 1 topping'];
    return ['🔥 Bán chạy', '🌿 Freeship theo ca'];
  }

  String get overlayInfo {
    if (name.contains('Cơm Tấm')) return '🕒 Chốt 10:45';
    if (name.contains('Bún')) return 'Giao tới: Cổng KTX A & B';
    return '';
  }

  String get distanceOrTime {
    if (name.contains('Cơm Tấm')) return '🚀 Cổng 3 KTX (150m)';
    if (name.contains('Bún')) return 'Nhanh 15-20p';
    if (name.contains('Trà Sữa')) return 'Trà đậm, ít ngọt';
    return address.isNotEmpty ? address : 'Khu vực KTX';
  }
}
