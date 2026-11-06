import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import 'dispute_history_screen.dart';

/// Màn hình S8: Khiếu Nại & Hoàn Tiền KTX chuẩn 100% Figma
class DisputeRefundScreen extends StatefulWidget {
  final OrderSummaryModel? initialOrder;
  final int? orderId;

  const DisputeRefundScreen({
    super.key,
    this.initialOrder,
    this.orderId,
  });

  @override
  State<DisputeRefundScreen> createState() => _DisputeRefundScreenState();
}

class _DisputeRefundScreenState extends State<DisputeRefundScreen> {
  int _selectedReasonIndex = 0; // 0: Thiếu món hoặc thiếu topping
  final Set<int> _selectedDishIndices = {1}; // Món 1: Trà đào 10.000đ được chọn mặc định
  int _refundMethodIndex = 0; // 0: Ví KTX Food, 1: Bank
  final TextEditingController _descCtrl = TextEditingController(
    text:
        'Lúc nhận tại bàn 2 mình chỉ có 1 hộp cơm sườn, kiểm tra lại không thấy ly trà đào kèm ống hút. Bác tài xế gom thì bảo quán chỉ đưa 1 hộp...',
  );

  bool _hasEvidenceImage = true;

  final List<Map<String, String>> _reasons = [
    {
      'title': 'Thiếu món hoặc thiếu topping',
      'desc': 'Quán quên không bỏ đủ món hoặc topping vào suất',
    },
    {
      'title': 'Đồ ăn bị nghiêng đổ / Hư hỏng',
      'desc': 'Đồ tràn hộp khi vận chuyển gom tại cổng KTX',
    },
    {
      'title': 'Món ăn sai mô tả / Sai ghi chú',
      'desc': 'Không làm theo yêu cầu: cay, mỡ hành, nước mắm riêng',
    },
    {
      'title': 'Chất lượng không đảm bảo',
      'desc': 'Nguội ngắt, ôi chua, mùi lạ hoặc có dị vật',
    },
    {
      'title': 'Không bàn giao / Giao nhầm đơn',
      'desc': 'Tài xế gom báo đã giao nhưng bàn số 2 không có đơn',
    },
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}đ';
  }

  double get _calculatedRefundAmount {
    double total = 0;
    if (_selectedDishIndices.contains(0)) total += 35000;
    if (_selectedDishIndices.contains(1)) total += 10000;
    return total;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _hasEvidenceImage = true);
    }
  }

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Đã gửi yêu cầu khiếu nại thành công! Trưởng bàn gom KTX sẽ xử lý trong 30 phút.',
        ),
        backgroundColor: Color(0xFF059669),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DisputeHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Khiếu Nại & Hoàn Tiền',
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
          // 1. Banner xanh mint Bảo vệ quyền lợi Sinh viên ĐHQG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Bảo vệ quyền lợi Sinh viên ĐHQG',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF047857),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Bảo đảm 100%',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hỗ trợ đối soát nhanh • Đảm bảo bữa ăn trọn vẹn',
                        style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Card Đơn hàng gặp sự cố (#KTX-8829B)
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
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Mã đơn hàng ',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          TextSpan(
                            text: '#KTX-8829B',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF521B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Ca Trưa 11:30 – 12:00',
                        style: TextStyle(
                          color: Color(0xFFFF521B),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quán Cơm Tấm Cô Ba – ĐHQG',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Đã nhận 11:42',
                        style: TextStyle(color: Color(0xFF059669), fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '📍 Bàn số 2 – Cổng KTX Khu B',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                _buildOrderDishRow('1x Cơm Tấm Sườn Bì Chả Đặc Biệt', '35.000đ'),
                _buildOrderDishRow('1x Trà Đào Cam Sả Tươi (500ml)', '10.000đ'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng đã thanh toán (VietQR)',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '45.000đ',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF521B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Section: BẠN ĐANG GẶP SỰ CỐ GÌ? *
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'BẠN ĐANG GẶP SỰ CỐ GÌ? ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    TextSpan(
                      text: '*',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                    ),
                  ],
                ),
              ),
              const Text('Chọn 1 lý do', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn đúng lý do để điều phối viên KTX xử lý nhanh vào ca nhận',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          // 5 Radio Options
          ...List.generate(_reasons.length, (idx) {
            final isSelected = _selectedReasonIndex == idx;
            final r = _reasons[idx];
            return InkWell(
              onTap: () => setState(() => _selectedReasonIndex = idx),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFFBF9) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r['title']!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFFFF521B), size: 16),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r['desc']!,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // 4. Section: MÓN ĂN BỊ ẢNH HƯỞNG
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MÓN ĂN BỊ ẢNH HƯỞNG',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    if (_selectedDishIndices.length == 2) {
                      _selectedDishIndices.clear();
                    } else {
                      _selectedDishIndices.addAll([0, 1]);
                    }
                  });
                },
                child: const Text(
                  'Chọn tất cả',
                  style: TextStyle(fontSize: 11, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Tích chọn món bị thiếu hoặc hỏng để tính tiền hoàn:',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          // Checkbox Món 1: Cơm Tấm Sườn Bì Chả Đặc Biệt
          _buildDishCheckboxCard(
            index: 0,
            name: 'Cơm Tấm Sườn Bì Chả Đặc Biệt',
            price: '35.000đ',
            subtitle: 'Phần ăn chính (hộp nguyên vẹn)',
            warningText: null,
          ),
          const SizedBox(height: 8),

          // Checkbox Món 2: Trà Đào Cam Sả Tươi (500ml)
          _buildDishCheckboxCard(
            index: 1,
            name: 'Trà Đào Cam Sả Tươi (500ml)',
            price: '10.000đ',
            subtitle: null,
            warningText: 'Quán quên bỏ vào túi giao gom tại cổng',
          ),
          const SizedBox(height: 10),

          // Box Số tiền đề xuất hoàn tự động
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Số tiền đề xuất hoàn tự động:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tỷ lệ hoàn tiền: 100% giá trị món thiếu',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(_calculatedRefundAmount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFF521B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Section: BẰNG CHỨNG & GHI CHÚ
          const Text(
            'BẰNG CHỨNG & GHI CHÚ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          const Text(
            'Ảnh chụp rõ tem niêm phong và món giao, quyết hoàn tiền sau 15–30 phút',
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),

          const Text(
            'Mô tả sự cố bạn gặp phải:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập chi tiết sự cố bạn gặp phải...',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 12),

          const Text(
            'Hình ảnh thực tế tại KTX (Tối đa 3 ảnh):',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 8),

          // 2 Khung ảnh: 1 ảnh đã tải lên và 1 nút chụp thêm
          Row(
            children: [
              if (_hasEvidenceImage)
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '✓ Hợp lệ',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => setState(() => _hasEvidenceImage = false),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              if (_hasEvidenceImage) const SizedBox(width: 10),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 110,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 24, color: Color(0xFFFF521B)),
                      SizedBox(height: 4),
                      Text(
                        'Chụp thêm ảnh',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      Text(
                        'Tối đa 3/3',
                        style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Khung vàng nhắc nhở tem niêm phong nhiệt
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inventory_2_outlined, color: Color(0xFFD97706), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bao bì giao gom của KTX Food luôn có tem niêm phong nhiệt. Chụp rõ mã nếu đơn để tràn màng ép món với sinh viên cùng bàn.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Section: PHƯƠNG THỨC NHẬN TIỀN HOÀN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PHƯƠNG THỨC NHẬN TIỀN HOÀN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '✓ Miễn phí',
                  style: TextStyle(color: Color(0xFF059669), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Option 1: Ví KTX Food
          InkWell(
            onTap: () => setState(() => _refundMethodIndex = 0),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _refundMethodIndex == 0 ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _refundMethodIndex == 0 ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  width: _refundMethodIndex == 0 ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _refundMethodIndex == 0 ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _refundMethodIndex == 0 ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ví KTX Food / Xu Sinh Viên',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Nhanh nhất • Vào ví',
                          style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 26, top: 2),
                    child: Text(
                      'Cộng trực tiếp vào ví để dùng ngay khi gửi yêu cầu duyệt.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    margin: const EdgeInsets.only(left: 26),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFEDD5)),
                    ),
                    child: const Text(
                      'Tặng thêm voucher KTX: +5.000đ đơn ca kế tiếp',
                      style: TextStyle(fontSize: 10, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Option 2: Tài khoản ngân hàng
          InkWell(
            onTap: () => setState(() => _refundMethodIndex = 1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _refundMethodIndex == 1 ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _refundMethodIndex == 1 ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  width: _refundMethodIndex == 1 ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _refundMethodIndex == 1 ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _refundMethodIndex == 1 ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Chuyển về tài khoản ngân hàng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                      const Spacer(),
                      const Text(
                        '1 – 2 giờ',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 26, top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngân hàng thụ hưởng: MB Bank (Quân Đội)', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                        Text('Số tài khoản: **** **** 8829', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                        Text('Chủ tài khoản: LÊ THÙY LINH', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        SizedBox(height: 2),
                        Text('* Hệ thống tự động đồng bộ theo tài khoản sinh viên liên kết KTX App', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 7. Commitment Card: Cam kết xử lý trong 30 phút
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Cam kết xử lý trong 30 phút',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quán Cơm Tấm Cô Ba và Điều Phối Viên Bàn Gom KTX Khu B sẽ trực tiếp xem lại camera soạn đơn và giải quyết thỏa đáng.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFFFF521B)),
                    SizedBox(width: 4),
                    Text(
                      'Trưởng bàn gom KTX Khu B: ',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '1900 68xx (Trực ca 11:30 – 19:00)',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 8. Nút cam Gửi Yêu Cầu Khiếu Nại & Hoàn Tiền
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
              onPressed: _handleSubmit,
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text(
                'Gửi Yêu Cầu Khiếu Nại & Hoàn Tiền',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hệ thống sẽ tạm giữ tiền món trên của quán và giải ngân phần xác nhận trong vài phút.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOrderDishRow(String name, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
          Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildDishCheckboxCard({
    required int index,
    required String name,
    required String price,
    String? subtitle,
    String? warningText,
  }) {
    final isChecked = _selectedDishIndices.contains(index);
    return InkWell(
      onTap: () {
        setState(() {
          if (isChecked) {
            _selectedDishIndices.remove(index);
          } else {
            _selectedDishIndices.add(index);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFFFFFBF9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
            width: isChecked ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: isChecked ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isChecked ? const Color(0xFFFF521B) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 2),
                child: Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ),
            if (warningText != null)
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFFF521B)),
                      const SizedBox(width: 4),
                      Text(
                        warningText,
                        style: const TextStyle(fontSize: 10, color: Color(0xFFFF521B), fontWeight: FontWeight.w600),
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

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(Icons.explore_outlined, 'Khám phá', false),
          _buildBottomNavItem(Icons.restaurant_outlined, 'Đặt món', false),
          _buildBottomNavItem(Icons.receipt_long_rounded, 'Thanh toán', false),
          _buildBottomNavItem(Icons.access_time_rounded, 'Lịch sử', true),
          _buildBottomNavItem(Icons.person_outline_rounded, 'Tài khoản', false),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
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
