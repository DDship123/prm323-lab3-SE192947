import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_config.dart';

/// Dịch vụ kết nối API-001, API-002, API-002b (Đồng bộ tài khoản & Hồ sơ sinh viên KTX)
class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  /// API-001: Đồng bộ tài khoản Google / OTP xuống MySQL Backend
  Future<UserModel> syncUser({
    required String firebaseUid,
    required String email,
    required String displayName,
    String? phone,
    String? avatarUrl,
    String? ktxBuilding,
    String? ktxRoom,
  }) async {
    final url = Uri.parse(ApiConfig.authSync);
    final payload = {
      'firebaseUid': firebaseUid,
      'email': email,
      'displayName': displayName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      'ktxBuilding': ktxBuilding ?? 'Khu B - Tòa BA1',
      'ktxRoom': ktxRoom ?? '312',
    };

    try {
      final response = await _client
          .post(
            url,
            headers: ApiConfig.headers(),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          final user = UserModel.fromJson(data);
          ApiConfig.currentBackendUserId = user.id;
          return user;
        }
      }
    } catch (_) {
      // Fallback sang hồ sơ cục bộ nếu Backend chưa bật
    }

    return UserModel(
      id: ApiConfig.currentBackendUserId,
      firebaseUid: firebaseUid,
      email: email,
      displayName: displayName,
      phone: phone ?? '0987654321',
      avatarUrl: avatarUrl,
      ktxBuilding: ktxBuilding ?? 'Khu B - Tòa BA1',
      ktxRoom: ktxRoom ?? '312',
    );
  }

  /// API-002: Lấy hồ sơ người dùng hiện tại
  Future<UserModel> fetchMyProfile() async {
    try {
      final response = await _client
          .get(Uri.parse(ApiConfig.usersMe), headers: ApiConfig.headers())
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          return UserModel.fromJson(data);
        }
      }
    } catch (_) {}

    return UserModel(
      id: ApiConfig.currentBackendUserId,
      firebaseUid: 'student_ktx_demo',
      email: 'student@fpt.edu.vn',
      displayName: 'Sinh viên KTX',
      phone: '0987654321',
      ktxBuilding: 'Khu B - Tòa BA1',
      ktxRoom: '312',
    );
  }

  /// API-002b: Cập nhật hồ sơ sinh viên KTX
  Future<UserModel> updateMyProfile({
    required String displayName,
    required String phone,
    required String ktxBuilding,
    required String ktxRoom,
  }) async {
    try {
      final response = await _client
          .patch(
            Uri.parse(ApiConfig.usersMe),
            headers: ApiConfig.headers(),
            body: jsonEncode({
              'displayName': displayName,
              'phone': phone,
              'ktxBuilding': ktxBuilding,
              'ktxRoom': ktxRoom,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final data = jsonMap['data'] as Map<String, dynamic>?;
        if (data != null) {
          return UserModel.fromJson(data);
        }
      }
    } catch (_) {}

    return UserModel(
      id: ApiConfig.currentBackendUserId,
      firebaseUid: 'student_ktx_demo',
      email: 'student@fpt.edu.vn',
      displayName: displayName,
      phone: phone,
      ktxBuilding: ktxBuilding,
      ktxRoom: ktxRoom,
    );
  }
}
