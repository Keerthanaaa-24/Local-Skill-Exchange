class TransactionModel {
  final int transactionId;
  final int walletId;
  final int? bookingId;
  final int amount;
  final String transactionType;
  final String description;
  final String status;
  final String createdAt;

  TransactionModel({
    required this.transactionId,
    required this.walletId,
    this.bookingId,
    required this.amount,
    required this.transactionType,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transaction_id'] ?? 0,
      walletId: json['wallet_id'] ?? 0,
      bookingId: json['booking_id'],
      amount: json['amount'] ?? 0,
      transactionType: json['transaction_type'] ?? 'unknown',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'wallet_id': walletId,
      'booking_id': bookingId,
      'amount': amount,
      'transaction_type': transactionType,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }
}
