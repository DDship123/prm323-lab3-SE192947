import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/store_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../viewmodels/home_vm.dart';
import '../viewmodels/profile_demo_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_food_item_card.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/ktx_text_field.dart';
import '../widgets/screen_state.dart';
import 'store_detail_screen.dart';

/// Màn hình S1: Trang chủ & Tìm kiếm Quán ăn Gom đơn KTX
class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenCheckout;
  final VoidCallback onOpenDispute;

  const HomeScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onOpenCheckout,
    required this.onOpenDispute,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();

  static const _zones = [
    {'code': 'ALL', 'label': 'Tất cả KTX'},
    {'code': 'KTX_KHU_B', 'label': 'KTX Khu B'},
    {'code': 'KTX_KHU_A', 'label': 'KTX Khu A'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadHomeData();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showPickupSelector(HomeViewModel homeVm, CartCheckoutViewModel cartVm) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chọn điểm giao nhận chuẩn KTX',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: AppSpacing.sm),
              ...HomeViewModel.ktxPickupLocations.map(
                (loc) => ListTile(
                  leading: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                  ),
                  title: Text(loc, style: AppTypography.bodyMedium),
                  trailing: homeVm.selectedPickupLocation == loc
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    homeVm.selectPickupLocation(loc);
                    cartVm.setPickupLocation(loc);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final cartVm = context.watch<CartCheckoutViewModel>();
    final demoVm = context.watch<ProfileDemoViewModel>();
    final remoteConfig = context.watch<RemoteConfigService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        variant: KtxAppBarVariant.homeHeader,
        subtitle: 'Điểm nhận gom đơn KTX',
        title: homeVm.selectedPickupLocation,
        unreadNotificationCount:
            homeVm.unreadNotificationCount + demoVm.unreadCount,
        onLocationTap: () => _showPickupSelector(homeVm, cartVm),
        onNotificationTap: widget.onOpenNotifications,
        actions: [
          IconButton(
            onPressed: widget.onOpenCheckout,
            tooltip: 'Giỏ hàng gom đơn',
            icon: Badge(
              isLabelVisible: cartVm.totalItemCount > 0,
              label: Text('${cartVm.totalItemCount}'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            homeVm.loadHomeData(),
            context.read<RemoteConfigService>().fetchAndActivate(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (remoteConfig.promoBannerEnabled)
              _buildPromoBanner(remoteConfig.promoBannerText),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: KtxTextField(
                    label: 'Tìm món ăn hoặc tên quán KTX',
                    hintText: 'Nhập "Cơm tấm", "Bún bò"...',
                    controller: _searchCtrl,
                    prefixIcon: Icons.search_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedMd,
                        ),
                      ),
                      onPressed: () {
                        final term = _searchCtrl.text;
                        homeVm.searchStores(term);
                        context.read<AnalyticsService>().logSearch(
                              searchTerm: term.isEmpty ? 'ALL' : term,
                              campusZone: homeVm.selectedCampusZone,
                              resultCount: 3,
                            );
                      },
                      child: const Text('Tìm'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _zones.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, idx) {
                  final zone = _zones[idx];
                  final selected = homeVm.selectedCampusZone == zone['code'];
                  return ChoiceChip(
                    label: Text(zone['label']!),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => homeVm.selectCampusZone(zone['code']!),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quán ăn Gom đơn KTX',
                  style: AppTypography.heading2,
                ),
                TextButton.icon(
                  onPressed: widget.onOpenDispute,
                  icon: const Icon(
                    Icons.report_problem_outlined,
                    size: 18,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Khiếu nại S8',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStoreList(homeVm),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(String bannerText) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: AppRadius.roundedMd,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gom đơn Ca Trưa 11:30 & Ca Chiều 18:00',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bannerText,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList(HomeViewModel homeVm) {
    final state = homeVm.storesState;
    return switch (state) {
      StateInitial() || StateLoading() => const KtxLoadingState(itemCount: 3),
      StateError(:final errorMessage) => KtxErrorState(
          message: errorMessage,
          onRetry: homeVm.loadHomeData,
        ),
      StateEmpty(:final message) => KtxEmptyState(
          title: 'Không tìm thấy quán ăn',
          message: message,
          actionLabel: 'Xem tất cả quán',
          onAction: () {
            _searchCtrl.clear();
            homeVm.searchStores('');
          },
        ),
      StateSuccess(:final data) => Column(
          children: data
              .map(
                (StoreModel store) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
                  child: KtxFoodItemCard(
                    title: store.name,
                    subtitle: '${store.address}\n${store.description ?? ''}',
                    price: 0,
                    imageUrl: store.avatarUrl,
                    isAvailable: store.isActive,
                    badgeText: store.campusZoneLabel,
                    rating: store.ratingAvg,
                    ratingCount: store.ratingCount,
                    onTap: () {
                      context.read<AnalyticsService>().logViewStoreDetail(
                            storeId: store.id,
                            storeCategory: store.campusZoneLabel,
                            ratingAvg: store.ratingAvg,
                          );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StoreDetailScreen(
                            store: store,
                            onOpenCheckout: widget.onOpenCheckout,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
              .toList(),
        ),
    };
  }
}
