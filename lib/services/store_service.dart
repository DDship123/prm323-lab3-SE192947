import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/menu_item_model.dart';
import '../models/store_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-003, API-004, API-005 (Khám phá Quán ăn & Thực đơn KTX)
class StoreService {
  final http.Client _client;

  StoreService({http.Client? client}) : _client = client ?? http.Client();

  /// API-003: Lấy danh sách quán ăn theo từ khóa và phân khu KTX
  Future<List<StoreModel>> fetchStores({
    String? keyword,
    String? campusZone,
  }) async {
    final queryParams = <String, String>{};
    if (keyword != null && keyword.trim().isNotEmpty) {
      queryParams['keyword'] = keyword.trim();
    }
    if (campusZone != null &&
        campusZone.isNotEmpty &&
        campusZone != 'ALL') {
      queryParams['campusZone'] = campusZone;
    }

    final uri = Uri.parse(ApiConfig.stores).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    try {
      final response = await _client
          .get(uri, headers: ApiConfig.headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'];
        if (data is Map<String, dynamic> && data['content'] is List) {
          final content = data['content'] as List<dynamic>;
          return content
              .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
              .toList();
        } else if (data is List) {
          return data
              .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Fallback sang dữ liệu mẫu khớp với DataInitializer của Backend khi mất mạng
    }

    var fallback = _fallbackStores();
    if (campusZone != null && campusZone.isNotEmpty && campusZone != 'ALL') {
      fallback = fallback.where((s) => s.campusZone == campusZone).toList();
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      final kw = keyword.trim().toLowerCase();
      fallback = fallback
          .where((s) =>
              s.name.toLowerCase().contains(kw) ||
              (s.description?.toLowerCase().contains(kw) ?? false))
          .toList();
    }
    return fallback;
  }

  /// API-004: Lấy thông tin chi tiết quán ăn
  Future<StoreModel> fetchStoreById(int storeId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.stores}/$storeId'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          return StoreModel.fromJson(data);
        }
      }
    } catch (_) {}

    return _fallbackStores().firstWhere(
      (s) => s.id == storeId,
      orElse: () => _fallbackStores().first,
    );
  }

  /// API-005: Lấy danh sách thực đơn của quán
  Future<List<MenuItemModel>> fetchMenuItems(int storeId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.stores}/$storeId/menu-items'),
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final rawList = jsonMap['data'] as List<dynamic>? ?? [];
        return rawList
            .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}

    return _fallbackMenuItems(storeId);
  }

  /// API Thêm món ăn mới vào thực đơn quán (POST /api/v1/stores/{storeId}/menu-items)
  Future<MenuItemModel?> createMenuItem({
    required int storeId,
    required String name,
    required double basePrice,
    required String category,
    required String description,
    required String imageUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.stores}/$storeId/menu-items');
    final body = jsonEncode({
      'name': name,
      'basePrice': basePrice,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': true,
      'customizationOptions': [],
    });

    try {
      final response = await _client.post(uri, headers: ApiConfig.headers(), body: body).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>;
        return MenuItemModel.fromJson(data);
      }
    } catch (_) {}
    return MenuItemModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      storeId: storeId,
      name: name,
      description: description,
      basePrice: basePrice,
      category: category,
      imageUrl: imageUrl,
      isAvailable: true,
      customizationOptions: [],
    );
  }

  /// API Cập nhật món ăn (PUT /api/v1/menu-items/{id})
  Future<MenuItemModel?> updateMenuItem({
    required int id,
    required String name,
    required double basePrice,
    required String category,
    required String description,
    required String imageUrl,
    bool? isAvailable,
  }) async {
    final uri = Uri.parse('${ApiConfig.menuItems}/$id');
    final body = jsonEncode({
      'name': name,
      'basePrice': basePrice,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      if (isAvailable != null) 'isAvailable': isAvailable,
      'customizationOptions': [],
    });

    try {
      final response = await _client.put(uri, headers: ApiConfig.headers(), body: body).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>;
        return MenuItemModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// API Xóa món ăn khỏi thực đơn (DELETE /api/v1/menu-items/{id})
  Future<bool> deleteMenuItem(int id) async {
    final uri = Uri.parse('${ApiConfig.menuItems}/$id');
    try {
      final response = await _client.delete(uri, headers: ApiConfig.headers()).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  List<StoreModel> _fallbackStores() => const [
        StoreModel(
          id: 1,
          name: 'Cơm Tấm Sườn Bì Khu B - Cổng 3',
          description: 'Cơm tấm sườn nướng mật ong, giao gom đơn tận trụ KTX Khu B',
          address: 'Cổng 3 KTX (150m)',
          campusZone: 'KTX_KHU_B',
          phoneNumber: '0901234567',
          avatarUrl:
              'https://images.unsplash.com/photo-1544025162-d76694265947?w=600',
          isActive: true,
          ratingAvg: 4.9,
          ratingCount: 350,
        ),
        StoreModel(
          id: 2,
          name: 'Bún Đậu Mắm Tôm Cô Bông KTX',
          description: 'Bún đậu mắm tôm thập cẩm giòn rụm, giao tới các cổng KTX',
          address: 'Giao tới: Cổng KTX A & B',
          campusZone: 'KTX_KHU_B',
          phoneNumber: '0909888777',
          avatarUrl:
              'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
          isActive: true,
          ratingAvg: 4.8,
          ratingCount: 210,
        ),
        StoreModel(
          id: 3,
          name: 'Trà Sữa Đậm Vị KTX Khu B',
          description: 'Trà sữa đậm vị lá trà Bảo Lộc, trân châu hoàng kim',
          address: 'Sảnh Tòa BA1 KTX Khu B',
          campusZone: 'KTX_KHU_B',
          phoneNumber: '0903111222',
          avatarUrl:
              'https://images.unsplash.com/photo-1556881286-fc6915169721?w=600',
          isActive: true,
          ratingAvg: 4.7,
          ratingCount: 480,
        ),
      ];

  List<MenuItemModel> _fallbackMenuItems(int storeId) {
    if (storeId == 2) {
      return const [
        MenuItemModel(
          id: 3,
          storeId: 2,
          name: 'Bún Bò Đặc Biệt Tái Nạm Chả Cua',
          description: 'Đầy đủ thịt tái, nạm bò, chả cua Huế và rau sống tươi',
          imageUrl:
              'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600',
          basePrice: 40000,
          category: 'BUN_PHO',
          isAvailable: true,
          customizationOptions: [
            CustomizationGroupModel(
              group: 'Độ cay',
              required: true,
              options: [
                CustomizationOptionModel(name: 'Không cay', extraPrice: 0),
                CustomizationOptionModel(name: 'Cay vừa', extraPrice: 0),
                CustomizationOptionModel(name: 'Cay nồng Huế', extraPrice: 0),
              ],
            ),
            CustomizationGroupModel(
              group: 'Topping thêm',
              required: false,
              options: [
                CustomizationOptionModel(name: 'Thêm chả cua', extraPrice: 10000),
                CustomizationOptionModel(name: 'Thêm bún', extraPrice: 5000),
              ],
            ),
          ],
        ),
      ];
    }

    return const [
      MenuItemModel(
        id: 1,
        storeId: 1,
        name: 'Cơm Sườn Nướng Mật Ong Chả Trứng',
        description: 'Sườn cốt lết ướp mật ong nướng than, kèm chả hấp và canh rong biển',
        imageUrl:
            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
        basePrice: 35000,
        category: 'COM',
        isAvailable: true,
        customizationOptions: [
          CustomizationGroupModel(
            group: 'Kích cỡ',
            required: true,
            options: [
              CustomizationOptionModel(name: 'Cơm vừa', extraPrice: 0),
              CustomizationOptionModel(name: 'Cơm nhiều (+Cơm)', extraPrice: 5000),
            ],
          ),
          CustomizationGroupModel(
            group: 'Topping thêm',
            required: false,
            options: [
              CustomizationOptionModel(name: 'Trứng ốp la lòng đào', extraPrice: 6000),
              CustomizationOptionModel(name: 'Bì thính', extraPrice: 7000),
              CustomizationOptionModel(name: 'Lạp xưởng tươi', extraPrice: 10000),
            ],
          ),
        ],
      ),
      MenuItemModel(
        id: 2,
        storeId: 1,
        name: 'Trà Tắc Xí Muội Khổng Lồ (700ml)',
        description: 'Trà tắc tươi mát lạnh giải nhiệt ca trưa KTX',
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=600',
        basePrice: 15000,
        category: 'NUOC',
        isAvailable: true,
        customizationOptions: [
          CustomizationGroupModel(
            group: 'Mức đá',
            required: true,
            options: [
              CustomizationOptionModel(name: 'Đá bình thường', extraPrice: 0),
              CustomizationOptionModel(name: 'Ít đá', extraPrice: 0),
            ],
          ),
        ],
      ),
    ];
  }
}
