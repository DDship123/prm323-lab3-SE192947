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
  bool _isUploadingImage = false;
  Uint8List? _pickedImageBytes;
  bool _showManualUrlInput = false;

  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool get isCreateMode => widget.item == null;

  static const List<Map<String, String>> _sampleDishImages = [
    {
      'label': '🍛 Cơm tấm',
      'url': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
    },
    {
      'label': '🍜 Bún / Phở',
      'url': 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600',
    },
    {
      'label': '🍗 Gà xối mỡ',
      'url': 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=600',
    },
    {
      'label': '🧋 Trà sữa',
      'url': 'https://images.unsplash.com/photo-1558857563-b37cf5288219?w=600',
    },
    {
      'label': '🍑 Trà đào',
      'url': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=600',
    },
    {
      'label': '🍟 Ăn vặt',
      'url': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=600',
    },
  ];

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _isUploadingImage = true;
      });

      final uploadService = EvidenceUploadService();
      final uploadedUrl = await uploadService.uploadMenuItemImage(
        bytes: bytes,
        fileName: picked.name,
      );

      if (mounted) {
        setState(() {
          _imageUrlController.text = uploadedUrl;
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tải ảnh món ăn lên Cloudinary thành công!'),
            backgroundColor: Color(0xFF059669),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải ảnh: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _selectPresetImage(String url, String label) {
    setState(() {
      _pickedImageBytes = null;
      _imageUrlController.text = url;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn ảnh mẫu: $label'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

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
                  _buildImagePickerSection(),
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

  Widget _buildImagePickerSection() {
    final currentUrl = _imageUrlController.text.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFFFF521B)),
                  SizedBox(width: 6),
                  Text(
                    'Hình ảnh món ăn (*)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showManualUrlInput = !_showManualUrlInput),
                child: Text(
                  _showManualUrlInput ? 'Ẩn link URL' : '🔗 Dán link URL',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFF521B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Khung xem trước ảnh
          Center(
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isUploadingImage
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFFF521B)),
                            SizedBox(height: 10),
                            Text('Đang tải ảnh lên Cloud...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      )
                    : _pickedImageBytes != null
                        ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: double.infinity)
                        : currentUrl.isNotEmpty
                            ? Image.network(
                                currentUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, size: 36, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('Không thể tải ảnh từ URL', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 4),
                                    Text('Chưa chọn ảnh món ăn', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút bấm tải ảnh từ thiết bị
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF521B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isUploadingImage ? null : _pickAndUploadImage,
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text(
                'Tải ảnh từ máy tính / Điện thoại lên Cloudinary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách ảnh mẫu KTX gợi ý
          const Text(
            'Hoặc chọn nhanh ảnh món mẫu KTX:',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _sampleDishImages.map((sample) {
              final isSelected = currentUrl == sample['url'];
              return InkWell(
                onTap: () => _selectPresetImage(sample['url']!, sample['label']!),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF521B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    sample['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Ô nhập link URL thủ công nếu cần
          if (_showManualUrlInput) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'Đường dẫn ảnh trực tiếp (URL)',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link_rounded),
                isDense: true,
              ),
              onChanged: (_) => setState(() => _pickedImageBytes = null),
            ),
          ],
        ],
      ),
    );
  }

}
