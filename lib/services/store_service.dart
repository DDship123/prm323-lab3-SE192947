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
    bool onlyActive = true,
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
    if (onlyActive) {
      queryParams['isActive'] = 'true';
    }

    final uri = Uri.parse(ApiConfig.stores).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    try {
      ApiConfig.log('DB-STORE', 'GET $uri');
      final response = await _client
          .get(uri, headers: ApiConfig.headers())
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'];
        if (data is Map<String, dynamic> && data['content'] is List) {
          final content = data['content'] as List<dynamic>;
          final list = content
              .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
              .toList();
          ApiConfig.log('DB-STORE', '✅ Đã tải ${list.length} quán ăn từ Database');
          return list;
        } else if (data is List) {
          final list = data
              .map((e) => StoreModel.fromJson(e as Map<String, dynamic>))
              .toList();
          ApiConfig.log('DB-STORE', '✅ Đã tải ${list.length} quán ăn từ Database');
          return list;
        }
      } else {
        ApiConfig.log('DB-STORE-ERROR', '❌ HTTP ${response.statusCode} từ $uri');
        throw Exception('Máy chủ phản hồi mã lỗi ${response.statusCode}');
      }
    } catch (e) {
      ApiConfig.log('DB-STORE-ERROR', '❌ Lỗi tải danh sách quán: $e');
      throw Exception('Mất kết nối máy chủ. Vui lòng kiểm tra lại kết nối mạng!');
    }

    return [];
  }

  /// API-004: Lấy thông tin chi tiết quán ăn
  Future<StoreModel> fetchStoreById(int storeId) async {
    final uri = Uri.parse('${ApiConfig.stores}/$storeId');
    ApiConfig.log('DB-STORE', 'GET $uri');
    final response = await _client
        .get(
          uri,
          headers: ApiConfig.headers(),
        )
        .timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final jsonMap =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final data = jsonMap['data'] as Map<String, dynamic>?;
      if (data != null) {
        final store = StoreModel.fromJson(data);
        ApiConfig.log('DB-STORE', '✅ Chi tiết quán ID=$storeId: "${store.name}"');
        return store;
      }
    }
    ApiConfig.log('DB-STORE-ERROR', '❌ Không tìm thấy quán ID=$storeId');
    throw Exception('Không tìm thấy thông tin quán ăn với ID: $storeId');
  }

  /// API-005: Lấy danh sách thực đơn của quán
  Future<List<MenuItemModel>> fetchMenuItems(int storeId) async {
    final uri = Uri.parse('${ApiConfig.stores}/$storeId/menu-items');
    try {
      ApiConfig.log('DB-MENU', 'GET $uri');
      final response = await _client
          .get(
            uri,
            headers: ApiConfig.headers(),
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final rawList = jsonMap['data'] as List<dynamic>? ?? [];
        final items = rawList
            .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        ApiConfig.log('DB-MENU', '✅ Đã tải ${items.length} món ăn của quán ID=$storeId từ Database');
        return items;
      }
    } catch (e) {
      ApiConfig.log('DB-MENU-ERROR', '❌ Lỗi tải thực đơn quán ID=$storeId: $e');
    }

    return [];
  }

  /// API Thêm món ăn mới vào thực đơn quán (POST /api/v1/stores/{storeId}/menu-items)
  Future<MenuItemModel?> createMenuItem({
    required int storeId,
    required String name,
    required double basePrice,
    required String category,
    required String description,
    required String imageUrl,
    List<CustomizationGroupModel>? customizationOptions,
  }) async {
    final uri = Uri.parse('${ApiConfig.stores}/$storeId/menu-items');
    final formattedCustomization = (customizationOptions ?? []).map((g) => {
      'group': g.group,
      'required': g.required,
      'options': g.options.map((o) => {
        'name': o.name,
        'extraPrice': o.extraPrice,
      }).toList(),
    }).toList();

    final body = jsonEncode({
      'name': name,
      'basePrice': basePrice,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'isAvailable': true,
      'customizationOptions': formattedCustomization,
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
      customizationOptions: customizationOptions ?? [],
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
    List<CustomizationGroupModel>? customizationOptions,
  }) async {
    final uri = Uri.parse('${ApiConfig.menuItems}/$id');
    final formattedCustomization = (customizationOptions ?? []).map((g) => {
      'group': g.group,
      'required': g.required,
      'options': g.options.map((o) => {
        'name': o.name,
        'extraPrice': o.extraPrice,
      }).toList(),
    }).toList();

    final body = jsonEncode({
      'name': name,
      'basePrice': basePrice,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      if (isAvailable != null) 'isAvailable': isAvailable,
      'customizationOptions': formattedCustomization,
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

  /// API Cập nhật thông tin cửa hàng (PUT /api/v1/stores/{id})
  Future<StoreModel?> updateStore({
    required int id,
    required String name,
    required String address,
    required String phoneNumber,
    required String description,
    required String avatarUrl,
    required String campusZone,
    bool isActive = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.stores}/$id');
    final body = jsonEncode({
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'description': description,
      'avatarUrl': avatarUrl,
      'campusZone': campusZone,
      'isActive': isActive,
    });
    try {
      final response = await _client.put(uri, headers: ApiConfig.headers(), body: body).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>;
        return StoreModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }
}
