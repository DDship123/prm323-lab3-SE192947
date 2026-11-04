import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Dịch vụ quản lý tương tác với Firebase Cloud Storage
/// Hỗ trợ đa nền tảng (Web, Android, iOS, Windows)
class CloudStorageService {
  FirebaseStorage? _storage;

  CloudStorageService({FirebaseStorage? storage}) : _storage = storage;

  FirebaseStorage get storage => _storage ??= FirebaseStorage.instance;

  /// Tải dữ liệu ảnh bằng chứng lên Firebase Storage theo đường dẫn chuẩn:
  /// reports/{userId}/{timestamp}_{filename}.jpg
  Future<String> uploadEvidenceBytes({
    required Uint8List imageBytes,
    required String fileName,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last.toLowerCase();
      final validExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(fileExtension)
          ? fileExtension
          : 'jpg';
      final storageFileName = 'evidence_${timestamp}.$validExtension';

      // Đường dẫn theo đặc tả: reports/{userId}/...
      final storageRef = storage
          .ref()
          .child('reports')
          .child(userId)
          .child(storageFileName);

      final metadata = SettableMetadata(
        contentType: 'image/$validExtension',
        customMetadata: {
          'uploadedBy': userId,
          'purpose': 'dispute_evidence',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putData(imageBytes, metadata);

      // Lắng nghe tiến trình upload phục vụ hiển thị thanh Progress Bar
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firebase Cloud Storage [${e.code}]: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tải ảnh lên Đám mây: $e');
    }
  }

  /// Xóa ảnh bằng chứng nếu người dùng hủy bỏ trước khi gửi
  Future<void> deleteImageByUrl(String imageUrl) async {
    try {
      final ref = storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (_) {}
  }
}
