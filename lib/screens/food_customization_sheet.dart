import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_service.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../viewmodels/cart_checkout_vm.dart';

/// MÃ n hÃ¬nh S3 (TÃ¹y Biáº¿n MÃ³n Ä‚n): Chá»n Size báº¯t buá»™c, Topping thÃªm, Ghi chÃº chuáº©n Figma
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
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
  final TextEditingController _noteCtrl = TextEditingController();

  List<CustomizationGroupModel> get _effectiveGroups {
    // Æ¯u tiÃªn hÃ ng Ä‘áº§u: Láº¥y Ä‘Ãºng customizationOptions thá»±c táº¿ cá»§a mÃ³n Äƒn tá»« Backend
    if (widget.menuItem.customizationOptions.isNotEmpty) {
      return widget.menuItem.customizationOptions;
    }
    return const [];
  }

  @override
  void initState() {
    super.initState();
    final groups = _effectiveGroups;
    for (final group in groups) {
      if (group.required && group.options.isNotEmpty) {
        _requiredChoices[group.group] = group.options.first;
      } else {
        _optionalChoices[group.group] = {};
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
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
    final extras = _buildSelectedOptions().fold(
      0.0,
      (sum, element) => sum + element.extraPrice,
    );
    return (widget.menuItem.basePrice + extras) * _quantity;
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}Ä‘';
  }

  void _addQuickChip(String chipText) {
    final clean = chipText.replaceAll('+ ', '');
    final current = _noteCtrl.text.trim();
    if (current.isEmpty) {
      _noteCtrl.text = clean;
    } else if (!current.contains(clean)) {
      _noteCtrl.text = '$current, $clean';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _effectiveGroups;
    final quickChips = [
      '+ Ãt cay',
      '+ KhÃ´ng hÃ nh lÃ¡',
      '+ Äá»ƒ riÃªng nÆ°á»›c máº¯m',
      '+ Xin thÃªm Ä‘á»“ chua',
      '+ CÆ¡m nhiá»u chÃ¡y giÃ²n',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay láº¡i thá»±c Ä‘Æ¡n',
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'TÃ¹y Biáº¿n MÃ³n Ä‚n',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'ThÃ´ng bÃ¡o',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF521B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Giá» hÃ ng',
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF1E293B),
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
              ),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Giáº£m sá»‘ lÆ°á»£ng',
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove, size: 16),
                        color: const Color(0xFF475569),
                      ),
                      Semantics(
                        identifier: 'text_customize_qty',
                        label: 'Sá»‘ lÆ°á»£ng',
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'TÄƒng sá»‘ lÆ°á»£ng',
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add, size: 16),
                        color: const Color(0xFFFF521B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: Semantics(
                      identifier: 'btn_customize_add_to_cart',
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF521B),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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
                                'ÄÃ£ thÃªm $_quantity x ${widget.menuItem.name} vÃ o giá»',
                              ),
                              backgroundColor: const Color(0xFFFF521B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          'ThÃªm vÃ o giá» â€¢ ${_formatCurrency(_totalPrice)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(Icons.explore_outlined, 'KhÃ¡m phÃ¡', true),
                _buildBottomNavItem(
                  Icons.restaurant_outlined,
                  'Äáº·t mÃ³n',
                  false,
                ),
                _buildBottomNavItem(
                  Icons.receipt_long_rounded,
                  'Thanh toÃ¡n',
                  false,
                ),
                _buildBottomNavItem(Icons.history_rounded, 'Lá»‹ch sá»­', false),
                _buildBottomNavItem(
                  Icons.person_outline_rounded,
                  'TÃ i khoáº£n',
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. áº¢nh bÃ¬a Hero cá»§a mÃ³n Äƒn kÃ¨m nhÃ£n
            Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child:
                      widget.menuItem.imageUrl != null &&
                          widget.menuItem.imageUrl!.isNotEmpty
                      ? Image.network(
                          widget.menuItem.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(
                                  Icons.fastfood_rounded,
                                  size: 50,
                                  color: Color(0xFFFF521B),
                                ),
                              ),
                        )
                      : Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.fastfood_rounded,
                            size: 50,
                            color: Color(0xFFFF521B),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF521B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ðŸ”¥ BÃ¡n cháº¡y nháº¥t Ca TrÆ°a',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Chuáº©n Vá»‹ SÃ i GÃ²n',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ðŸ“ KTX Khu B â€¢ Chá»‘t lÃºc 10:45 TrÆ°a nay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 14,
                            ),
                            SizedBox(width: 3),
                            Text(
                              '4.9 (1.2k+)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 2. TiÃªu Ä‘á» mÃ³n & MÃ´ táº£
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.menuItem.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.storeName} â€¢ KTX Khu B (Cá»•ng 2)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatCurrency(widget.menuItem.basePrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF521B),
                        ),
                      ),
                      if (widget.menuItem.originalPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(widget.menuItem.originalPrice!),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: const Text(
                          '-16% Trá»£ giÃ¡ KTX',
                          style: TextStyle(
                            color: Color(0xFFFF521B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.menuItem.description ?? 'Pháº§n cÆ¡m táº¥m sÆ°á»n que nÆ°á»›ng than hoa máº­t ong thÆ¡m lá»«ng, bÃ¬ riá»ng trá»™n thÃ­nh vÃ ng Ã³ng, cháº£ trá»©ng háº¥p bÃ©o bÃ¹i, kÃ¨m má»¡ hÃ nh tÃ³p má»¡ giÃ²n vÃ  Ä‘á»“ chua nhÃ  lÃ m tÆ°Æ¡i ngon.',
                    (widget.menuItem.description != null && widget.menuItem.description!.isNotEmpty)
                        ? widget.menuItem.description!
                        : 'MÃ³n Äƒn thÆ¡m ngon, nÃ³ng há»•i cháº¿ biáº¿n phá»¥c vá»¥ sinh viÃªn KTX.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD1FAE5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Há»™p bÃ£ mÃ­a giá»¯ nhiá»‡t tá»± há»§y, Ä‘Ã³ng gÃ³i náº¯p kÃ­n vÃ  tÄƒm mÃ¨ diá»‡t khuáº©n cho sinh viÃªn.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // 3. Danh sÃ¡ch cÃ¡c nhÃ³m tÃ¹y biáº¿n (Figma 4 nhÃ³m)
            ...groups.map((group) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF521B),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              group.group,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: group.required
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            group.required
                                ? 'Báº¯t buá»™c â€¢ Chá»n 1'
                                : 'TÃ¹y chá»n â€¢ Tá»‘i Ä‘a 5',
                            style: TextStyle(
                              color: group.required
                                  ? const Color(0xFFFF521B)
                                  : const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...group.options.map((opt) {
                      if (group.required) {
                        final isSelected = _requiredChoices[group.group] == opt;
                        return InkWell(
                          onTap: () {
                            setState(() => _requiredChoices[group.group] = opt);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF521B)
                                    : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? const Color(0xFFFF521B)
                                      : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opt.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Text(
                                  opt.extraPrice > 0
                                      ? '+${_formatCurrency(opt.extraPrice)}'
                                      : (opt.name.contains('Máº·c Ä‘á»‹nh')
                                            ? 'Máº·c Ä‘á»‹nh'
                                            : '+0Ä‘'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: opt.extraPrice > 0
                                        ? const Color(0xFFFF521B)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        final set = _optionalChoices[group.group] ?? {};
                        final isChecked = set.contains(opt);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                set.remove(opt);
                              } else {
                                set.add(opt);
                              }
                              _optionalChoices[group.group] = set;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isChecked
                                    ? const Color(0xFFFF521B)
                                    : const Color(0xFFE2E8F0),
                                width: isChecked ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isChecked
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: isChecked
                                      ? const Color(0xFFFF521B)
                                      : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    opt.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isChecked
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Text(
                                  opt.extraPrice > 0
                                      ? '+${_formatCurrency(opt.extraPrice)}'
                                      : 'Miá»…n phÃ­',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isChecked
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: opt.extraPrice > 0
                                        ? const Color(0xFFFF521B)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }),
                  ],
                ),
              );
            }),

            // 4. Ghi chÃº cho QuÃ¡n CÃ´ Ba & 5 Quick Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF475569),
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ghi chÃº cho QuÃ¡n CÃ´ Ba',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'QuÃ¡n luÃ´n cá»‘ gáº¯ng chuáº©n bá»‹ theo Ä‘Ãºng yÃªu cáº§u cá»§a báº¡n sinh viÃªn.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'VÃ­ dá»¥: Äá»“ chua Ä‘á»ƒ riÃªng, cho xin thÃªm muá»—ng nÄ©a dÃ¹ng 1 láº§n, cÆ¡m sáº¥y khÃ´ rÃ¡o...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickChips.map((chip) {
                        return InkWell(
                          onTap: () => _addQuickChip(chip),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              chip,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 5. Khung xanh cam káº¿t giao cháº·n ca trÆ°a KTX
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cam káº¿t Giao Cháº·n Ca TrÆ°a KTX',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'ÄÆ¡n hÃ ng Ä‘Æ°á»£c quÃ¡n nÆ°á»›ng nÃ³ng trÆ°á»›c giá» giao 15 phÃºt. Xe gom KTX táº­p káº¿t táº¡i Cá»•ng KTX Khu B Ä‘Ãºng 11:30.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
