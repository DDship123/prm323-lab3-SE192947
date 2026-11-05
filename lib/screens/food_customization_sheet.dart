import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../widgets/ktx_button.dart';

/// Màn hình S3 (Bottom Sheet): Tùy biến món ăn (Chọn Size bắt buộc & Topping thêm)
class FoodCustomizationSheet extends StatefulWidget {
  final int storeId;
  final String storeName;
  final MenuItemModel menuItem;

  const FoodCustomizationSheet({
    super.key,
    required this.storeId,
    required this.storeName,
    required this.menuItem,
  });

  static Future<void> show(
    BuildContext context, {
    required int storeId,
    required String storeName,
    required MenuItemModel menuItem,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FoodCustomizationSheet(
        storeId: storeId,
        storeName: storeName,
        menuItem: menuItem,
      ),
    );
  }

  @override
  State<FoodCustomizationSheet> createState() => _FoodCustomizationSheetState();
}

class _FoodCustomizationSheetState extends State<FoodCustomizationSheet> {
  int _quantity = 1;
  final Map<String, CustomizationOptionModel> _requiredChoices = {};
  final Map<String, Set<CustomizationOptionModel>> _optionalChoices = {};

  @override
  void initState() {
    super.initState();
    for (final group in widget.menuItem.customizationOptions) {
      if (group.required && group.options.isNotEmpty) {
        _requiredChoices[group.group] = group.options.first;
      } else {
        _optionalChoices[group.group] = {};
      }
    }
  }

  List<SelectedItemOption> _buildSelectedOptions() {
    final result = <SelectedItemOption>[];
    _requiredChoices.forEach((groupName, opt) {
      result.add(
        SelectedItemOption(
          group: groupName,
          choice: opt.name,
          extraPrice: opt.extraPrice,
        ),
      );
    });
    _optionalChoices.forEach((groupName, opts) {
      for (final opt in opts) {
        result.add(
          SelectedItemOption(
            group: groupName,
            choice: opt.name,
            extraPrice: opt.extraPrice,
          ),
        );
      }
    });
    return result;
  }

  double get _totalPrice {
    final extras = _buildSelectedOptions()
        .fold(0.0, (sum, element) => sum + element.extraPrice);
    return (widget.menuItem.basePrice + extras) * _quantity;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadius.roundedFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.menuItem.name,
                          style: AppTypography.heading2,
                        ),
                        if (widget.menuItem.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.menuItem.description!,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _formatCurrency(widget.menuItem.basePrice),
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.lg),
              ...widget.menuItem.customizationOptions.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          group.group,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: group.required
                                ? AppColors.primaryLight.withValues(alpha: 0.4)
                                : AppColors.surfaceVariant,
                            borderRadius: AppRadius.roundedSm,
                          ),
                          child: Text(
                            group.required ? 'Bắt buộc (Chọn 1)' : 'Tùy chọn',
                            style: AppTypography.bodySmall.copyWith(
                              color: group.required
                                  ? AppColors.primaryDark
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...group.options.map((opt) {
                      if (group.required) {
                        final selected = _requiredChoices[group.group] == opt;
                        return RadioListTile<CustomizationOptionModel>(
                          value: opt,
                          groupValue: _requiredChoices[group.group],
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(opt.name, style: AppTypography.bodyMedium),
                          secondary: Text(
                            opt.extraPrice > 0
                                ? '+${_formatCurrency(opt.extraPrice)}'
                                : 'Miễn phí',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _requiredChoices[group.group] = val);
                            }
                          },
                        );
                      } else {
                        final set = _optionalChoices[group.group] ?? {};
                        final checked = set.contains(opt);
                        return CheckboxListTile(
                          value: checked,
                          activeColor: AppColors.primary,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(opt.name, style: AppTypography.bodyMedium),
                          secondary: Text(
                            opt.extraPrice > 0
                                ? '+${_formatCurrency(opt.extraPrice)}'
                                : 'Miễn phí',
                            style: AppTypography.bodySmall,
                          ),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                set.add(opt);
                              } else {
                                set.remove(opt);
                              }
                              _optionalChoices[group.group] = set;
                            });
                          },
                        );
                      }
                    }),
                    const Divider(),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Số lượng phần',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppColors.primary,
                      ),
                      Text(
                        '$_quantity',
                        style: AppTypography.heading3,
                      ),
                      IconButton(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              KtxButton(
                label: 'Thêm vào giỏ gom đơn • ${_formatCurrency(_totalPrice)}',
                icon: Icons.add_shopping_cart_rounded,
                onPressed: () {
                  context.read<AnalyticsService>().logAddToCart(
                        menuItemId: widget.menuItem.id,
                        storeId: widget.storeId,
                        quantity: _quantity,
                        unitPrice: widget.menuItem.basePrice,
                      );
                  context.read<CartCheckoutViewModel>().addItemToCart(
                        storeId: widget.storeId,
                        storeName: widget.storeName,
                        menuItem: widget.menuItem,
                        quantity: _quantity,
                        selectedOptions: _buildSelectedOptions(),
                      );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Đã thêm $_quantity x ${widget.menuItem.name} vào giỏ gom đơn',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
