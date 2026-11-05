import 'package:flutter/material.dart';

/// Hằng số bo góc (Border Radius) chuẩn Design System
/// - Thẻ (card): bo góc 16
/// - Nút, ô nhập: bo góc 12
/// - Chip và pill: bo góc 9999
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0; // Nút, ô nhập
  static const double card = 16.0; // Thẻ
  static const double lg = 16.0;
  static const double full = 9999.0; // Chip & pill

  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedCard = BorderRadius.circular(card);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedFull = BorderRadius.circular(full);
}
