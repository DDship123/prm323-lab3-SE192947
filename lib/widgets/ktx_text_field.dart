import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Ô nhập liệu chuẩn C02 hỗ trợ nhãn lỗi và trạng thái focus viền cam
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
      return Icon(prefixIcon as IconData, color: AppColors.textSecondary);
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
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
              hintStyle:
                  AppTypography.bodyMedium.copyWith(color: AppColors.textHint),
              errorText: errorText,
              prefixIcon: _resolvePrefixIcon(),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: readOnly ? AppColors.surfaceVariant : Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: AppRadius.roundedMd,
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
