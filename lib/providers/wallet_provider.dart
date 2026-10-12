import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../repositories/wallet_repository.dart';
import '../services/api_client.dart';

class WalletState {
  final WalletModel wallet;
  final List<TransactionModel> transactions;

  WalletState({required this.wallet, required this.transactions});
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(apiClient);
});

final walletNotifierProvider = AsyncNotifierProvider<WalletNotifier, WalletState>(() {
  return WalletNotifier();
});

class WalletNotifier extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() async {
    return _fetchWalletData();
  }

  Future<WalletState> _fetchWalletData() async {
    final repository = ref.read(walletRepositoryProvider);
    final wallet = await repository.getWallet();
    final transactions = await repository.getTransactions();
    return WalletState(wallet: wallet, transactions: transactions);
  }

  Future<void> refreshWallet() async {
    state = const AsyncValue.loading();
    try {
      final data = await _fetchWalletData();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
