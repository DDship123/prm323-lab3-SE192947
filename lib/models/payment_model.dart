/// Mô hình dữ liệu thanh toán VietQR Napas 247 & COD Fallback (PaymentResponse)
class PaymentModel {
  final int id;
  final int orderId;
  final String orderCode;
  final String paymentMethod;
  final double amount;
  final String status;
  final String? transactionRef;
  final String? vietqrContent;
  final String? qrUrl;
  final String? bankBin;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.orderCode,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    this.transactionRef,
    this.vietqrContent,
    this.qrUrl,
    this.bankBin,
    this.bankName,
    this.accountNumber,
    this.accountName,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      orderId: (json['orderId'] as num?)?.toInt() ?? 0,
      orderCode: json['orderCode'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'VIETQR',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'UNPAID',
      transactionRef: json['transactionRef'] as String?,
      vietqrContent: json['vietqrContent'] as String?,
      qrUrl: json['qrUrl'] as String?,
      bankBin: json['bankBin'] as String?,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountName: json['accountName'] as String?,
    );
  }
}
