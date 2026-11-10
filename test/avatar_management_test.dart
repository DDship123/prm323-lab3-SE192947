import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:prm393_lab03_se192947/models/user_model.dart';
import 'package:prm393_lab03_se192947/services/api_config.dart';
import 'package:prm393_lab03_se192947/services/auth_api_service.dart';
import 'package:prm393_lab03_se192947/viewmodels/auth_vm.dart';
import 'package:prm393_lab03_se192947/widgets/ktx_app_bar.dart';

class _FakeHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _FakeHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _transparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  setUpAll(() {
    HttpOverrides.global = _FakeHttpOverrides();
  });

  group('UserModel copyWith Tests', () {
    test('copyWith updates avatarUrl and preserves other fields', () {
      const original = UserModel(
        id: 1,
        firebaseUid: 'uid_123',
        email: 'student@fpt.edu.vn',
        displayName: 'Nguyễn Văn A',
        phone: '0912345678',
        role: 'STUDENT',
        avatarUrl: null,
        ktxBuilding: 'BA1',
        ktxRoom: '312',
      );

      final updated = original.copyWith(
        avatarUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      );

      expect(updated.id, original.id);
      expect(updated.firebaseUid, original.firebaseUid);
      expect(updated.email, original.email);
      expect(updated.displayName, original.displayName);
      expect(updated.phone, original.phone);
      expect(updated.role, original.role);
      expect(updated.avatarUrl, 'https://res.cloudinary.com/demo/image/upload/sample.jpg');
      expect(updated.ktxBuilding, original.ktxBuilding);
      expect(updated.ktxRoom, original.ktxRoom);
    });

    test('copyWith updates multiple fields simultaneously', () {
      const original = UserModel(
        id: 2,
        firebaseUid: 'uid_owner',
        email: 'coba.owner@fpt.edu.vn',
        displayName: 'Cô Ba',
        role: 'STORE_OWNER',
      );

      final updated = original.copyWith(
        displayName: 'Cô Ba Quán Ăn KTX',
        avatarUrl: 'https://cdn.example.com/owner.png',
        phone: '0987654321',
      );

      expect(updated.id, 2);
      expect(updated.displayName, 'Cô Ba Quán Ăn KTX');
      expect(updated.avatarUrl, 'https://cdn.example.com/owner.png');
      expect(updated.phone, '0987654321');
      expect(updated.role, 'STORE_OWNER');
    });
  });

  group('AuthApiService Avatar Tests', () {
    test('uploadAvatarFile sends multipart request and parses updated user', () async {
      ApiConfig.currentBackendUserId = 1;

      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, endsWith('/users/me/avatar'));
        expect(request.headers['X-User-Id'], '1');

        final responseJson = {
          'status': 'SUCCESS',
          'message': 'Tải lên ảnh đại diện thành công',
          'data': {
            'id': 1,
            'firebaseUid': 'uid_123',
            'email': 'student@fpt.edu.vn',
            'displayName': 'Nguyễn Văn A',
            'role': 'STUDENT',
            'avatarUrl': 'https://res.cloudinary.com/food_ordering/avatars/user_1.jpg',
          },
        };

        return http.Response.bytes(
          utf8.encode(jsonEncode(responseJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthApiService(client: mockClient);
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final user = await service.uploadAvatarFile(bytes: bytes, fileName: 'avatar.jpg');

      expect(user.id, 1);
      expect(user.avatarUrl, 'https://res.cloudinary.com/food_ordering/avatars/user_1.jpg');
    });

    test('deleteAvatar sends DELETE request and returns updated user with null avatarUrl', () async {
      ApiConfig.currentBackendUserId = 3;

      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, endsWith('/users/me/avatar'));

        final responseJson = {
          'status': 'SUCCESS',
          'message': 'Xóa ảnh đại diện thành công',
          'data': {
            'id': 3,
            'firebaseUid': 'shipper_uid',
            'email': 'shipper.hung@fpt.edu.vn',
            'displayName': 'Nguyễn Hùng (Shipper)',
            'role': 'SHIPPER',
            'avatarUrl': null,
          },
        };

        return http.Response.bytes(
          utf8.encode(jsonEncode(responseJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthApiService(client: mockClient);
      final user = await service.deleteAvatar();

      expect(user.id, 3);
      expect(user.avatarUrl, isNull);
    });

    test('updateMyProfile preserves empty avatarUrl string in payload', () async {
      Map<String, dynamic>? capturedPayload;

      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;

        final responseJson = {
          'status': 'SUCCESS',
          'data': {
            'id': 1,
            'firebaseUid': 'uid_123',
            'email': 'student@fpt.edu.vn',
            'displayName': 'Nguyễn Văn A',
            'role': 'STUDENT',
            'avatarUrl': null,
          },
        };

        return http.Response.bytes(
          utf8.encode(jsonEncode(responseJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthApiService(client: mockClient);
      await service.updateMyProfile(
        displayName: 'Nguyễn Văn A',
        phone: '0912345678',
        ktxBuilding: 'BA1',
        ktxRoom: '312',
        avatarUrl: '', // explicit empty to clear
      );

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.containsKey('avatarUrl'), isTrue);
      expect(capturedPayload!['avatarUrl'], '');
    });
  });

  group('AuthViewModel Avatar Lifecycle Tests', () {
    test('uploadAvatarFile updates currentUser and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          'status': 'SUCCESS',
          'data': {
            'id': 1,
            'firebaseUid': 'uid_1',
            'email': 'student@fpt.edu.vn',
            'displayName': 'Nguyễn Văn A',
            'avatarUrl': 'https://res.cloudinary.com/avatar_new.jpg',
          },
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responseJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthApiService(client: mockClient);
      final vm = AuthViewModel(authApiService: service);

      vm.setCurrentUser(const UserModel(
        id: 1,
        firebaseUid: 'uid_1',
        email: 'student@fpt.edu.vn',
        displayName: 'Nguyễn Văn A',
        avatarUrl: null,
      ));

      int notificationCount = 0;
      vm.addListener(() {
        notificationCount++;
      });

      expect(vm.isUploadingAvatar, isFalse);

      final success = await vm.uploadAvatarFile(
        bytes: Uint8List.fromList([10, 20, 30]),
        fileName: 'profile.png',
      );

      expect(success, isTrue);
      expect(vm.isUploadingAvatar, isFalse);
      expect(vm.currentUser?.avatarUrl, 'https://res.cloudinary.com/avatar_new.jpg');
      expect(notificationCount, greaterThanOrEqualTo(2)); // start + finish
    });

    test('removeAvatar resets avatarUrl to null and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        final responseJson = {
          'status': 'SUCCESS',
          'data': {
            'id': 1,
            'firebaseUid': 'uid_1',
            'email': 'student@fpt.edu.vn',
            'displayName': 'Nguyễn Văn A',
            'avatarUrl': null,
          },
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responseJson)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = AuthApiService(client: mockClient);
      final vm = AuthViewModel(authApiService: service);

      vm.setCurrentUser(const UserModel(
        id: 1,
        firebaseUid: 'uid_1',
        email: 'student@fpt.edu.vn',
        displayName: 'Nguyễn Văn A',
        avatarUrl: 'https://res.cloudinary.com/old_avatar.jpg',
      ));

      expect(vm.currentUser?.avatarUrl, isNotNull);

      final success = await vm.removeAvatar();

      expect(success, isTrue);
      expect(vm.currentUser?.avatarUrl, isNull);
    });
  });

  group('KtxAppBar Dynamic Avatar Widget Tests', () {
    testWidgets('KtxAppBar displays network image when currentUser has avatarUrl', (tester) async {
      final mockClient = MockClient((_) async => http.Response('{}', 200));
      final authVm = AuthViewModel(authApiService: AuthApiService(client: mockClient));
      authVm.setCurrentUser(const UserModel(
        id: 1,
        firebaseUid: 'uid_1',
        email: 'student@fpt.edu.vn',
        displayName: 'Test Student',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVm,
            child: Scaffold(
              appBar: KtxAppBar(
                title: 'Test Header',
                onAvatarTap: () {},
              ),
            ),
          ),
        ),
      );

      final circleAvatarFinder = find.byType(CircleAvatar);
      expect(circleAvatarFinder, findsOneWidget);

      final circleAvatar = tester.widget<CircleAvatar>(circleAvatarFinder);
      expect(circleAvatar.backgroundImage, isNotNull);
      expect(circleAvatar.backgroundImage, isA<NetworkImage>());
    });

    testWidgets('KtxAppBar displays fallback icon when currentUser has null avatarUrl', (tester) async {
      final mockClient = MockClient((_) async => http.Response('{}', 200));
      final authVm = AuthViewModel(authApiService: AuthApiService(client: mockClient));
      authVm.setCurrentUser(const UserModel(
        id: 1,
        firebaseUid: 'uid_1',
        email: 'student@fpt.edu.vn',
        displayName: 'Test Student',
        avatarUrl: null,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthViewModel>.value(
            value: authVm,
            child: Scaffold(
              appBar: KtxAppBar(
                title: 'Test Header',
                onAvatarTap: () {},
              ),
            ),
          ),
        ),
      );

      final circleAvatarFinder = find.byType(CircleAvatar);
      expect(circleAvatarFinder, findsOneWidget);

      final circleAvatar = tester.widget<CircleAvatar>(circleAvatarFinder);
      expect(circleAvatar.backgroundImage, isNull);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });
}
