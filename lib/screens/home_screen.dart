import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/store_model.dart';
import '../theme/app_colors.dart';
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
import '../widgets/screen_state.dart';
import 'store_detail_screen.dart';

/// Màn hình S1: Trang chủ & Tìm kiếm Quán ăn Gom đơn KTX
class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenCheckout;
  final VoidCallback onOpenDispute;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onSwitchRole;

  const HomeScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onOpenCheckout,
    required this.onOpenDispute,
    this.onOpenProfile,
    this.onSwitchRole,
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
        subtitle: 'GIAO ĐẾN',
        title: homeVm.selectedPickupLocation,
        unreadNotificationCount:
            homeVm.unreadNotificationCount + demoVm.unreadCount,
        onLocationTap: () => _showPickupSelector(homeVm, cartVm),
        onNotificationTap: widget.onOpenNotifications,
        cartItemCount: cartVm.totalItemCount,
        onCartTap: widget.onOpenCheckout,
        onAvatarTap: widget.onOpenProfile ?? widget.onSwitchRole,
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
            _buildSearchBar(homeVm),
            const SizedBox(height: AppSpacing.md),
            if (remoteConfig.promoBannerEnabled)
              _buildBatchCard(remoteConfig.promoBannerText),
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

  Widget _buildSearchBar(HomeViewModel homeVm) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (term) {
                homeVm.searchStores(term);
                context.read<AnalyticsService>().logSearch(
                      searchTerm: term.isEmpty ? 'ALL' : term,
                      campusZone: homeVm.selectedCampusZone,
                      resultCount: 3,
                    );
              },
              decoration: InputDecoration(
                hintText: 'Tìm món ngon, cơm, bún, trà sữa...',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                  tooltip: 'Tìm kiếm bằng giọng nói',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tìm kiếm giọng nói đang được kết nối.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4EC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD8BF),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            tooltip: 'Lọc quán ăn',
            onPressed: () {
              final term = _searchCtrl.text;
              homeVm.searchStores(term);
              context.read<AnalyticsService>().logSearch(
                    searchTerm: term.isEmpty ? 'ALL' : term,
                    campusZone: homeVm.selectedCampusZone,
                    resultCount: 3,
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(String bannerText) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF521B), Color(0xFFFF6D3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Ca gom + Badge đang mở
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ca Trưa (11:30 - 12:00)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ĐANG MỞ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Body: Thời gian đếm ngược & Hạn chốt gom
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian gom còn lại',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTimeBox('00', 'GIỜ'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            ':',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildTimeBox('28', 'PHÚT'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          child: Text(
                            ':',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildTimeBox('45', 'GIÂY'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.25),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Hạn chốt gom',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Chốt lúc 10:45',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Trưa nay',
                        style: TextStyle(
                          color: Color(0xFF7C2D12),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer: Số đơn đã gom & nút xem chi tiết
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '42',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.white, fontSize: 13),
                  children: [
                    TextSpan(text: 'Đã gom '),
                    TextSpan(
                      text: '42 đơn',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' Khu B'),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  if (bannerText.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(bannerText),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String val, String unit) {
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF9A2C00).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              height: 1.1,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              fontSize: 8,
              height: 1.1,
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
