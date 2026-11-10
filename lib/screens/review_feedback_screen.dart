import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/order_model.dart';
import '../viewmodels/auth_vm.dart';
import '../viewmodels/review_vm.dart';
import '../services/evidence_upload_service.dart';
import '../widgets/ktx_bottom_nav_bar.dart';
import 'review_success_screen.dart';

/// Màn hình S9: Đánh Giá & Phản Hồi bữa ăn KTX chuẩn 100% Figma
/// Hỗ trợ vuốt chọn 1-5 sao, cmt và ảnh (tối đa 3 ảnh) không ràng buộc
class ReviewFeedbackScreen extends StatefulWidget {
  final OrderDetailModel order;

  const ReviewFeedbackScreen({
    super.key,
    required this.order,
  });

  @override
  State<ReviewFeedbackScreen> createState() => _ReviewFeedbackScreenState();
}

class _ReviewFeedbackScreenState extends State<ReviewFeedbackScreen> {
  int _storeRating = 5;
  int _shipperRating = 5;
  final Set<String> _selectedStoreTags = {'Đồ ăn nóng sốt', 'Đóng gói cẩn thận'};
  final Set<String> _selectedShipperTags = {'Đến cổng đúng hẹn'};
  final TextEditingController _commentCtrl = TextEditingController();
  final TextEditingController _shipperCommentCtrl = TextEditingController();
  bool _isAnonymous = true;
  final List<String> _evidencePhotos = [];

  static const _storeTags = [
    'Đồ ăn nóng sốt',
    'Đóng gói cẩn thận',
    'Đúng ghi chú',
    'Khẩu phần đầy đặn',
  ];

