import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/store_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../viewmodels/store_detail_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/ktx_sticky_cart_bar.dart';
import '../widgets/screen_state.dart';
import 'cart_screen.dart';
import 'food_customization_sheet.dart';
import 'group_cart_checkout_screen.dart';
import 'live_order_tracking_screen.dart';

/// Màn hình S2: Chi tiết Quán ăn & Thực đơn Đặt món Sinh viên chuẩn Figma
class StoreDetailScreen extends StatefulWidget {
  final StoreModel store;
  final VoidCallback onOpenCheckout;

  const StoreDetailScreen({
    super.key,
    required this.store,
    required this.onOpenCheckout,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  bool _isFavorite = false;

  static const Map<String, String> _categoryLabels = {
    'COM': 'Cơm',
    'BUN_PHO': 'Bún / Phở',
    'DO_UONG': 'Đồ uống',
    'NUOC': 'Đồ uống',
    'AN_VAT': 'Ăn vặt',
    'TOPPING': 'Món thêm',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreDetailViewModel>().loadStoreDetail(widget.store);
    });
  }

  void _openFoodSheet(MenuItemModel item, StoreModel store) {
    FoodCustomizationSheet.show(
      context,
      storeId: store.id,
      storeName: store.name,
      menuItem: item,
    );
  }

