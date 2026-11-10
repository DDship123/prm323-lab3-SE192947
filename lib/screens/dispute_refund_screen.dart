import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import 'dispute_history_screen.dart';

/// Màn hình S8: Khiếu Nại & Hoàn Tiền KTX chuẩn 100% Figma
class DisputeRefundScreen extends StatefulWidget {
  final OrderDetailModel? order;
  final OrderSummaryModel? initialOrder;
  final int? orderId;

  const DisputeRefundScreen({
    super.key,
    this.order,
    this.initialOrder,
    this.orderId,
  });

  @override
  State<DisputeRefundScreen> createState() => _DisputeRefundScreenState();
}

class _DisputeRefundScreenState extends State<DisputeRefundScreen> {
  int _selectedReasonIndex = 0; // 0: Thiếu món / thiếu đồ
  final Set<int> _selectedDishIndices = {1}; // Món 1: Trà đào 10.000đ
  int _refundMethodIndex = 0; // 0: Ví KTX Food, 1: Bank
  final TextEditingController _descCtrl = TextEditingController(
    text:
        'Lúc nhận tại Bàn 2 mở túi chỉ có hộp cơm sườn, không thấy ly trà đào kèm ống hút. Em có hỏi tài xế thì bảo quán chỉ đưa 1 hộp.',
  );

  bool _hasEvidenceImage = true;

  @override
  void initState() {
    super.initState();
    if (widget.order != null && widget.order!.items.isNotEmpty) {
      _selectedDishIndices.clear();
      _selectedDishIndices.add(0);
      _descCtrl.text = 'Sau khi nhận hàng mở ra kiểm tra thì món ăn gặp sự cố, đề nghị hoàn tiền theo quy định KTX.';
    }
  }

