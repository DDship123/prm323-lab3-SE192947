class WalletTransactionItem {
  final String transactionId;
  final String type;
  final String title;
  final double amount;
  final DateTime? createdAt;
  final String status;

  WalletTransactionItem({
    required this.transactionId,
    required this.type,
    required this.title,
    required this.amount,
    this.createdAt,
    required this.status,
  });

  factory WalletTransactionItem.fromJson(Map<String, dynamic> json) {
    return WalletTransactionItem(
      transactionId: json['transactionId'] ?? '',
      type: json['type'] ?? 'CONG_THU_LAO',
      title: json['title'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      status: json['status'] ?? 'SUCCESS',
    );
  }
}

class ShipperWalletModel {
  final double walletBalance;
  final double pendingEarnings;
  final double completedEarnings;
  final int completedTrips;
  final double codCollectedToday;
  final List<WalletTransactionItem> recentTransactions;

  ShipperWalletModel({
    required this.walletBalance,
    required this.pendingEarnings,
    required this.completedEarnings,
    required this.completedTrips,
    required this.codCollectedToday,
    required this.recentTransactions,
  });

  factory ShipperWalletModel.fromJson(Map<String, dynamic> json) {
    return ShipperWalletModel(
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      pendingEarnings: (json['pendingEarnings'] as num?)?.toDouble() ?? 0.0,
      completedEarnings: (json['completedEarnings'] as num?)?.toDouble() ?? 0.0,
      completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
      codCollectedToday: (json['codCollectedToday'] as num?)?.toDouble() ?? 0.0,
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => WalletTransactionItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
