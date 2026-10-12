import '../services/api_client.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class WalletRepository {
  final ApiClient _apiClient;

  WalletRepository(this._apiClient);

  Future<WalletModel> getWallet() async {
    try {
      final response = await _apiClient.dio.get('/wallet');
      return WalletModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch wallet: $e');
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _apiClient.dio.get('/wallet/transactions');
      return (response.data as List).map((e) => TransactionModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<TransactionModel> getTransactionById(int id) async {
    try {
      final response = await _apiClient.dio.get('/wallet/transactions/$id');
      return TransactionModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch transaction details: $e');
    }
  }
}
