import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/menu_item_model.dart';
import '../services/evidence_upload_service.dart';
import '../services/store_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../services/commission_policy_service.dart';
import '../theme/app_typography.dart';
import '../widgets/ktx_app_bar.dart';
import '../widgets/ktx_button.dart';

class RestaurantEditItemScreen extends StatefulWidget {
  final MenuItemModel? item;
  final int storeId;

  const RestaurantEditItemScreen({
    super.key,
    this.item,
    this.storeId = 1,
  });

  @override
  State<RestaurantEditItemScreen> createState() => _RestaurantEditItemScreenState();
}

class _RestaurantEditItemScreenState extends State<RestaurantEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _imageUrlController;
  late bool _isAvailable;
  String _selectedCategory = 'COM';
  bool _isSaving = false;

  // Quản lý ảnh món ăn (Tải từ máy lên hoặc chụp trực tiếp)
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  bool _isUploadingImage = false;
  double _uploadProgress = 0.0;
  final ImagePicker _picker = ImagePicker();

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool get isCreateMode => widget.item == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(text: widget.item != null ? widget.item!.basePrice.toStringAsFixed(0) : '35000');
    _descController = TextEditingController(text: widget.item?.description ?? '');
    _imageUrlController = TextEditingController(
      text: widget.item?.imageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
    );
    _isAvailable = widget.item?.isAvailable ?? true;
    _selectedCategory = widget.item?.category ?? 'COM';
    CommissionPolicyService().loadCommissionRate().then((_) {
      if (mounted) setState(() {});
    });
    _priceController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isUploadingImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đợi ảnh tải lên hoàn tất trước khi lưu!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text.trim()) ?? 35000.0;
      final desc = _descController.text.trim();
      final img = _imageUrlController.text.trim().isNotEmpty
          ? _imageUrlController.text.trim()
          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c';

      final service = StoreService();
      if (isCreateMode) {
        await service.createMenuItem(
          storeId: widget.storeId,
          name: name,
          basePrice: price,
          category: _selectedCategory,
          description: desc,
          imageUrl: img,
        );
      } else {
        await service.updateMenuItem(
          id: widget.item!.id,
          name: name,
          basePrice: price,
          category: _selectedCategory,
          description: desc,
          imageUrl: img,
          isAvailable: _isAvailable,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCreateMode ? 'Đã thêm món "$name" vào thực đơn quán thành công!' : 'Đã cập nhật món ăn thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa món'),
        content: Text('Bạn có chắc chắn muốn xóa "${widget.item?.name}" khỏi thực đơn không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa món', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      try {
        final success = await StoreService().deleteMenuItem(widget.item!.id);
        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã xóa món ăn thành công!'), backgroundColor: AppColors.success),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không thể xóa món ăn, vui lòng thử lại!'), backgroundColor: AppColors.error),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = file.name;
        _isUploadingImage = true;
        _uploadProgress = 0.2;
      });

      try {
        final uploadService = EvidenceUploadService();
        final downloadUrl = await uploadService.uploadEvidence(
          bytes: bytes,
          fileName: file.name,
          userId: 'store_${widget.storeId}',
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
        if (mounted) {
          setState(() {
            _imageUrlController.text = downloadUrl;
            _isUploadingImage = false;
            _uploadProgress = 1.0;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã tải ảnh món ăn lên Cloud thành công!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
            if (_imageUrlController.text.isEmpty) {
              _imageUrlController.text =
                  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chọn ảnh món ăn thành công!'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final isWebPluginError = e.toString().contains('pickImage') ||
            e.toString().contains('undefined') ||
            e.toString().contains('TypeError');
        if (isWebPluginError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '💡 Web Chrome cần khởi động lại (flutter run -d chrome) để nạp plugin camera/file. Đang mở ảnh mẫu KTX...',
              ),
              backgroundColor: Color(0xFFEA580C),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
          _showPresetPhotosDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể chọn ảnh: $e'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showPresetPhotosDialog() {
    final presets = [
      {
        'title': 'Cơm tấm sườn bì chả đặc biệt',
        'url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c',
      },
      {
        'title': 'Bánh mì chảo xíu mại trứng lòng đào',
        'url': 'https://images.unsplash.com/photo-1509722747041-616f39b57569',
      },
      {
        'title': 'Bún bò Huế O Phượng đặc biệt',
        'url': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43',
      },
      {
        'title': 'Trà sữa trân châu Ba Anh Em',
        'url': 'https://images.unsplash.com/photo-1558857563-b37cf2cb7a77',
      },
      {
        'title': 'Gà rán & khoai lắc giòn rụm',
        'url': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec',
      },
      {
        'title': 'Mì Quảng tôm thịt trứng cút',
        'url': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.collections_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('Chọn Ảnh Món Mẫu KTX', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn một trong các ảnh món ăn chất lượng cao chuẩn bị sẵn:',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: presets.length,
                  separatorBuilder: (_, _) => const Divider(height: 8),
                  itemBuilder: (_, idx) {
                    final item = presets[idx];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          item['url']!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, size: 20),
                          ),
                        ),
                      ),
                      title: Text(item['title']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                      onTap: () {
                        setState(() {
                          _pickedImageBytes = null;
                          _pickedImageName = item['title'];
                          _imageUrlController.text = item['url']!;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã chọn: ${item['title']}'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KtxAppBar(
        title: isCreateMode ? 'Thêm Món Mới KTX' : 'Chỉnh sửa Món & Topping',
        actions: [
          if (!isCreateMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Xóa món',
              onPressed: _isSaving ? null : _handleDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Thông tin món ăn', style: AppTypography.heading2),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên món ăn (*)',
                      hintText: 'VD: Cơm sườn nướng đặc biệt',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.restaurant),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Tên món không được để trống' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giá bán cơ bản (VNĐ) (*)',
                            hintText: '35000',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Giá bán không được để trống' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Danh mục',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'COM', child: Text('Cơm')),
                            DropdownMenuItem(value: 'BUN_PHO', child: Text('Bún / Phở')),
                            DropdownMenuItem(value: 'DO_UONG', child: Text('Đồ uống')),
                            DropdownMenuItem(value: 'AN_VAT', child: Text('Ăn vặt')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  _buildCommissionCalculationBox(),
                  const SizedBox(height: AppSpacing.md),
                  _buildImageSelectorSection(),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả món ăn',
                      hintText: 'Nguyên liệu, hương vị đặc trưng...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Còn món phục vụ hôm nay', style: AppTypography.bodyMedium),
                      Switch(
                        value: _isAvailable,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isAvailable = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Topping section
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tùy chọn Topping KTX', style: AppTypography.heading2),
                      const Chip(
                        label: Text('Mặc định', style: TextStyle(fontSize: 11)),
                        backgroundColor: AppColors.surfaceVariant,
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildToppingTile('Trứng ốp la lòng đào', 6000, true),
                  _buildToppingTile('Chả trứng hấp thịt', 8000, true),
                  _buildToppingTile('Thêm tóp mỡ giòn', 3000, true),
                  _buildToppingTile('Canh chua thịt bằm', 5000, true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            KtxButton(
              label: isCreateMode ? 'Thêm món vào thực đơn' : 'Lưu thay đổi món',
              isLoading: _isSaving,
              onPressed: _handleSave,
            ),
            if (!isCreateMode) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _handleDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                label: const Text('Xóa món ăn này', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToppingTile(String name, double price, bool available) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name, style: AppTypography.bodyMedium),
      subtitle: Text(
        '+${currencyFormatter.format(price)}',
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
      ),
      trailing: Chip(
        label: Text(
          available ? 'Còn Topping' : 'Hết Topping',
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.successLight,
      ),
    ),
    );
  }

  Widget _buildCommissionCalculationBox() {
    final policy = CommissionPolicyService();
    final rate = policy.commissionRate;
    final storeRate = policy.storePayoutRate;
    final rawPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final platformFee = policy.calculatePlatformFee(rawPrice);
    final netPayout = policy.calculateNetPayout(rawPrice);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Dự toán Thực nhận của Quán',
                    style: AppTypography.heading3.copyWith(fontSize: 13, color: AppColors.primaryDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Chiết khấu sàn: ${rate.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá niêm yết cho Sinh viên:', style: AppTypography.bodySmall),
              Text(currencyFormatter.format(rawPrice), style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Phí sàn KTX Food (${rate.toStringAsFixed(0)}% theo Admin):', style: AppTypography.bodySmall),
              Text('-${currencyFormatter.format(platformFee)}', style: AppTypography.bodySmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 18, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    '💵 Quán thực nhận (${storeRate.toStringAsFixed(0)}%):',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Text(
                currencyFormatter.format(netPayout),
                style: AppTypography.heading3.copyWith(color: AppColors.success, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '* Tỷ lệ chiết khấu ${rate.toStringAsFixed(0)}% được thiết lập tập trung bởi Ban Quản Lý KTX.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectorSection() {
    final hasImage = _pickedImageBytes != null || _imageUrlController.text.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Ảnh minh họa món ăn (*)',
                    style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (hasImage)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: AppRadius.roundedSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Đã có ảnh',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Khung xem trước ảnh (Preview)
          if (hasImage) ...[
            ClipRRect(
              borderRadius: AppRadius.roundedMd,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _pickedImageBytes != null
                        ? Image.memory(
                            _pickedImageBytes!,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.fastfood, size: 48, color: Colors.grey),
                              ),
                            ),
                          ),
                  ),
                  // Nút xóa ảnh hiện tại
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _pickedImageBytes = null;
                            _pickedImageName = null;
                            _imageUrlController.clear();
                          });
                        },
                        tooltip: 'Xóa ảnh đã chọn',
                      ),
                    ),
                  ),
                  if (_pickedImageName != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tệp: $_pickedImageName',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            // Placeholder khi chưa có ảnh
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.textHint),
                  const SizedBox(height: 6),
                  Text(
                    'Chưa có ảnh món ăn',
                    style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chọn ảnh sắc nét từ máy hoặc chụp trực tiếp qua Camera',
                    style: AppTypography.caption.copyWith(color: AppColors.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Thanh tiến trình tải ảnh lên Cloud
          if (_isUploadingImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _uploadProgress > 0 ? _uploadProgress : null,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Đang tải ảnh lên Cloud Storage (${(_uploadProgress * 100).toInt()}%)...',
              style: AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Hai nút thao tác: Tải ảnh từ máy & Chụp trực tiếp
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Tải ảnh từ máy lên'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                  ),
                  onPressed: _isUploadingImage ? null : () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Chụp trực tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedSm),
                  ),
                  onPressed: _isUploadingImage ? null : () => _pickImage(ImageSource.camera),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.collections_outlined, size: 16, color: AppColors.textSecondary),
              label: const Text(
                'Hoặc chọn nhanh từ kho ảnh món mẫu KTX',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              onPressed: _showPresetPhotosDialog,
            ),
          ),
        ],
      ),
    );
  }

}
