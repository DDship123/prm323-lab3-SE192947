import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../viewmodels/review_vm.dart';
import 'review_success_screen.dart';

/// Màn hình S9: Đánh Giá & Phản Hồi bữa ăn KTX chuẩn 100% Figma
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
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (_evidencePhotos.length < 3) {
          _evidencePhotos.add(picked.path);
        }
      });
    }
  }

  Future<void> _handleSubmitReview(ReviewViewModel vm) async {
    final ok = await vm.submitOrderReview(widget.order.id);
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
          onPressed: () => Navigator.of(context).maybePop(),
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
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: Color(0xFF1E293B)),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF521B),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1E293B)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
              ),
              backgroundColor: Colors.grey.shade200,
            ),
          ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Bắt buộc',
                        style: TextStyle(color: Color(0xFFE11D48), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 5 Sao vàng
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final star = idx + 1;
                      return IconButton(
                        onPressed: () => setState(() => _storeRating = star),
                        icon: Icon(
                          star <= _storeRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 34,
                        ),
                      );
                    }),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRatingText(_storeRating),
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

                // CHI TIẾT NHẬN XÉT (0/300)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CHI TIẾT NHẬN XÉT',
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
                    hintText: 'Chia sẻ cảm nhận về hương vị, độ tươi ngon và nhiệt độ món ăn nhé sinh viên ơi...',
                    hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),

                // ẢNH MINH CHỨNG MÓN ĂN
                const Text(
                  'ẢNH MINH CHỨNG MÓN ĂN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
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
                    const SizedBox(width: 8),
                    _buildPhotoPlaceholder('[Ảnh 1]'),
                    const SizedBox(width: 8),
                    _buildPhotoPlaceholder('[Ảnh 2]'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Section 02: Đánh giá Người Giao Hàng
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
                    const Text(
                      'SH – 042',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tài xế row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFFDBEAFE),
                      child: const Text('AVT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Nguyễn Văn Minh',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                          ],
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Đội xe Gom KTX B • Chuyến 11:30 - 12:00',
                          style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5 Sao vàng người giao hàng
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (idx) {
                      final star = idx + 1;
                      return IconButton(
                        onPressed: () => setState(() => _shipperRating = star),
                        icon: Icon(
                          star <= _shipperRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 30,
                        ),
                      );
                    }),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Đúng giờ & Thân thiện',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
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
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'Gửi Đánh Giá & Nhận 50 Điểm KTX',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildPhotoPlaceholder(String label) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, size: 20, color: Color(0xFF94A3B8)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(icon: Icons.home_outlined, label: 'Khám phá', isActive: false),
          _BottomNavItem(icon: Icons.shopping_bag_outlined, label: 'Đặt món', isActive: false),
          _BottomNavItem(icon: Icons.receipt_long_outlined, label: 'Thanh toán', isActive: false),
          _BottomNavItem(icon: Icons.access_time_rounded, label: 'Lịch sử', isActive: true),
          _BottomNavItem(icon: Icons.person_outline_rounded, label: 'Tài khoản', isActive: false),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
