import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Ô nhập liệu chuẩn KTX Food theo tài liệu thông số thiết kế (Mục 5):
/// - Nền #f3f4f6, bo góc 12, cao 44
/// - Nhãn trường nhập: 12 Semi Bold, #6b7280 (nằm phía trên)
/// - Chữ gợi ý: #9ca3af
/// - Vùng chạm tối thiểu 44x44
class KtxTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final int maxLines;
  final bool readOnly;
  final Object? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const KtxTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.maxLines = 1,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
  });

  Widget? _resolvePrefixIcon() {
    if (prefixIcon == null) return null;
    if (prefixIcon is Widget) return prefixIcon as Widget;
    if (prefixIcon is IconData) {
      return Icon(prefixIcon as IconData, size: 18, color: AppColors.textSecondary);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label ?? hintText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTypography.inputLabel,
            ),
            const SizedBox(height: 6),
          ],
          TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.caption,
              errorText: errorText,
              prefixIcon: _resolvePrefixIcon(),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.surfaceVariant, // #f3f4f6
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: maxLines > 1 ? 12 : 13,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd, // bo 12
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: const BorderSide(color: AppColors.error, width: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
