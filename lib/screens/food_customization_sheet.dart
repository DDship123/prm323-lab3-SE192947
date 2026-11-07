import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../firebase/analytics_service.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../viewmodels/cart_checkout_vm.dart';

/// Màn hình S3 (Tùy Biến Món Ăn): Chọn Size bắt buộc, Topping thêm, Ghi chú chuẩn Figma
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
    if (widget.menuItem.customizationOptions.length >= 3) {
      return widget.menuItem.customizationOptions;
    }
    return const [
      CustomizationGroupModel(
        group: 'Chọn Kích cỡ / Phần Ăn',
        required: true,
        options: [
          CustomizationOptionModel(
            name: 'Phần Tiêu chuẩn (Vừa ăn, chuẩn no cho sinh viên)',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Phần No nê Sinh viên (Thêm 1 bát cơm xới đầy)',
            extraPrice: 5000,
          ),
          CustomizationOptionModel(
            name: 'Phần Thượng hạng (Thêm 1 sườn que + 1 miếng chả)',
            extraPrice: 15000,
          ),
        ],
      ),
      CustomizationGroupModel(
        group: 'Khẩu vị & Mỡ hành',
        required: true,
        options: [
          CustomizationOptionModel(
            name: 'Mỡ hành tóp mỡ truyền thống (Khuyên dùng)',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Nhiều mỡ hành, tóp mỡ giòn rụm',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Ít mỡ hành, không lấy tóp mỡ',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Không lấy mỡ hành (Ăn thanh đạm)',
            extraPrice: 0,
          ),
        ],
      ),
      CustomizationGroupModel(
        group: 'Topping thêm hấp dẫn',
        required: false,
        options: [
          CustomizationOptionModel(
            name: 'Trứng ốp la lòng đào sốt nước tương',
            extraPrice: 6000,
          ),
          CustomizationOptionModel(
            name: 'Chả trứng hấp nấm mèo (1 miếng)',
            extraPrice: 5000,
          ),
          CustomizationOptionModel(
            name: 'Sườn que ướp mật ong (1 miếng to)',
            extraPrice: 15000,
          ),
          CustomizationOptionModel(
            name: 'Bì heo trộn thính thơm giòn',
            extraPrice: 7000,
          ),
          CustomizationOptionModel(
            name: 'Canh rong biển thịt bằm nóng hổi',
            extraPrice: 5000,
          ),
          CustomizationOptionModel(
            name: 'Canh chua cá lóc đồng',
            extraPrice: 12000,
          ),
        ],
      ),
      CustomizationGroupModel(
        group: 'Độ cay & Nước mắm',
        required: true,
        options: [
          CustomizationOptionModel(
            name: 'Nước mắm kẹo chua ngọt cay vừa (Chuẩn vị)',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Nước mắm cay nhiều (Thêm ớt băm tươi)',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Nước mắm không cay (Không ớt)',
            extraPrice: 0,
          ),
          CustomizationOptionModel(
            name: 'Nước mắm để riêng trong bịch',
            extraPrice: 0,
          ),
        ],
      ),
    ];
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
        for (final opt in group.options) {
          if (opt.name.contains('Trứng ốp la') ||
              opt.name.contains('Canh rong biển')) {
            _optionalChoices[group.group]!.add(opt);
          }
        }
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
    return '${formatter.format(amount)}đ';
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
      '+ Ít cay',
      '+ Không hành lá',
      '+ Để riêng nước mắm',
      '+ Xin thêm đồ chua',
      '+ Cơm nhiều cháy giòn',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại thực đơn',
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tùy Biến Món Ăn',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Thông báo',
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
            tooltip: 'Giỏ hàng',
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
                        tooltip: 'Giảm số lượng',
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                        icon: const Icon(Icons.remove, size: 16),
                        color: const Color(0xFF475569),
                      ),
                      Semantics(
                        identifier: 'text_customize_qty',
                        label: 'Số lượng',
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
                        tooltip: 'Tăng số lượng',
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
                                'Đã thêm $_quantity x ${widget.menuItem.name} vào giỏ',
                              ),
                              backgroundColor: const Color(0xFFFF521B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          'Thêm vào giỏ • ${_formatCurrency(_totalPrice)}',
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
                _buildBottomNavItem(Icons.explore_outlined, 'Khám phá', true),
                _buildBottomNavItem(
                  Icons.restaurant_outlined,
                  'Đặt món',
                  false,
                ),
                _buildBottomNavItem(
                  Icons.receipt_long_rounded,
                  'Thanh toán',
                  false,
                ),
                _buildBottomNavItem(Icons.history_rounded, 'Lịch sử', false),
                _buildBottomNavItem(
                  Icons.person_outline_rounded,
                  'Tài khoản',
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
            // 1. Ảnh bìa Hero của món ăn kèm nhãn
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
                          '🔥 Bán chạy nhất Ca Trưa',
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
                          'Chuẩn Vị Sài Gòn',
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
                          '📍 KTX Khu B • Chốt lúc 10:45 Trưa nay',
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

            // 2. Tiêu đề món & Mô tả
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
                        '${widget.storeName} • KTX Khu B (Cổng 2)',
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
                          '-16% Trợ giá KTX',
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
                    widget.menuItem.description ?? 'Phần cơm tấm sườn que nướng than hoa mật ong thơm lừng, bì riềng trộn thính vàng óng, chả trứng hấp béo bùi, kèm mỡ hành tóp mỡ giòn và đồ chua nhà làm tươi ngon.',
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
                            'Hộp bã mía giữ nhiệt tự hủy, đóng gói nắp kín và tăm mè diệt khuẩn cho sinh viên.',
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

            // 3. Danh sách các nhóm tùy biến (Figma 4 nhóm)
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
                                ? 'Bắt buộc • Chọn 1'
                                : 'Tùy chọn • Tối đa 5',
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
                                      : (opt.name.contains('Mặc định')
                                            ? 'Mặc định'
                                            : '+0đ'),
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
                                      : 'Miễn phí',
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

            // 4. Ghi chú cho Quán Cô Ba & 5 Quick Chips
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
                          'Ghi chú cho Quán Cô Ba',
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
                      'Quán luôn cố gắng chuẩn bị theo đúng yêu cầu của bạn sinh viên.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Đồ chua để riêng, cho xin thêm muỗng nĩa dùng 1 lần, cơm sấy khô ráo...',
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

            // 5. Khung xanh cam kết giao chặn ca trưa KTX
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
                            'Cam kết Giao Chặn Ca Trưa KTX',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Đơn hàng được quán nướng nóng trước giờ giao 15 phút. Xe gom KTX tập kết tại Cổng KTX Khu B đúng 11:30.',
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
