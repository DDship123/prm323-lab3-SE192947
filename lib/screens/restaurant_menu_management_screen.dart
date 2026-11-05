import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/menu_item_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/owner_vm.dart';
import '../widgets/ktx_app_bar.dart';
import 'restaurant_edit_item_screen.dart';

class RestaurantMenuManagementScreen extends StatefulWidget {
  final String ownerId;

  const RestaurantMenuManagementScreen({super.key, required this.ownerId});

  @override
  State<RestaurantMenuManagementScreen> createState() => _RestaurantMenuManagementScreenState();
}

class _RestaurantMenuManagementScreenState extends State<RestaurantMenuManagementScreen> {
  final StoreService _storeService = StoreService();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  List<MenuItemModel> _menuItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    try {
      final items = await _storeService.fetchMenuItems(1);
      setState(() {
        _menuItems = items;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerVm = context.watch<OwnerViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: 'Quản lý Thực đơn & Món ăn',
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadMenu,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm món mới', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const RestaurantEditItemScreen(storeId: 1),
            ),
          );
          if (res == true) {
            _loadMenu();
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 64, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('Chưa có món ăn nào trong thực đơn', style: AppTypography.heading3),
                      const SizedBox(height: 6),
                      Text('Hãy nhấn nút "+ Thêm món mới" bên dưới để tạo món cho quán!', style: AppTypography.bodySmall),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _menuItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (ctx, i) {
                    final item = _menuItems[i];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedMd,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        borderRadius: AppRadius.roundedMd,
                        onTap: () async {
                          final res = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestaurantEditItemScreen(item: item, storeId: 1),
                            ),
                          );
                          if (res == true) {
                            _loadMenu();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: AppRadius.roundedSm,
                                child: Image.network(
                                  item.imageUrl ?? '',
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(Icons.fastfood, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: AppTypography.heading3),
                                    const SizedBox(height: 4),
                                    Text(
                                      currencyFormatter.format(item.basePrice),
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.primaryDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.isAvailable ? 'Đang phục vụ' : 'Hết món',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: item.isAvailable ? AppColors.success : AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Chỉnh sửa món',
                                icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 20),
                                onPressed: () async {
                                  final res = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantEditItemScreen(item: item, storeId: 1),
                                    ),
                                  );
                                  if (res == true) {
                                    _loadMenu();
                                  }
                                },
                              ),
                              Switch(
                                value: item.isAvailable,
                                activeColor: AppColors.primary,
                                onChanged: (val) async {
                                  setState(() {
                                    _menuItems[i] = MenuItemModel(
                                      id: item.id,
                                      storeId: item.storeId,
                                      name: item.name,
                                      description: item.description,
                                      imageUrl: item.imageUrl,
                                      basePrice: item.basePrice,
                                      category: item.category,
                                      isAvailable: val,
                                      customizationOptions: item.customizationOptions,
                                    );
                                  });
                                  await ownerVm.toggleAvailability(
                                    menuItemId: item.id,
                                    isAvailable: val,
                                    ownerId: widget.ownerId,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
