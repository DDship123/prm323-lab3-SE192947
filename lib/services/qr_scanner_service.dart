import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zxing_lib/common.dart';
import 'package:zxing_lib/qrcode.dart';
import 'package:zxing_lib/zxing.dart';

class QrScannerService {
  static final ImagePicker _picker = ImagePicker();

  /// Quét mã QR bằng Camera thật của thiết bị / webcam Chrome
  static Future<String?> scanQrFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      return await decodeQrFromBytes(bytes);
    } catch (e) {
      debugPrint('Lỗi mở Camera quét QR: $e');
      return null;
    }
  }

  /// Quét mã QR bằng cách chọn ảnh từ thư viện / ảnh chụp màn hình
  static Future<String?> scanQrFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked == null) return null;
      final bytes = await picked.readAsBytes();
      return await decodeQrFromBytes(bytes);
    } catch (e) {
      debugPrint('Lỗi chọn ảnh QR: $e');
      return null;
    }
  }

  /// Giải mã chuỗi QR từ dữ liệu ảnh nhị phân bằng ZXing
  static Future<String?> decodeQrFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final int32List = byteData.buffer.asInt32List();
      final source = RGBLuminanceSource(img.width, img.height, int32List);
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final reader = QRCodeReader();
      final result = reader.decode(bitmap);
      return result.text;
    } catch (e) {
      debugPrint('ZXing không tìm thấy QR hoặc lỗi giải mã: $e');
      return null;
    }
  }
}
