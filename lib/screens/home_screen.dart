import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../firebase/analytics_service.dart';
import '../firebase/remote_config_service.dart';
import '../models/store_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';
import '../viewmodels/cart_checkout_vm.dart';
import '../viewmodels/home_vm.dart';
import '../viewmodels/profile_demo_vm.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_empty_state.dart';
import '../widgets/ktx_error_state.dart';
import '../widgets/ktx_loading_state.dart';
import '../widgets/screen_state.dart';
import 'store_detail_screen.dart';

/// Màn hình S1: Trang chủ & Tìm kiếm Quán ăn Gom đơn KTX (Figma Prototype Standard)
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
  final Set<int> _favoriteStoreIds = {1};

  static const _zones = [
    {'code': 'ALL', 'label': 'Tất cả', 'icon': '🔥', 'dotColor': null},
    {'code': 'KTX_KHU_B', 'label': 'KTX Khu B', 'icon': '•', 'dotColor': 0xFF10B981},
    {'code': 'KTX_KHU_A', 'label': 'KTX Khu A', 'icon': '•', 'dotColor': 0xFFF59E0B},
    {'code': 'LANG_DH', 'label': 'Làng ĐH', 'icon': '🎓', 'dotColor': null},
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

    String greetingName = 'Linh';
    try {
      final authVm = Provider.of<AuthViewModel>(context, listen: false);
      if (authVm.currentUser != null && authVm.currentUser!.displayName.isNotEmpty) {
        greetingName = authVm.currentUser!.displayName.split(' ').last;
      }
    } catch (_) {}

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
            // 1. Lời chào người dùng chuẩn Figma
            _buildGreetingBar(greetingName),
            const SizedBox(height: AppSpacing.sm + 2),

            // 2. Thanh tìm kiếm & lọc quán
            _buildSearchBar(homeVm),
            const SizedBox(height: AppSpacing.md),

            // 3. Banner Ca gom trưa đếm ngược
            if (remoteConfig.promoBannerEnabled)
              _buildBatchCard(remoteConfig.promoBannerText),
            const SizedBox(height: AppSpacing.md),

            // 4. Dải chip chọn phân khu KTX
            _buildZoneChips(homeVm),
            const SizedBox(height: AppSpacing.lg),

            // 5. Lưới 6 danh mục Món ngon sinh viên (Figma Grid 2x3)
            _buildCategorySection(homeVm),
            const SizedBox(height: AppSpacing.lg),

            // 6. Tiêu đề Quán quen được yêu thích
            _buildSectionHeader(),
            const SizedBox(height: AppSpacing.sm),

            // 7. Danh sách thẻ quán ăn dạng dọc chuẩn Figma
            _buildStoreList(homeVm),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingBar(String userName) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KTX Food Ship',
              style: TextStyle(
                color: Color(0xFFFF521B),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Chào $userName! Trưa nay ăn gì?',
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4EC),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Color(0xFFFF521B),
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildZoneChips(HomeViewModel homeVm) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _zones.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, idx) {
          final zone = _zones[idx];
          final selected = homeVm.selectedCampusZone == zone['code'];
          final dotColorVal = zone['dotColor'] as int?;

          return InkWell(
            onTap: () => homeVm.selectCampusZone(zone['code'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFF521B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF521B).withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (zone['icon'] != null && dotColorVal == null) ...[
                    Text(
                      zone['icon'] as String,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                  ] else if (dotColorVal != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Color(dotColorVal),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    zone['label'] as String,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF334155),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(HomeViewModel homeVm) {
    final categories = [
      {
        'name': 'Cơm trưa',
        'subtitle': 'Từ 25k',
        'icon': Icons.lunch_dining_rounded,
        'bgColor': const Color(0xFFFFF7ED),
        'iconColor': const Color(0xFFEA580C),
      },
      {
        'name': 'Bún phở',
        'subtitle': 'Nóng hổi',
        'icon': Icons.ramen_dining_rounded,
        'bgColor': const Color(0xFFFEF3C7),
        'iconColor': const Color(0xFFD97706),
      },
      {
        'name': 'Trà sữa',
        'subtitle': 'Ưu đãi',
        'icon': Icons.local_cafe_rounded,
        'bgColor': const Color(0xFFFDF2F8),
        'iconColor': const Color(0xFFDB2777),
      },
      {
        'name': 'Ăn vặt',
        'subtitle': 'Bánh tráng...',
        'icon': Icons.fastfood_rounded,
        'bgColor': const Color(0xFFFEF9C3),
        'iconColor': const Color(0xFFCA8A04),
      },
      {
        'name': 'Bánh mì',
        'subtitle': 'Giao nhanh',
        'icon': Icons.bakery_dining_rounded,
        'bgColor': const Color(0xFFFFE4E6),
        'iconColor': const Color(0xFFE11D48),
      },
      {
        'name': 'Nước ép',
        'subtitle': 'Healthy',
        'icon': Icons.local_bar_rounded,
        'bgColor': const Color(0xFFECFDF5),
        'iconColor': const Color(0xFF059669),
      },
    ];

    Widget buildCatCard(Map<String, dynamic> cat) {
      return InkWell(
        onTap: () => homeVm.searchStores(cat['name'] as String),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
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
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cat['bgColor'] as Color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  cat['icon'] as IconData,
                  color: cat['iconColor'] as Color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      cat['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF521B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'MÓN NGON SINH VIÊN',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => homeVm.searchStores(''),
              child: const Text(
                'Xem tất cả (12)',
                style: TextStyle(
                  color: Color(0xFFFF521B),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: buildCatCard(categories[0])),
            const SizedBox(width: 8),
            Expanded(child: buildCatCard(categories[1])),
            const SizedBox(width: 8),
            Expanded(child: buildCatCard(categories[2])),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: buildCatCard(categories[3])),
            const SizedBox(width: 8),
            Expanded(child: buildCatCard(categories[4])),
            const SizedBox(width: 8),
            Expanded(child: buildCatCard(categories[5])),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                SizedBox(width: 6),
                Text(
                  'Quán quen được yêu thích',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Sinh viên KTX đặt nhiều nhất tuần này',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Khu vực KTX',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(
                Icons.report_problem_outlined,
                size: 18,
                color: AppColors.error,
              ),
              tooltip: 'Khiếu nại S8',
              onPressed: widget.onOpenDispute,
            ),
          ],
        ),
      ],
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
              .map((store) => _buildStoreCard(store, context))
              .toList(),
        ),
    };
  }

  Widget _buildStoreCard(StoreModel store, BuildContext context) {
    final isFav = _favoriteStoreIds.contains(store.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openStoreDetail(store),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ảnh lớn tràn viền trên + Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 145,
                    width: double.infinity,
                    child: store.avatarUrl != null &&
                            store.avatarUrl!.isNotEmpty
                        ? Image.network(
                            store.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildStorePlaceholder(),
                          )
                        : _buildStorePlaceholder(),
                  ),
                ),

                // Badges góc trên bên trái
                Positioned(
                  top: 8,
                  left: 8,
                  child: Wrap(
                    spacing: 6,
                    children: store.promoBadges.map((badge) {
                      final isGreen = badge.contains('Freeship');
                      final isPink = badge.contains('Mua 2');
                      final bgColor = isGreen
                          ? const Color(0xFF059669)
                          : (isPink
                              ? const Color(0xFFE11D48)
                              : const Color(0xFFFF521B));
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Badge góc dưới bên phải (Chốt giờ / Giao tới)
                if (store.overlayInfo.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        store.overlayInfo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Nội dung chi tiết
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên quán + Nút tim yêu thích
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isFav) {
                              _favoriteStoreIds.remove(store.id);
                            } else {
                              _favoriteStoreIds.add(store.id);
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Đánh giá sao + Số review + Khoảng cách/Thời gian
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 3),
                      Text(
                        '${store.ratingAvg}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const Text(' • ',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12)),
                      Text(
                        '${store.ratingCount}+ đánh giá',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const Text(' • ',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12)),
                      Expanded(
                        child: Text(
                          store.distanceOrTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Mức giá sinh viên + Nút Chọn món +
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.priceSubtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            store.priceRange,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF521B),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => _openStoreDetail(store),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4EC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFD8BF)),
                          ),
                          child: const Text(
                            'Chọn món +',
                            style: TextStyle(
                              color: Color(0xFFFF521B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        color: Color(0xFFFF521B),
        size: 38,
      ),
    );
  }

  void _openStoreDetail(StoreModel store) {
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
  }
}
