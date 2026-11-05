import 'package:flutter/material.dart';

/// Bảng màu chuẩn KTX Food theo tài liệu Thông số thiết kế (Node 462:1932)
class AppColors {
  AppColors._();

  // Nền trang
  static const Color background = Color(0xFFF8FAFC); // #f8fafc

  // Chữ
  static const Color textPrimary = Color(0xFF111827); // #111827 (Chữ chính)
  static const Color textSecondary = Color(0xFF6B7280); // #6b7280 (Chữ phụ)
  static const Color textHint = Color(0xFF9CA3AF); // #9ca3af (Chữ chú thích / gợi ý)

  // Màu thương hiệu chính
  static const Color primary = Color(0xFFFF5722); // #ff5722 (Màu thương hiệu, nút chính, giá)
  static const Color primaryLight = Color(0xFFFFEDD5); // #ffedd5 (Nền nút phụ / pill chờ)
  static const Color primaryDark = Color(0xFFC2410C); // #c2410c (Chữ nút phụ / chữ trạng thái chờ)

  // Bề mặt & Nền card
  static const Color surface = Colors.white; // #ffffff
  static const Color surfaceVariant = Color(0xFFF3F4F6); // #f3f4f6 (Ô nhập, ô tìm kiếm, pill đã tiếp nhận)
  static const Color headerBtnBackground = Color(0xFFF9FAFB); // #f9fafb (Nút tròn header 44x44)
  static const Color iconBoxBackground = Color(0xFFFFF7ED); // #fff7ed (Ô icon)

  // Viền
  static const Color border = Color(0xFFF3F4F6); // #f3f4f6 (Viền nhẹ chuẩn card)
  static const Color borderStrong = Color(0xFFE5E7EB); // #e5e7eb (Viền ngăn cách)
  static const Color divider = Color(0xFFF3F4F6); // #f3f4f6

  // Trạng thái - Xong / Hoàn thành (Pill xanh)
  static const Color success = Color(0xFF059669); // #059669
  static const Color successLight = Color(0xFFF9FAFB); // Nền hộp xong #f9fafb

  // Trạng thái - Chờ / Đang xử lý
  static const Color warning = Color(0xFFC2410C); // #c2410c
  static const Color warningLight = Color(0xFFFFEDD5); // nền #ffedd5
  static const Color warningBox = Color(0xFFFFF7ED); // hộp #fff7ed

  // Trạng thái - Từ chối / Nguy hiểm / Lỗi
  static const Color error = Color(0xFFB91C1C); // #b91c1c (Thông báo lỗi, chữ nút nguy hiểm)
  static const Color errorLight = Color(0xFFFEF2F2); // nền nút nguy hiểm #fef2f2
  static const Color errorBorder = Color(0xFFFECACA); // viền nút nguy hiểm #fecaca

  // Trạng thái - Đã tiếp nhận
  static const Color info = Color(0xFF6B7280); // #6b7280
  static const Color infoLight = Color(0xFFF3F4F6); // #f3f4f6

  // Chevron & Icon phụ
  static const Color chevron = Color(0xFF9CA3AF); // #9ca3af
}