  static const _shipperTags = [
    'Đến cổng đúng hẹn',
    'Nhiệt tình, lễ phép',
    'Bảo quản thức ăn tốt',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewViewModel>().resetForm();
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _shipperCommentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_evidencePhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chỉ có thể đính kèm tối đa 3 hình ảnh minh chứng!')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF521B)),
              title: const Text('Chọn từ Thư viện ảnh'),
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (ctx.mounted) Navigator.pop(ctx, img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF521B)),
              title: const Text('Chụp ảnh mới bằng Camera'),
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (ctx.mounted) Navigator.pop(ctx, img);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      String photoUrl = picked.path;
      try {
        final bytes = await picked.readAsBytes();
        final uploadService = EvidenceUploadService();
        final cloudUrl = await uploadService.uploadEvidence(
          bytes: bytes,
          fileName: 'review__.jpg',
          userId: 'student_',
        );
        if (cloudUrl.isNotEmpty) {
          photoUrl = cloudUrl;
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (_evidencePhotos.length < 3) {
            _evidencePhotos.add(photoUrl);
          }
        });
      }
    }
  }

  void _navigateToTab(int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => AuthGate(initialStudentTabIndex: index),
      ),
      (route) => false,
    );
  }

  void _removePhoto(int index) {
    if (index >= 0 && index < _evidencePhotos.length) {
      setState(() {
        _evidencePhotos.removeAt(index);
      });
    }
  }

  Future<void> _handleSubmitReview(ReviewViewModel vm) async {
    vm.setStoreRating(_storeRating);
    vm.setShipperRating(_shipperRating);
    vm.setComment(_commentCtrl.text);
    vm.setShipperComment(_shipperCommentCtrl.text);
    vm.clearImages();
    for (final img in _evidencePhotos) {
      vm.addImage(img);
    }

    final authVm = context.read<AuthViewModel>();
    final user = authVm.currentUser;

    final ok = await vm.submitOrderReview(
      widget.order.id,
      storeName: widget.order.storeName.isNotEmpty ? widget.order.storeName : 'Cơm Tấm Cô Ba - KTX Khu B',
      shipperName: widget.order.shipperName ?? 'Nguyễn Hùng (Shipper Đội Gom KTX)',
      userDisplayName: _isAnonymous
          ? 'Sinh viên ẩn danh (KTX)'
          : (user?.displayName ?? 'Ngô Trường Đạt (Sinh viên)'),
      userAvatarUrl: _isAnonymous ? null : user?.avatarUrl,
      storeId: widget.order.storeId,
      shipperId: widget.order.shipperId ?? 3,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewSuccessScreen(order: widget.order),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi đánh giá thành công! Bạn nhận được +50 Điểm KTX.'),
          backgroundColor: Color(0xFF059669),
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  /// Widget cho phép vừa Chạm vừa Vuốt (Swipe / Drag) để chọn từ 1 đến 5 sao
  Widget _buildSwipeableStarRating({
    required int rating,
    required ValueChanged<int> onChanged,
    double starSize = 38,
    Color activeColor = const Color(0xFFF59E0B),
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = (starSize * 5) + (10 * 4);

        void handlePosition(Offset localPosition) {
          final dx = localPosition.dx.clamp(0.0, totalWidth);
          final star = ((dx / totalWidth) * 5).ceil().clamp(1, 5);
          if (star != rating) {
            onChanged(star);
          }
        }

        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => handlePosition(details.localPosition),
            onHorizontalDragUpdate: (details) => handlePosition(details.localPosition),
            child: SizedBox(
              width: totalWidth,
              height: starSize + 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (idx) {
                  final starNum = idx + 1;
                  final isFilled = starNum <= rating;
                  return Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFilled ? activeColor : const Color(0xFFCBD5E1),
                    size: starSize,
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewViewModel>();
    final orderCode = widget.order.orderCode.isNotEmpty
        ? widget.order.orderCode
        : '#KTX-8829B';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              _navigateToTab(3);
            }
          },
        ),
        title: const Text(
          'Đánh Giá & Phản Hồi',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _navigateToTab(0),
            child: const Text(
              'Để sau',
              style: TextStyle(
                color: Color(0xFFFF521B),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Thẻ tóm tắt đơn hàng
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        orderCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155)),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Text(
                          'Ca trưa • Hôm nay, 11:45',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.order.storeName.isNotEmpty
                                ? widget.order.storeName
                                : 'Cơm Tấm Cô Ba Sinh Viên',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.order.items.isNotEmpty
                                ? widget.order.items
                                    .map((i) => '${i.quantity}x ${i.itemName}')
                                    .join(', ')
                                : 'Đơn hàng tại ${widget.order.storeName}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFF521B), size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFFFF521B)),
                      const SizedBox(width: 4),
                      Text(
                        'Điểm nhận: ${widget.order.pickupLocation.isNotEmpty ? widget.order.pickupLocation : "Cổng 2 – KTX Khu B (Cột B5)"}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Section 01: Chất lượng Món & Quán
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '01',
                            style: TextStyle(color: Color(0xFFFF521B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Chất lượng Món & Quán',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.swipe_rounded, size: 13, color: Color(0xFF64748B)),
                        SizedBox(width: 3),
                        Text(
                          'Vuốt để chọn',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5 Sao vàng vuốt để chọn
                _buildSwipeableStarRating(
                  rating: _storeRating,
                  onChanged: (val) => setState(() => _storeRating = val),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_storeRating sao • ${_getRatingText(_storeRating)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ĐẶC ĐIỂM NỔI BẬT (CHỌN NHANH)
                const Text(
                  'ĐẶC ĐIỂM NỔI BẬT (CHỌN NHANH)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _storeTags.map((tag) {
                    final isSelected = _selectedStoreTags.contains(tag);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedStoreTags.remove(tag);
                          } else {
                            _selectedStoreTags.add(tag);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          isSelected ? '✓ $tag' : '+ $tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFFF521B) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // CHI TIẾT NHẬN XÉT (Không bắt buộc)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CHI TIẾT NHẬN XÉT (TÙY CHỌN)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    Text(
                      '${_commentCtrl.text.length}/300',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  maxLength: 300,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Cảm nhận về hương vị, độ tươi ngon và nhiệt độ món ăn nhé sinh viên ơi...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),

                // ẢNH MINH CHỨNG MÓN ĂN (Tối đa 3 ảnh)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ẢNH MINH CHỨNG MÓN ĂN',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                    ),
                    Text(
                      '${_evidencePhotos.length}/3 ảnh (Tùy chọn)',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_evidencePhotos.length < 3)
                        InkWell(
                          onTap: _pickPhoto,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFCCBC), style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFFFF521B)),
                                SizedBox(height: 4),
                                Text('+ Thêm ảnh', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF521B))),
                              ],
                            ),
                          ),
                        ),
                      if (_evidencePhotos.length < 3) const SizedBox(width: 8),
                      ..._evidencePhotos.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final path = entry.value;
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 75,
                              height: 75,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: path.startsWith('http')
                                    ? Image.network(path, fit: BoxFit.cover)
                                    : (kIsWeb
                                        ? Image.network(path, fit: BoxFit.cover)
                                        : Image.file(File(path), fit: BoxFit.cover)),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: 4,
                              child: InkWell(
                                onTap: () => _removePhoto(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Section 02: Đánh giá Người Giao Hàng (Shipper)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '02',
                            style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Đánh giá Người Giao Hàng',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.swipe_rounded, size: 13, color: Color(0xFF64748B)),
                        SizedBox(width: 3),
                        Text(
                          'Vuốt để chọn',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tài xế row
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(0xFFDBEAFE),
                      backgroundImage: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100'),
                      child: Icon(Icons.person, color: Color(0xFF1D4ED8), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.order.shipperName ?? 'Nguyễn Hùng',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                            ],
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Đội xe Gom KTX B • Chuyến 11:30 - 12:00',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5 Sao vàng người giao hàng vuốt để chọn
                _buildSwipeableStarRating(
                  rating: _shipperRating,
                  onChanged: (val) => setState(() => _shipperRating = val),
                  activeColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_shipperRating sao • ${_getRatingText(_shipperRating)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // PHẢN HỒI DỊCH VỤ GIAO HÀNG
                const Text(
                  'PHẢN HỒI DỊCH VỤ GIAO HÀNG',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _shipperTags.map((tag) {
                    final isSelected = _selectedShipperTags.contains(tag);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedShipperTags.remove(tag);
                          } else {
                            _selectedShipperTags.add(tag);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF7ED) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          isSelected ? '✓ $tag' : '+ $tag',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFFF521B) : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Nhận xét shipper tùy chọn
                TextField(
                  controller: _shipperCommentCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Nhận xét thêm về thái độ, thời gian giao hàng của Shipper (tùy chọn)...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Toggle Đánh giá ẩn danh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security_rounded, size: 18, color: Color(0xFF475569)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đánh giá ẩn danh',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        'Ẩn tên tài khoản và số phòng KTX với người bán',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAnonymous,
                  activeTrackColor: const Color(0xFFFFCCBC),
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? const Color(0xFFFF521B)
                        : null,
                  ),
                  onChanged: (val) => setState(() => _isAnonymous = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 5. Card Điểm thưởng KTX
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.card_giftcard_rounded, color: Color(0xFFD97706), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bạn sẽ nhận được +50 Điểm KTX (tương đương giảm 5.000đ cho đơn ca tối kế tiếp).',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Nút cam Gửi Đánh Giá & Nhận 50 Điểm KTX
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF521B),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: vm.isSubmitting ? null : () => _handleSubmitReview(vm),
              icon: vm.isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                vm.isSubmitting ? 'Đang gửi đánh giá...' : 'Gửi Đánh Giá & Nhận 50 Điểm KTX',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              '• Hệ thống sẵn sàng ghi nhận • S-38 Rev.04',
              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Rất hài lòng';
      case 4:
        return 'Hài lòng';
      case 3:
        return 'Bình thường';
      case 2:
        return 'Chưa hài lòng';
      default:
        return 'Không hài lòng';
    }
  }

  Widget _buildBottomNavBar() {
    return KtxBottomNavBar(
      currentIndex: 3,
      onTap: _navigateToTab,
    );
  }
}