  void _navigateToCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CartScreen(
          onProceedToCheckout: _navigateToCheckout,
          onExploreMenu: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _navigateToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupCartCheckoutScreen(
          onBackToMenu: () => Navigator.of(context).pop(),
          onOrderCompleted: (OrderDetailModel order) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => LiveOrderTrackingScreen(initialOrder: order),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeVm = context.watch<StoreDetailViewModel>();
    final cartVm = context.watch<CartCheckoutViewModel>();
    final activeStore = storeVm.store ?? widget.store;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E293B),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                activeStore.name,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: 'Chia sẻ quán ăn',
                  icon: const Icon(
                    Icons.share_outlined,
                    color: Color(0xFF1E293B),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép liên kết quán ăn!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            )
          : KtxAppBar(
              variant: KtxAppBarVariant.homeHeader,
              subtitle: 'GIAO ĐẾN',
              title: activeStore.campusZoneLabel,
              cartItemCount: cartVm.totalItemCount,
              onCartTap: _navigateToCart,
            ),
      bottomNavigationBar: cartVm.totalItemCount > 0
          ? KtxStickyCartBar(
              itemCount: cartVm.totalItemCount,
              totalAmount: cartVm.subtotalAmount,
              pickupLocation: activeStore.campusZoneLabel,
              onCheckoutTap: _navigateToCart,
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildStoreBanner(activeStore, storeVm, canPop),
          ),
          SliverToBoxAdapter(child: _buildCategorySelector(storeVm)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: _buildMenuSliver(storeVm, activeStore, cartVm),
          ),
          SliverToBoxAdapter(child: _buildReviewsSection(storeVm)),

        ],
      ),
    );
  }

  Widget _buildStoreBanner(
    StoreModel store,
    StoreDetailViewModel vm,
    bool canPop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ảnh bìa Hero của Quán + Các nút Overlays
        Stack(
          children: [
            SizedBox(
              height: 175,
              width: double.infinity,
              child: store.avatarUrl != null && store.avatarUrl!.isNotEmpty
                  ? Image.network(
                      store.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildHeroPlaceholder(),
                    )
                  : _buildHeroPlaceholder(),
            ),

            // Nút Back, Heart, Share trên ảnh
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (canPop)
                    Semantics(
                      button: true,
                      label: 'Quay lại',
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      Semantics(
                        identifier: 'btn_store_favorite',
                        button: true,
                        toggled: _isFavorite,
                        label: _isFavorite
                            ? 'Bỏ yêu thích quán'
                            : 'Yêu thích quán',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _isFavorite = !_isFavorite;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _isFavorite
                                  ? const Color(0xFFEF4444)
                                  : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        button: true,
                        label: 'Chia sẻ quán ăn',
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép liên kết quán ăn!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Nhãn địa điểm và khoảng cách góc dưới ảnh
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      store.campusZone == 'KTX_KHU_A'
                          ? 'KTX Khu A (Sảnh A3)'
                          : 'KTX Khu B (Cổng 2)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Cách 600m',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
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

        // 2. Thông tin quán: Tên, tích xanh, freeship, giờ
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF0284C7),
                        size: 18,
                      ),
                    ],
                  ),
                  const Text(
                    'Cổng KTX',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${store.campusZoneLabel} • ĐHQG',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    store.ratingAvg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFF059669),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Freeship',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '11:30',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Thẻ Ca gom đơn đếm ngược
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang nhận đơn Ca Trưa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Giao 11:30 Cổng B',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '24:59',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'CHỐT ĐƠN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 4. Bảng tin Cô Ba hôm nay
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.campaign_rounded,
                color: Color(0xFFFF521B),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BẢNG TIN CÔ BA HÔM NAY',
                      style: TextStyle(
                        color: Color(0xFFFF521B),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Tặng trà đá cho nhóm từ 3 phần',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildHeroPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFFFF521B),
        size: 50,
      ),
    );
  }

  Widget _buildCategorySelector(StoreDetailViewModel vm) {
    final state = vm.menuState;
    final allItems = (state is StateSuccess<List<MenuItemModel>>) ? state.data : <MenuItemModel>[];

    // Tạo danh sách danh mục ĐỘNG từ các món thực tế của quán
    final dynamicCategories = <Map<String, String>>[
      {'code': 'ALL', 'label': 'Tất cả'},
    ];

    final presentCategories = <String>{};
    for (final item in allItems) {
      final rawCat = item.category.trim().toUpperCase();
      if (rawCat.isNotEmpty && !presentCategories.contains(rawCat)) {
        presentCategories.add(rawCat);
      }
    }

    for (final cat in presentCategories) {
      final label = _categoryLabels[cat] ?? cat;
      dynamicCategories.add({'code': cat, 'label': label});
    }

    return SizedBox(
      height: 44,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: dynamicCategories.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (_, index) {
            final cat = dynamicCategories[index];
            final isSelected = vm.selectedCategory == cat['code'];
            return ChoiceChip(
              label: Text(cat['label']!),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => vm.selectCategory(cat['code']!),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuSliver(
    StoreDetailViewModel vm,
    StoreModel store,
    CartCheckoutViewModel cartVm,
  ) {
    final state = vm.menuState;
    return switch (state) {
      StateInitial() || StateLoading() => const SliverToBoxAdapter(
        child: KtxLoadingState(itemCount: 3),
      ),
      StateError(:final errorMessage) => SliverToBoxAdapter(
        child: KtxErrorState(
          message: errorMessage,
          onRetry: () => vm.loadStoreDetail(store),
        ),
      ),
      StateEmpty(:final message) => SliverToBoxAdapter(
        child: KtxEmptyState(title: 'Chưa có món ăn', message: message),
      ),
      StateSuccess() =>
        vm.filteredMenuItems.isEmpty
            ? const SliverToBoxAdapter(
                child: KtxEmptyState(
                  title: 'Danh mục trống',
                  message: 'Chưa có món ăn nào trong danh mục này.',
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate((context, idx) {
                  final item = vm.filteredMenuItems[idx];
                  final isFirstTopping =
                      item.category == 'TOPPING' &&
                      (idx == 0 ||
                          vm.filteredMenuItems[idx - 1].category != 'TOPPING');

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isFirstTopping) ...[
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Topping & Món Canh Thêm',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'Tiết kiệm gom chung',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      _buildFoodItemCard(
                        item: item,
                        store: store,
                        cartVm: cartVm,
                      ),
                    ],
                  );
                }, childCount: vm.filteredMenuItems.length),
              ),
    };
  }

  Widget _buildFoodItemCard({
    required MenuItemModel item,
    required StoreModel store,
    required CartCheckoutViewModel cartVm,
  }) {
    final cartItems = cartVm.items
        .where((i) => i.menuItemId == item.id)
        .toList();
    final totalQty = cartItems.fold(0, (sum, i) => sum + i.quantity);
    final hasCustomization = item.customizationOptions.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ảnh món vuông bo góc 12px + Badge (Best Seller, Cay nhẹ)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildItemPlaceholder(),
                        )
                      : _buildItemPlaceholder(),
                ),
              ),
              if (item.promoBadge != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.promoBadge == 'Best Seller'
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFFF521B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.promoBadge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Tên món + Giá (kèm giá gạch nếu có)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(item.basePrice)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFFFF521B),
                      ),
                    ),
                    if (item.originalPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${NumberFormat('#,###', 'vi_VN').format(item.originalPrice)}đ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nút hành động: [Tùy biến] hoặc [- 1 +] hoặc [+]
          if (hasCustomization && totalQty == 0)
            Semantics(
              identifier: 'btn_customize_item_${item.id}',
              button: true,
              label: 'Tùy biến ${item.name}',
              excludeSemantics: true,
              onTap: () => _openFoodSheet(item, store),
              child: InkWell(
                onTap: () => _openFoodSheet(item, store),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        size: 14,
                        color: Color(0xFF475569),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Tùy biến',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (totalQty > 0)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    identifier: 'btn_decrease_item_${item.id}',
                    button: true,
                    label: 'Giảm số lượng ${item.name}',
                    child: InkWell(
                      onTap: () {
                        final idx = cartVm.items.indexWhere(
                          (i) => i.menuItemId == item.id,
                        );
                        if (idx != -1) cartVm.updateQuantity(idx, -1);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 14,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Semantics(
                      identifier: 'text_qty_item_${item.id}',
                      label: 'Số lượng ${item.name} trong giỏ',
                      child: Text(
                        '$totalQty',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    identifier: 'btn_increase_item_${item.id}',
                    button: true,
                    label: 'Tăng số lượng ${item.name}',
                    child: InkWell(
                      onTap: () {
                        if (hasCustomization) {
                          _openFoodSheet(item, store);
                        } else {
                          final idx = cartVm.items.indexWhere(
                            (i) => i.menuItemId == item.id,
                          );
                          if (idx != -1) {
                            cartVm.updateQuantity(idx, 1);
                          } else {
                            cartVm.addItemToCart(
                              storeId: store.id,
                              storeName: store.name,
                              menuItem: item,
                              quantity: 1,
                              selectedOptions: [],
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 14,
                          color: Color(0xFFFF521B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Semantics(
              identifier: 'btn_add_item_${item.id}',
              button: true,
              label: 'Thêm ${item.name} vào giỏ',
              child: InkWell(
                onTap: () {
                  if (hasCustomization) {
                    _openFoodSheet(item, store);
                  } else {
                    cartVm.addItemToCart(
                      storeId: store.id,
                      storeName: store.name,
                      menuItem: item,
                      quantity: 1,
                      selectedOptions: [],
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4EC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFD8BF)),
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFFFF521B),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        color: Color(0xFFFF521B),
        size: 26,
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const Text('Không thể tải ảnh'),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(StoreDetailViewModel vm) {
    final reviews = vm.reviews;
    final totalRating = reviews.fold<double>(0.0, (acc, r) => acc + r.storeRating);
    final double avgRating = reviews.isNotEmpty
        ? (totalRating / reviews.length)
        : (widget.store.ratingAvg > 0 ? widget.store.ratingAvg : 5.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đánh giá từ sinh viên KTX ()',
                style: AppTypography.heading3,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB45309)),
                    ),
                    Text(
                      ' / 5.0',
                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '★ Đánh giá trung bình:  sao (Tổng điểm cộng lại chia đều cho  lượt đánh giá)',
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.divider),
              ),
              child: const Center(
                child: Text(
                  'Chưa có đánh giá nào cho quán này. Hãy là người đầu tiên đặt món và đánh giá nhé!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...reviews.take(10).map((rev) {
              final timeStr = DateFormat('dd/MM/yyyy • HH:mm').format(rev.createdAt);
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFFFECE5),
                          backgroundImage: rev.userAvatarUrl != null && rev.userAvatarUrl!.isNotEmpty
                              ? NetworkImage(rev.userAvatarUrl!)
                              : null,
                          child: rev.userAvatarUrl == null || rev.userAvatarUrl!.isEmpty
                              ? Text(
                                  rev.userDisplayName.isNotEmpty ? rev.userDisplayName[0].toUpperCase() : 'S',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF521B), fontSize: 13),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rev.userDisplayName,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rev.storeRating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (rev.comment != null && rev.comment!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        rev.comment!,
                        style: AppTypography.bodySmall.copyWith(color: const Color(0xFF334155), height: 1.35),
                      ),
                    ],
                    if (rev.images.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: rev.images.map((imgUrl) {
                          return InkWell(
                            onTap: () => _showImageDialog(context, imgUrl),
                            borderRadius: BorderRadius.circular(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imgUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.broken_image, size: 20, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}