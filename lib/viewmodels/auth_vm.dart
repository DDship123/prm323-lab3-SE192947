import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

/// ViewModel quản lý xác thực, đồng bộ sinh viên KTX (S0, S0_Reg, S0_OTP, S13)
class AuthViewModel extends ChangeNotifier {
  final AuthApiService _authApiService;

  UserModel? _currentUser;
  bool _isSyncing = false;
  bool _isUploadingAvatar = false;
  String? _errorMessage;
  String _pendingPhone = '';

  AuthViewModel({required AuthApiService authApiService})
      : _authApiService = authApiService;

  UserModel? get currentUser => _currentUser;
  bool get isSyncing => _isSyncing;
  bool get isUploadingAvatar => _isUploadingAvatar;
  String? get errorMessage => _errorMessage;
  String get pendingPhone => _pendingPhone;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Đồng bộ tài khoản sau khi đăng nhập Google Sign-In
  Future<void> syncFirebaseUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authApiService.syncUser(
        firebaseUid: uid,
        email: email,
        displayName: displayName,
        avatarUrl: photoUrl,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Lưu thông tin đăng ký tài khoản sinh viên KTX (S0_Reg -> S0_OTP)
  Future<bool> registerStudent({
    required String email,
    required String displayName,
    required String phone,
    required String ktxBuilding,
    required String ktxRoom,
  }) async {
    if (displayName.trim().isEmpty || phone.trim().length < 9) {
      _errorMessage = 'Vui lòng nhập đầy đủ họ tên và số điện thoại hợp lệ.';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _errorMessage = null;
    _pendingPhone = phone.trim();
    notifyListeners();

    try {
      _currentUser = await _authApiService.syncUser(
        firebaseUid: 'phone_${phone.trim()}',
        email: email.trim().isEmpty
            ? '${phone.trim()}@student.fpt.edu.vn'
            : email.trim(),
        displayName: displayName.trim(),
        phone: phone.trim(),
        ktxBuilding: ktxBuilding,
        ktxRoom: ktxRoom,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Xác thực mã OTP 6 chữ số (S0_OTP)
  bool verifyOtp(String otpCode) {
    if (otpCode.trim().length != 6) {
      _errorMessage = 'Mã OTP phải gồm đúng 6 chữ số (Gợi ý demo: 123456).';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  /// Cập nhật thông tin phòng KTX tại S13
  Future<bool> updateProfile({
    required String displayName,
    required String phone,
    required String ktxBuilding,
    required String ktxRoom,
    String? avatarUrl,
  }) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authApiService.updateMyProfile(
        displayName: displayName,
        phone: phone,
        ktxBuilding: ktxBuilding,
        ktxRoom: ktxRoom,
        avatarUrl: avatarUrl ?? _currentUser?.avatarUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Cập nhật ảnh đại diện (Upload từ máy lên)
  Future<bool> updateAvatar(String newAvatarUrl) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final current = _currentUser;
      _currentUser = await _authApiService.updateMyProfile(
        displayName: current?.displayName ?? 'Sinh viên KTX',
        phone: current?.phone ?? '0968097907',
        ktxBuilding: current?.ktxBuilding ?? 'Khu B - Tòa BA1',
        ktxRoom: current?.ktxRoom ?? '312',
        avatarUrl: newAvatarUrl,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Tải lên ảnh đại diện dạng nhị phân lên máy chủ
  Future<bool> uploadAvatarFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authApiService.uploadAvatarFile(
        bytes: bytes,
        fileName: fileName,
      );
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          avatarUrl: updatedUser.avatarUrl,
        );
      } else {
        _currentUser = updatedUser;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }

  /// Xóa hoặc đặt lại ảnh đại diện về mặc định
  Future<bool> removeAvatar() async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authApiService.deleteAvatar();
      if (_currentUser != null) {
        _currentUser = UserModel(
          id: _currentUser!.id,
          firebaseUid: _currentUser!.firebaseUid,
          email: _currentUser!.email,
          displayName: _currentUser!.displayName,
          phone: _currentUser!.phone,
          role: _currentUser!.role,
          avatarUrl: null,
          ktxBuilding: _currentUser!.ktxBuilding,
          ktxRoom: _currentUser!.ktxRoom,
          ratingAvg: _currentUser!.ratingAvg,
          ratingCount: _currentUser!.ratingCount,
          isBanned: _currentUser!.isBanned,
        );
      } else {
        _currentUser = updatedUser;
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
  }
}
