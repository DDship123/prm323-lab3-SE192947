import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/admin_api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../viewmodels/auth_vm.dart';

/// Màn hình Web Admin Quản lý Người dùng & Phân quyền (RBAC)
/// Hỗ trợ tìm kiếm, lọc theo vai trò, đổi quyền tài khoản và Ban/Unban vi phạm
class WebAdminUsersScreen extends StatefulWidget {
  final AdminApiService adminService;

  const WebAdminUsersScreen({
    super.key,
    required this.adminService,
  });

  @override
  State<WebAdminUsersScreen> createState() => _WebAdminUsersScreenState();
}

class _WebAdminUsersScreenState extends State<WebAdminUsersScreen> {
  bool _isLoading = true;
  List<UserModel> _users = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'ALL';
  String _selectedStatusFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final authVm = context.read<AuthViewModel>();
      final adminId = authVm.currentUser?.id.toString() ?? '4';
      final list = await widget.adminService.fetchAllUsers(adminId: adminId);
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleToggleBan(UserModel user) async {
    final willBan = !user.isBanned;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
        title: Row(
          children: [
            Icon(
              willBan ? Icons.block_rounded : Icons.check_circle_rounded,
              color: willBan ? AppColors.error : AppColors.success,
              size: 26,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(willBan ? 'Khóa tài khoản?' : 'Mở khóa tài khoản?'),
          ],
        ),
        content: Text(
          willBan
              ? 'Bạn có chắc muốn KHÓA tài khoản "${user.displayName}" (ID: ${user.id})? Người dùng sẽ bị chặn đăng nhập và từ chối mọi giao dịch trên hệ thống KTX Food.'
              : 'Bạn có chắc muốn MỞ KHÓA tài khoản "${user.displayName}" (ID: ${user.id}) để người dùng tiếp tục hoạt động?',
          style: AppTypography.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willBan ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willBan ? 'Xác nhận Khóa' : 'Xác nhận Mở khóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final authVm = context.read<AuthViewModel>();
        final adminId = authVm.currentUser?.id.toString() ?? '4';
        final ok = await widget.adminService.toggleUserBan(
          userId: user.id,
          banned: willBan,
          adminId: adminId,
        );

        if (ok && mounted) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == user.id);
            if (idx != -1) {
              _users[idx] = _users[idx].copyWith(isBanned: willBan);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                willBan
                    ? 'Đã khóa tài khoản "${user.displayName}" thành công'
                    : 'Đã mở khóa tài khoản "${user.displayName}" thành công',
              ),
              backgroundColor: willBan ? AppColors.error : AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleChangeRole(UserModel user) async {
    String selectedRole = user.role;
    final roles = [
      {'code': 'STUDENT', 'name': 'Sinh viên (Student)', 'desc': 'Đặt món, gom đơn, tích điểm', 'icon': Icons.school_rounded, 'color': AppColors.primary},
      {'code': 'STORE_OWNER', 'name': 'Chủ quán ăn (Store Owner)', 'desc': 'Quản lý thực đơn, nhận ca gom', 'icon': Icons.restaurant_rounded, 'color': AppColors.success},
      {'code': 'SHIPPER', 'name': 'Người giao hàng (Shipper)', 'desc': 'Nhận chuyến, giao tới sảnh KTX', 'icon': Icons.delivery_dining_rounded, 'color': Colors.purple},
      {'code': 'ADMIN', 'name': 'Ban Quản trị (Admin)', 'desc': 'Toàn quyền kiểm soát hệ thống KTX', 'icon': Icons.admin_panel_settings_rounded, 'color': AppColors.error},
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
          title: Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Phân quyền: ${user.displayName}', style: AppTypography.heading3.copyWith(fontSize: 18)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn vai trò mới cho tài khoản ID: ${user.id} (${user.email})',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                ...roles.map((r) {
                  final code = r['code'] as String;
                  final isSelected = selectedRole == code;
                  final color = r['color'] as Color;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.08) : AppColors.surfaceVariant,
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isSelected ? color : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: RadioListTile<String>(
                      value: code,
                      groupValue: selectedRole,
                      activeColor: color,
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedRole = val);
                        }
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: AppRadius.roundedSm,
                        ),
                        child: Icon(r['icon'] as IconData, color: color, size: 20),
                      ),
                      title: Text(
                        r['name'] as String,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? color : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        r['desc'] as String,
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  );
                }),
              ],
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu thay đổi vai trò'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedRole != user.role) {
      try {
        final authVm = context.read<AuthViewModel>();
        final adminId = authVm.currentUser?.id.toString() ?? '4';
        final ok = await widget.adminService.updateUserRole(
          userId: user.id,
          role: selectedRole,
          adminId: adminId,
        );

        if (ok && mounted) {
          setState(() {
            final idx = _users.indexWhere((u) => u.id == user.id);
            if (idx != -1) {
              _users[idx] = _users[idx].copyWith(role: selectedRole);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã cập nhật vai trò của "${user.displayName}" thành $selectedRole'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((u) {
      if (_selectedRoleFilter != 'ALL' && u.role != _selectedRoleFilter) {
        return false;
      }
      if (_selectedStatusFilter == 'ACTIVE' && u.isBanned) {
        return false;
      }
      if (_selectedStatusFilter == 'BANNED' && !u.isBanned) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = u.displayName.toLowerCase();
        final email = u.email.toLowerCase();
        final phone = (u.phone ?? '').toLowerCase();
        final room = '${u.ktxBuilding ?? ""} ${u.ktxRoom ?? ""}'.toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q) || room.contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1000;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSpacing.md),
                  Text('Đang tải danh sách người dùng KTX...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TIÊU ĐỀ & THỐNG KÊ NHANH
                  _buildHeaderMetrics(screenWidth),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. THANH TÌM KIẾM & BỘ LỌC
                  _buildFilterBar(),

                  const SizedBox(height: AppSpacing.md),

                  // 3. DANH SÁCH NGƯỜI DÙNG (TABLE HOẶC CARDS)
                  if (filtered.isEmpty)
                    _buildEmptyState()
                  else if (isDesktop)
                    _buildUserTable(filtered)
                  else
                    _buildUserCardList(filtered),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderMetrics(double screenWidth) {
    final total = _users.length;
    final students = _users.where((u) => u.role == 'STUDENT').length;
    final owners = _users.where((u) => u.role == 'STORE_OWNER').length;
    final shippers = _users.where((u) => u.role == 'SHIPPER').length;
    final banned = _users.where((u) => u.isBanned).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quản Lý Người Dùng & Phân Quyền', style: AppTypography.heading2),
                const SizedBox(height: 4),
                Text(
                  'Giám sát tài khoản sinh viên, chủ quán ăn, shipper và thiết lập quyền truy cập hệ thống',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Tải lại danh sách',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              onPressed: _loadUsers,
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
                _buildMetricCard('Tổng tài khoản', '$total', Icons.groups_rounded, AppColors.primary, cardWidth),
                _buildMetricCard('Sinh viên', '$students', Icons.school_rounded, Colors.blue, cardWidth),
                _buildMetricCard('Chủ quán', '$owners', Icons.storefront_rounded, AppColors.success, cardWidth),
                _buildMetricCard('Shipper gom ca', '$shippers', Icons.delivery_dining_rounded, Colors.purple, cardWidth),
                _buildMetricCard('Tài khoản bị khóa', '$banned', Icons.block_rounded, AppColors.error, cardWidth),
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
                    hintText: 'Tìm theo Tên, Email, SĐT, Phòng KTX...',
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
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Đang hoạt động')),
                      DropdownMenuItem(value: 'BANNED', child: Text('Đang bị khóa')),
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
                _buildRoleFilterChip('ALL', 'Tất cả vai trò'),
                _buildRoleFilterChip('STUDENT', 'Sinh viên'),
                _buildRoleFilterChip('STORE_OWNER', 'Chủ quán ăn'),
                _buildRoleFilterChip('SHIPPER', 'Shipper KTX'),
                _buildRoleFilterChip('ADMIN', 'Ban Quản trị'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String role, String label) {
    final isSelected = _selectedRoleFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedRoleFilter = role),
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

  Widget _buildUserTable(List<UserModel> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.roundedMd,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: math.max(constraints.maxWidth, 950.0),
                ),
                child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceVariant),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Người dùng', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Liên hệ', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Địa chỉ KTX', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map((user) {
            return DataRow(
              cells: [
                DataCell(Text('#${user.id}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryLight,
                        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                            ? Text(
                                user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          if (user.ratingAvg != null && user.ratingAvg! > 0)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  '${user.ratingAvg!.toStringAsFixed(1)} (${user.ratingCount ?? 0})',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.email, style: const TextStyle(fontSize: 12)),
                      if (user.phone != null && user.phone!.isNotEmpty)
                        Text(user.phone!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    (user.ktxBuilding != null || user.ktxRoom != null)
                        ? '${user.ktxBuilding ?? ""} ${user.ktxRoom ?? ""}'.trim()
                        : 'Chưa cập nhật',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(_buildRoleBadge(user.role)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: user.isBanned ? AppColors.errorLight : AppColors.successLight,
                      borderRadius: AppRadius.roundedFull,
                      border: Border.all(color: user.isBanned ? AppColors.error : AppColors.success),
                    ),
                    child: Text(
                      user.isBanned ? 'ĐÃ KHÓA' : 'HOẠT ĐỘNG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: user.isBanned ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Thay đổi quyền / Role',
                        icon: const Icon(Icons.manage_accounts_rounded, size: 20, color: AppColors.primary),
                        onPressed: () => _handleChangeRole(user),
                      ),
                      IconButton(
                        tooltip: user.isBanned ? 'Mở khóa tài khoản' : 'Khóa tài khoản vi phạm',
                        icon: Icon(
                          user.isBanned ? Icons.lock_open_rounded : Icons.lock_person_rounded,
                          size: 20,
                          color: user.isBanned ? AppColors.success : AppColors.error,
                        ),
                        onPressed: () => _handleToggleBan(user),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  ),
);
},
);
}

  Widget _buildUserCardList(List<UserModel> users) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final user = users[idx];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Text(
                            user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${user.email} • ID #${user.id}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _buildRoleBadge(user.role),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phòng: ${(user.ktxBuilding != null || user.ktxRoom != null) ? "${user.ktxBuilding ?? ""} ${user.ktxRoom ?? ""}".trim() : "Chưa cập nhật"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    user.isBanned ? 'Trạng thái: ĐÃ KHÓA' : 'Trạng thái: Hoạt động',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: user.isBanned ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () => _handleChangeRole(user),
                    icon: const Icon(Icons.manage_accounts_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Đổi quyền', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: user.isBanned ? AppColors.success : AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => _handleToggleBan(user),
                    icon: Icon(user.isBanned ? Icons.lock_open_rounded : Icons.lock_person_rounded, size: 16),
                    label: Text(user.isBanned ? 'Mở khóa' : 'Khóa nick', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color fg;
    String label;

    switch (role) {
      case 'STORE_OWNER':
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = 'CHỦ QUÁN';
        break;
      case 'SHIPPER':
        bg = Colors.purple.shade50;
        fg = Colors.purple.shade700;
        label = 'SHIPPER';
        break;
      case 'ADMIN':
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = 'ADMIN';
        break;
      case 'STUDENT':
      default:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
        label = 'SINH VIÊN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedSm,
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          const Text('Không tìm thấy người dùng phù hợp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Hãy thử thay đổi từ khóa tìm kiếm hoặc bỏ chọn các bộ lọc vai trò', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedRoleFilter = 'ALL';
                _selectedStatusFilter = 'ALL';
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Đặt lại tất cả bộ lọc'),
          ),
        ],
      ),
    );
  }
}
