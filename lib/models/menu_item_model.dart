/// Lựa chọn tùy biến cụ thể (vd: Size L, Trứng ốp la)
class CustomizationOptionModel {
  final String name;
  final double extraPrice;

  const CustomizationOptionModel({
    required this.name,
    required this.extraPrice,
  });

  factory CustomizationOptionModel.fromJson(Map<String, dynamic> json) {
    return CustomizationOptionModel(
      name: json['name'] as String? ?? '',
      extraPrice: (json['extraPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Nhóm tùy biến món ăn (vd: Kích cỡ, Topping thêm)
class CustomizationGroupModel {
  final String group;
  final bool required;
  final List<CustomizationOptionModel> options;

  const CustomizationGroupModel({
    required this.group,
    required this.required,
    required this.options,
  });

  factory CustomizationGroupModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return CustomizationGroupModel(
      group: json['group'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      options: rawOptions
          .map((e) =>
              CustomizationOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Mô hình dữ liệu món ăn trong thực đơn quán (MenuItemResponse)
class MenuItemModel {
  final int id;
  final int storeId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double basePrice;
  final String category;
  final bool isAvailable;
  final List<CustomizationGroupModel> customizationOptions;

  const MenuItemModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.basePrice,
    required this.category,
    this.isAvailable = true,
    this.customizationOptions = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['customizationOptions'] as List<dynamic>? ?? [];
    return MenuItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      storeId: (json['storeId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'COM',
      isAvailable: json['isAvailable'] as bool? ?? true,
      customizationOptions: rawGroups
          .map((e) =>
              CustomizationGroupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double? get originalPrice {
    if (name.contains('Cơm Sườn Bì Chả Đặc Biệt')) return 42000.0;
    return null;
  }

  String? get promoBadge {
    if (name.contains('Cơm Sườn Bì Chả Đặc Biệt')) return 'Best Seller';
    if (name.contains('Muối Ớt')) return 'Cay nhẹ';
    return null;
  }
}
