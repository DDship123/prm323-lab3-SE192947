import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Định nghĩa kiểu chữ chuẩn hóa Inter theo tài liệu Thông số thiết kế (Node 462:1932)
class AppTypography {
  AppTypography._();

  // Tiêu đề Header & Tiêu đề Thẻ: 16 Bold
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Tên quán, Tên món: 14 Bold
  static const TextStyle storeTitle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Giá món: 14 Bold, #ff5722
  static const TextStyle price = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  // Nội dung thường: 12 Regular
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Chú thích: 10–11 Regular
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // Nhãn chip, pill: 10 Bold
  static const TextStyle chipLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w700,
  );

  // Nhãn trường nhập: 12 Semi Bold, #6b7280
  static const TextStyle inputLabel = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  // Nút chuẩn: 12 Bold
  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );
}
