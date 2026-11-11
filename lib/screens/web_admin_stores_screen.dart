import 'package:flutter/material.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Màn hình Web Admin Quản lý Quán ăn & Đối tác KTX (Store Management)
/// Hỗ trợ kiểm duyệt quán mới, bật/tắt nhận đơn và chỉnh sửa thông tin quán
class WebAdminStoresScreen extends StatefulWidget {
  final StoreService storeService;

  const WebAdminStoresScreen({
    super.key,
    required this.storeService,
  });

  @override
  State<WebAdminStoresScreen> createState() => _WebAdminStoresScreenState();
}

class _WebAdminStoresScreenState extends State<WebAdminStoresScreen> {
  bool _isLoading = true;
  List<StoreModel> _stores = [];
  String _searchQuery = '';
  String _selectedZoneFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    try {
      // Lấy tất cả quán kể cả quán đang tạm đóng (onlyActive: false)
      final list = await widget.storeService.fetchStores(onlyActive: false);
      if (mounted) {
        setState(() {
          _stores = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _stores = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleToggleStoreActive(StoreModel store) async {
    final willActive = !store.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        title: Row(
          children: [
            Icon(
              willActive ? Icons.storefront_rounded : Icons.store_mall_directory_outlined,
              color: willActive ? AppColors.success : AppColors.error,
              size: 26,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(willActive ? 'Mở cửa nhận đơn?' : 'Tạm dừng hoạt động?'),
          ],
        ),
        content: Text(
          willActive
              ? 'Mở lại trạng thái nhận đơn cho quán "${store.name}". Sinh viên các sảnh KTX sẽ có thể tiếp tục đặt món ca trưa và chiều.'
              : 'TẠM DỪNG hoạt động quán "${store.name}". Quán sẽ không hiển thị trên danh mục đặt món của sinh viên KTX cho đến khi được mở lại.',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willActive ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willActive ? 'Mở nhận đơn' : 'Tạm ngưng quán'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storeService.toggleStoreActive(
        store: store,
        isActive: willActive,
      );

      if (mounted) {
        setState(() {
          final idx = _stores.indexWhere((s) => s.id == store.id);
          if (idx != -1) {
            _stores[idx] = StoreModel(
              id: store.id,
              name: store.name,
              address: store.address,
              campusZone: store.campusZone,
              phoneNumber: store.phoneNumber,
              description: store.description,
              avatarUrl: store.avatarUrl,
              isActive: willActive,
              ratingAvg: store.ratingAvg,
              ratingCount: store.ratingCount,
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              willActive
                  ? 'Quán "${store.name}" đã được kích hoạt nhận đơn thành công'
                  : 'Quán "${store.name}" đã tạm ngưng nhận đơn',
            ),
            backgroundColor: willActive ? AppColors.success : AppColors.textSecondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleCreateOrEditStore({StoreModel? editingStore}) async {
    final isEditing = editingStore != null;
    final nameCtrl = TextEditingController(text: editingStore?.name ?? '');
    final addressCtrl = TextEditingController(text: editingStore?.address ?? '');
    final phoneCtrl = TextEditingController(text: editingStore?.phoneNumber ?? '');
    final descCtrl = TextEditingController(text: editingStore?.description ?? '');
    final avatarCtrl = TextEditingController(text: editingStore?.avatarUrl ?? '');
    String campusZone = editingStore?.campusZone ?? 'KTX_KHU_B';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.add_business_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isEditing ? 'Sửa thông tin quán: ${editingStore.name}' : 'Thêm Quán Ăn Đối Tác Mới',
                style: AppTypography.heading3.copyWith(fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên quán ăn *',
                        hintText: 'Ví dụ: Cơm Tấm Sườn Bì Khu B',
                        prefixIcon: Icon(Icons.storefront_rounded, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên quán ăn' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ quán cụ thể *',
                        hintText: 'Ví dụ: Cổng B2 KTX ĐHQG, P. Đông Hòa, Dĩ An',
                        prefixIcon: Icon(Icons.place_rounded, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập địa chỉ quán' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: campusZone,
                            decoration: const InputDecoration(
                              labelText: 'Phân khu KTX phục vụ *',
                              prefixIcon: Icon(Icons.apartment_rounded, size: 20),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'KTX_KHU_A', child: Text('KTX Khu A')),
                              DropdownMenuItem(value: 'KTX_KHU_B', child: Text('KTX Khu B')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => campusZone = val);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Hotline / SĐT quán',
                              hintText: '0987123456',
                              prefixIcon: Icon(Icons.phone_rounded, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả ngắn về quán',
                        hintText: 'Ví dụ: Chuyên các món ăn trưa, giao nhanh tại các sảnh...',
                        prefixIcon: Icon(Icons.description_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: avatarCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Link ảnh đại diện (URL)',
                        hintText: 'https://images.unsplash.com/...',
                        prefixIcon: Icon(Icons.image_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
              ),
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(isEditing ? 'Lưu cập nhật' : 'Tạo quán mới'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        if (isEditing) {
          final updated = await widget.storeService.updateStore(
            id: editingStore.id,
            name: nameCtrl.text.trim(),
            address: addressCtrl.text.trim(),
            phoneNumber: phoneCtrl.text.trim(),
            description: descCtrl.text.trim(),
            avatarUrl: avatarCtrl.text.trim(),
            campusZone: campusZone,
            isActive: editingStore.isActive,
          );
          if (mounted) {
            setState(() {
              final idx = _stores.indexWhere((s) => s.id == editingStore.id);
              if (idx != -1 && updated != null) {
                _stores[idx] = updated;
              } else if (idx != -1) {
                _stores[idx] = StoreModel(
                  id: editingStore.id,
                  name: nameCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  avatarUrl: avatarCtrl.text.trim(),
                  campusZone: campusZone,
                  isActive: editingStore.isActive,
                  ratingAvg: editingStore.ratingAvg,
                  ratingCount: editingStore.ratingCount,
                );
              }
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã cập nhật thông tin quán thành công!'), backgroundColor: AppColors.success),
            );
          }
        } else {
          final created = await widget.storeService.createStore(
            name: nameCtrl.text.trim(),
            address: addressCtrl.text.trim(),
            campusZone: campusZone,
            phoneNumber: phoneCtrl.text.trim(),
            description: descCtrl.text.trim(),
            avatarUrl: avatarCtrl.text.trim(),
          );
          if (mounted) {
            setState(() {
              final newStore = created ??
                  StoreModel(
                    id: DateTime.now().millisecondsSinceEpoch % 10000,
                    name: nameCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    campusZone: campusZone,
                    phoneNumber: phoneCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    avatarUrl: avatarCtrl.text.trim(),
                    isActive: true,
                    ratingAvg: 5.0,
                    ratingCount: 0,
                  );
              _stores.insert(0, newStore);
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã thêm mới quán đối tác KTX thành công!'), backgroundColor: AppColors.success),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  List<StoreModel> get _filteredStores {
    return _stores.where((s) {
      if (_selectedZoneFilter != 'ALL' && s.campusZone != _selectedZoneFilter) {
        return false;
      }
      if (_selectedStatusFilter == 'ACTIVE' && !s.isActive) {
        return false;
      }
      if (_selectedStatusFilter == 'INACTIVE' && s.isActive) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = s.name.toLowerCase();
        final addr = s.address.toLowerCase();
        final phone = (s.phoneNumber ?? '').toLowerCase();
        return name.contains(q) || addr.contains(q) || phone.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredStores;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSpacing.md),
                  Text('Đang tải danh sách quán ăn KTX...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HEADER & KPI NHANH
                  _buildHeaderMetrics(),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. THANH BỘ LỌC & TÌM KIẾM
                  _buildFilterBar(),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. GRID DANH SÁCH QUÁN ĂN ĐỐI TÁC
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth > 1150) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 750) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 270,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) => _buildStoreCard(filtered[idx]),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderMetrics() {
    final total = _stores.length;
    final active = _stores.where((s) => s.isActive).length;
    final inactive = _stores.where((s) => !s.isActive).length;
    final zoneA = _stores.where((s) => s.campusZone == 'KTX_KHU_A').length;
    final zoneB = _stores.where((s) => s.campusZone == 'KTX_KHU_B').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quản Lý Quán Ăn & Đối Tác KTX', style: AppTypography.heading2),
                const SizedBox(height: 4),
                Text(
                  'Kiểm duyệt thông tin gian hàng, theo dõi trạng thái nhận đơn và đánh giá chất lượng món ăn',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  tooltip: 'Tải lại danh sách',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  onPressed: _loadStores,
                ),
                const SizedBox(width: AppSpacing.xs),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                  ),
                  onPressed: () => _handleCreateOrEditStore(),
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  label: const Text('+ Thêm Quán Mới'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth > 800 ? (constraints.maxWidth - 4 * 12) / 5 : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildMetricCard('Tổng số đối tác', '$total', Icons.store_rounded, AppColors.primary, cardWidth),
                _buildMetricCard('Đang mở bếp', '$active', Icons.check_circle_outline_rounded, AppColors.success, cardWidth),
                _buildMetricCard('Tạm đóng cửa', '$inactive', Icons.pause_circle_outline_rounded, AppColors.textSecondary, cardWidth),
                _buildMetricCard('Quán KTX Khu A', '$zoneA', Icons.place_rounded, Colors.blue, cardWidth),
                _buildMetricCard('Quán KTX Khu B', '$zoneB', Icons.pin_drop_rounded, Colors.deepOrange, cardWidth),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.roundedSm,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AppTypography.heading3.copyWith(color: color, fontSize: 18)),
                Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên quán, địa chỉ, số hotline...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedSm,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStatusFilter,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    style: AppTypography.bodySmall,
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Đang mở bếp')),
                      DropdownMenuItem(value: 'INACTIVE', child: Text('Tạm đóng cửa')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedStatusFilter = v);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildZoneFilterChip('ALL', 'Tất cả khu vực KTX'),
                _buildZoneFilterChip('KTX_KHU_A', '📍 KTX Khu A'),
                _buildZoneFilterChip('KTX_KHU_B', '📍 KTX Khu B'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneFilterChip(String zone, String label) {
    final isSelected = _selectedZoneFilter == zone;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedZoneFilter = zone),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: AppColors.surfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedFull,
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        ),
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    final isZoneA = store.campusZone == 'KTX_KHU_A';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: store.isActive ? AppColors.border : AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.roundedMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ẢNH ĐẠI DIỆN + BADGE TRẠNG THÁI & PHÂN KHU
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: (store.avatarUrl != null && store.avatarUrl!.isNotEmpty)
                      ? Image.network(
                          store.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildStorePlaceholder(),
                        )
                      : _buildStorePlaceholder(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isZoneA ? Colors.blue.shade700 : Colors.deepOrange.shade700,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Text(
                      isZoneA ? 'KTX Khu A' : 'KTX Khu B',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: store.isActive ? AppColors.success : AppColors.error,
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Text(
                      store.isActive ? 'ĐANG MỞ BẾP' : 'TẠM ĐÓNG',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // 2. NỘI DUNG CHI TIẾT QUÁN
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            store.name,
                            style: AppTypography.heading3.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              store.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.address,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (store.phoneNumber != null && store.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(store.phoneNumber!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                    const Spacer(),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => _handleCreateOrEditStore(editingStore: store),
                          icon: const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.primary),
                          label: const Text('Sửa quán', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: store.isActive ? AppColors.surfaceVariant : AppColors.success,
                            foregroundColor: store.isActive ? AppColors.error : Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                          ),
                          onPressed: () => _handleToggleStoreActive(store),
                          child: Text(
                            store.isActive ? 'Tạm ngưng' : 'Mở nhận đơn',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorePlaceholder() {
    return const Center(
      child: Icon(Icons.restaurant_rounded, size: 36, color: AppColors.textSecondary),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Không tìm thấy quán ăn đối tác phù hợp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Hãy thử thay đổi từ khóa tìm kiếm hoặc bỏ chọn bộ lọc khu vực', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedZoneFilter = 'ALL';
                _selectedStatusFilter = 'ALL';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Đặt lại bộ lọc'),
          ),
        ],
      ),
    );
  }
}
