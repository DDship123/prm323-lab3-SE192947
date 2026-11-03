import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Dịch vụ quản lý tương tác với Firebase Cloud Storage
/// Chuyên trách tải ảnh bằng chứng khiếu nại và biên bản sự cố
class CloudStorageService {
  FirebaseStorage? _storage;

  CloudStorageService({FirebaseStorage? storage}) : _storage = storage;

  FirebaseStorage get storage => _storage ??= FirebaseStorage.instance;

  /// Tải tệp ảnh bằng chứng lên Firebase Storage theo đường dẫn chuẩn:
  /// reports/{userId}/{timestamp}_{filename}.jpg
  Future<String> uploadEvidenceImage({
    required File imageFile,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    if (!await imageFile.exists()) {
      throw Exception('Tệp ảnh không tồn tại trên thiết bị.');
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      final validExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(fileExtension)
          ? fileExtension
          : 'jpg';
      final fileName = 'evidence_${timestamp}.$validExtension';

      // Đường dẫn theo đặc tả: reports/{userId}/...
      final storageRef = storage
          .ref()
          .child('reports')
          .child(userId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/$validExtension',
        customMetadata: {
          'uploadedBy': userId,
          'purpose': 'dispute_evidence',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);

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
    } catch (_) {
      // Bỏ qua lỗi xóa nếu file không tồn tại
    }
  }
}
