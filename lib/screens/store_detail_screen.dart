import 'package:flutter/material.dart';
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
import '../widgets/ktx_food_item_card.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/ktx_sticky_cart_bar.dart';
import '../widgets/screen_state.dart';
import 'food_customization_sheet.dart';
import 'group_cart_checkout_screen.dart';
import 'live_order_tracking_screen.dart';

/// Màn hình S2: Chi tiết Quán ăn, Thực đơn & Đánh giá của Sinh viên
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
  static const _categories = [
    {'code': 'ALL', 'label': 'Tất cả'},
    {'code': 'COM', 'label': 'Cơm KTX'},
    {'code': 'BUN_PHO', 'label': 'Bún / Phở'},
    {'code': 'NUOC', 'label': 'Giải khát'},
  ];

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

  void _navigateToCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupCartCheckoutScreen(
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
      appBar: KtxAppBar(
        title: activeStore.name,
        subtitle: activeStore.campusZoneLabel,
        cartItemCount: cartVm.totalItemCount,
        onCartTap: _navigateToCheckout,
      ),
      bottomNavigationBar: canPop
          ? KtxStickyCartBar(
              itemCount: cartVm.totalItemCount,
              totalAmount: cartVm.subtotalAmount,
              pickupLocation: activeStore.campusZoneLabel,
              onCheckoutTap: _navigateToCheckout,
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildStoreBanner(activeStore, storeVm),
          ),
          SliverToBoxAdapter(
            child: _buildCategorySelector(storeVm),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: _buildMenuSliver(storeVm, activeStore),
          ),
          if (storeVm.reviews.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildReviewsSection(storeVm),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreBanner(StoreModel store, StoreDetailViewModel vm) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: AppRadius.roundedSm,
                ),
                child: Text(
                  store.campusZoneLabel,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(
                '${store.ratingAvg.toStringAsFixed(1)} (${store.ratingCount} đánh giá)',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(store.name, style: AppTypography.heading2),
          if (store.description != null && store.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(store.description!, style: AppTypography.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  store.address,
                  style: AppTypography.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(StoreDetailViewModel vm) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) {
          final cat = _categories[index];
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
    );
  }

  Widget _buildMenuSliver(StoreDetailViewModel vm, StoreModel store) {
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
          child: KtxEmptyState(
            title: 'Chưa có món ăn',
            message: message,
          ),
        ),
      StateSuccess() => vm.filteredMenuItems.isEmpty
          ? const SliverToBoxAdapter(
              child: KtxEmptyState(
                title: 'Danh mục trống',
                message: 'Chưa có món ăn nào trong danh mục này.',
              ),
            )
          : SliverList.separated(
              itemCount: vm.filteredMenuItems.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm + 4),
              itemBuilder: (_, idx) {
                final item = vm.filteredMenuItems[idx];
                return KtxFoodItemCard(
                  title: item.name,
                  subtitle: item.description,
                  price: item.basePrice,
                  imageUrl: item.imageUrl,
                  isAvailable: item.isAvailable,
                  onTap: () => _openFoodSheet(item, store),
                  onAddTap: () => _openFoodSheet(item, store),
                );
              },
            ),
    };
  }

  Widget _buildReviewsSection(StoreDetailViewModel vm) {
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
          Text(
            'Đánh giá từ sinh viên KTX (${vm.reviews.length})',
            style: AppTypography.heading3,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...vm.reviews.take(5).map(
                (rev) => Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            rev.userDisplayName,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
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
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(rev.comment!, style: AppTypography.bodySmall),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
