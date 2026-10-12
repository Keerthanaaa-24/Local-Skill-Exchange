class WalletModel {
  final int walletId;
  final int userId;
  final int balance;
  final int totalCreditsEarned;
  final int totalCreditsSpent;
  final int pendingCredits;
  final int teachingSessionsCount;
  final int learningSessionsCount;
  final String createdAt;
  final String updatedAt;

  WalletModel({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.totalCreditsEarned,
    required this.totalCreditsSpent,
    required this.pendingCredits,
    this.teachingSessionsCount = 0,
    this.learningSessionsCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['wallet_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      balance: json['balance'] ?? 0,
      totalCreditsEarned: json['total_credits_earned'] ?? 0,
      totalCreditsSpent: json['total_credits_spent'] ?? 0,
      pendingCredits: json['pending_credits'] ?? 0,
      teachingSessionsCount: json['teaching_sessions_count'] ?? 0,
      learningSessionsCount: json['learning_sessions_count'] ?? 0,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'user_id': userId,
      'balance': balance,
      'total_credits_earned': totalCreditsEarned,
      'total_credits_spent': totalCreditsSpent,
      'pending_credits': pendingCredits,
      'teaching_sessions_count': teachingSessionsCount,
      'learning_sessions_count': learningSessionsCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