  final List<Map<String, dynamic>> _reasons = [
    {
      'title': 'Thiếu món / thiếu đồ',
      'desc': 'Quán nước, thiếu canh hoặc đồ ăn kèm',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'title': 'Đồ ăn bị đổ / Hư hỏng',
      'desc': 'Tràn hộp do quá trình vận chuyển',
      'icon': Icons.delete_outline_rounded,
    },
    {
      'title': 'Món ăn sai mô tả / Sai ghi chú',
      'desc': 'Không đúng yêu cầu: cay, mặn, không ớt',
      'icon': Icons.edit_note_rounded,
    },
    {
      'title': 'Chất lượng không đảm bảo',
      'desc': 'Nguội ngắt, ôi chua, chưa chín',
      'icon': Icons.sentiment_dissatisfied_rounded,
    },
    {
      'title': 'Giao nhầm đơn / Không nhận được',
      'desc': 'Đã báo giao nhưng bàn số 2 không có',
      'icon': Icons.public_rounded,
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
    if (widget.order != null && widget.order!.items.isNotEmpty) {
      final items = widget.order!.items;
      double total = 0;
      for (final idx in _selectedDishIndices) {
        if (idx >= 0 && idx < items.length) {
          total += items[idx].subtotal;
        }
      }
      return total > 0 ? total : widget.order!.totalPrice;
    }
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
          'Đã gửi yêu cầu hoàn tiền thành công! Trưởng bàn gom KTX sẽ xử lý trong 30 phút.',
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
                  ),
                  backgroundColor: Colors.grey.shade200,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
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
                        'Xử lý nhanh bàn giao • Bù tiền thỏa đáng',
                        style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Card Đơn hàng gặp sự cố
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
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.order != null && widget.order!.orderCode.isNotEmpty
                            ? (widget.order!.orderCode.startsWith('#') ? widget.order!.orderCode : '#${widget.order!.orderCode}')
                            : '#KTX-8829B',
                        style: const TextStyle(
                          color: Color(0xFFFF521B),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      widget.order?.slotTime.isNotEmpty == true
                          ? widget.order!.slotTime
                          : 'Ca Trưa 11:30 – 12:00',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Đã nhận',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.order?.storeName.isNotEmpty == true
                      ? widget.order!.storeName
                      : 'Quán Cơm Tấm Cô Ba – ĐHQG',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.order?.pickupLocation.isNotEmpty == true
                      ? '📍 ${widget.order!.pickupLocation}'
                      : '📍 Bàn số 2 • Cổng KTX Khu B',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                if (widget.order != null && widget.order!.items.isNotEmpty)
                  ...widget.order!.items.map((i) => _buildOrderDishRow(
                        '${i.quantity}x ${i.itemName}',
                        _formatCurrency(i.subtotal),
                      ))
                else ...[
                  _buildOrderDishRow('1x Cơm Tấm Sườn Bì Chả Đặc Biệt', '35.000đ'),
                  _buildOrderDishRow('1x Trà Đào Cam Sả Tươi (500ml)', '10.000đ', isHighlighted: true),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng đã trả (${widget.order?.paymentMethod.isNotEmpty == true ? widget.order!.paymentMethod : "VietQR"}):',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      widget.order != null ? _formatCurrency(widget.order!.totalPrice) : '45.000đ',
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
                      text: '*Bắt buộc',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                    ),
                  ],
                ),
              ),
              const Text('Chọn 1 lý do', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 10),

          // 5 Radio Options với icon chuẩn Figma
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
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF7ED) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        r['icon'] as IconData,
                        size: 18,
                        color: isSelected ? const Color(0xFFFF521B) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title'] as String,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r['desc'] as String,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
                      size: 18,
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
                    final count = widget.order != null && widget.order!.items.isNotEmpty
                        ? widget.order!.items.length
                        : 2;
                    if (_selectedDishIndices.length == count) {
                      _selectedDishIndices.clear();
                    } else {
                      _selectedDishIndices.addAll(List.generate(count, (i) => i));
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
          const SizedBox(height: 10),

          if (widget.order != null && widget.order!.items.isNotEmpty)
            ...widget.order!.items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildDishCheckboxCard(
                  index: idx,
                  name: '${item.quantity}x ${item.itemName}',
                  price: _formatCurrency(item.subtotal),
                  subtitle: item.selectedOptions.isNotEmpty
                      ? item.selectedOptions.map((o) => o.choice).join(', ')
                      : null,
                  warningText: _selectedDishIndices.contains(idx) ? 'Món gặp sự cố cần hoàn tiền' : null,
                ),
              );
            })
          else ...[
            // Checkbox Món 1: Cơm Tấm Sườn Bì Chả Đặc Biệt
            _buildDishCheckboxCard(
              index: 0,
              name: 'Cơm Tấm Sườn Bì Chả Đặc Biệt',
              price: '35.000đ',
              subtitle: 'Hộp nguyên vẹn',
              warningText: null,
            ),
            const SizedBox(height: 8),

            // Checkbox Món 2: Trà Đào Cam Sả Tươi (500ml)
            _buildDishCheckboxCard(
              index: 1,
              name: 'Trà Đào Cam Sả Tươi (500ml)',
              price: '10.000đ',
              subtitle: null,
              warningText: 'Quán quên không kèm vào túi',
            ),
          ],
          const SizedBox(height: 10),

          // Box Số tiền đề xuất hoàn tự động
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
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
                      '100% giá trị món thiếu (không tính ship)',
                      style: TextStyle(fontSize: 10, color: Color(0xFF92400E)),
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
          const SizedBox(height: 8),
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

          // 2 Khung ảnh: 1 ảnh đã tải và 1 nút chụp thêm
          Row(
            children: [
              if (_hasEvidenceImage)
                Stack(
                  children: [
                    Container(
                      width: 140,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            color: Colors.black.withValues(alpha: 0.6),
                            child: const Text(
                              'Tem #8829B_KTX.jpg',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
                          '✓ Đã tải',
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
              Expanded(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
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
                        Icon(Icons.camera_alt_outlined, size: 24, color: Color(0xFF94A3B8)),
                        SizedBox(height: 4),
                        Text(
                          'Chụp thêm ảnh',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        Text(
                          'Hộp cơm / Bill',
                          style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
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
                    'Túi gom có tem niêm phong nhiệt. Chụp rõ tem giúp duyệt hoàn tiền sau 15–30 phút.',
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 6. Section: PHƯƠNG THỨC NHẬN TIỀN HOÀN
          const Text(
            'PHƯƠNG THỨC NHẬN TIỀN HOÀN',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 10),

          // Option 1: Ví KTX Food / Xu Sinh Viên
          InkWell(
            onTap: () => setState(() => _refundMethodIndex = 0),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _refundMethodIndex == 0 ? const Color(0xFFFFFBF9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _refundMethodIndex == 0 ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
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
                        color: _refundMethodIndex == 0 ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
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
                          'Nhanh nhất • Tức thì',
                          style: TextStyle(color: Color(0xFF059669), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 26, top: 2),
                    child: Text(
                      'Cộng trực tiếp số dư app ngay khi xét duyệt',
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF521B), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Tặng thêm Voucher 5.000đ bù bữa trưa',
                          style: TextStyle(fontSize: 10, color: Color(0xFFFF521B), fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 6),
                        Text('+5K', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFF521B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Option 2: Chuyển về tài khoản ngân hàng
          InkWell(
            onTap: () => setState(() => _refundMethodIndex = 1),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _refundMethodIndex == 1 ? const Color(0xFFFFFBF9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _refundMethodIndex == 1 ? const Color(0xFFFF521B) : const Color(0xFFE2E8F0),
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
                        color: _refundMethodIndex == 1 ? const Color(0xFFFF521B) : const Color(0xFF94A3B8),
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
                        Text('MB Bank (Quân Đội) • **** 8856', style: TextStyle(fontSize: 10.5, color: Color(0xFF475569))),
                        Text('LE THUY LINH', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
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
                    Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Cam kết xử lý trong 30 phút',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quán và Trưởng bàn KTX Khu B sẽ trích xuất camera soạn đơn để giải quyết thỏa đáng.',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.35),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trưởng bàn gom KTX Khu B', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text('Trực ca: 11:00 – 13:00', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: Color(0xFFFF521B)),
                          SizedBox(width: 4),
                          Text('1900 68xx', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFF521B))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 8. Nút cam Gửi Yêu Cầu Hoàn Tiền (10.000đ)
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
              label: Text(
                'Gửi Yêu Cầu Hoàn Tiền (${_formatCurrency(_calculatedRefundAmount)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOrderDishRow(String name, String price, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: TextStyle(fontSize: 11, color: isHighlighted ? const Color(0xFFFF521B) : const Color(0xFF475569))),
          Text(price, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isHighlighted ? const Color(0xFFFF521B) : const Color(0xFF1E293B))),
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
                child: Row(
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
