import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/home_cards.dart';
import '../../providers/wallet_provider.dart';

class CreditBalanceCardWidget extends ConsumerWidget {
  const CreditBalanceCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletNotifierProvider);
    return walletAsync.when(
      data: (walletState) => CreditBalanceCard(balance: walletState.wallet.balance),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Text('Error loading balance'),
    );
  }
}
