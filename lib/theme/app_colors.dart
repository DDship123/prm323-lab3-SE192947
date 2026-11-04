import 'package:flutter/material.dart';

/// Bảng màu chuẩn hóa nhận diện ứng dụng Đặt món KTX
class AppColors {
  AppColors._();

  // Màu sắc chủ đạo (Brand Primary)
  static const Color primary = Color(0xFFFF5722); // Cam KTX
  static const Color primaryLight = Color(0xFFFFCCBC);
  static const Color primaryDark = Color(0xFFE64A19);

  // Màu nền & Bề mặt (Neutral / Surfaces)
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F4);

  // Màu văn bản (Text Colors)
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // Màu trạng thái (Feedback Colors)
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57C00);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1976D2);

  // Màu viền và ngăn cách
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);
}

