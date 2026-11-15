import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/api_endpoints.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/models/payment_method_model.dart';
import 'package:expense_tracker_frontend/models/transaction_model.dart';
import 'package:expense_tracker_frontend/providers/api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionState {
  final bool isLoading;
  final List<TransactionModel> transactions;
  final Decimal totalIncome;
  final Decimal totalExpense;
  final int totalCount;
  final String? error;

  TransactionState({
    this.isLoading = false,
    this.transactions = const [],
    Decimal? totalIncome,
    Decimal? totalExpense,
    this.totalCount = 0,
    this.error,
  })  : totalIncome = totalIncome ?? Decimal.zero,
        totalExpense = totalExpense ?? Decimal.zero;

  TransactionState copyWith({
    bool? isLoading,
    List<TransactionModel>? transactions,
    Decimal? totalIncome,
    Decimal? totalExpense,
    int? totalCount,
    String? error,
  }) {
    return TransactionState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      totalCount: totalCount ?? this.totalCount,
      error: error,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final Ref ref;

  TransactionNotifier(this.ref) : super(TransactionState(isLoading: true)) {
    loadTransactions();
  }

  Future<void> loadTransactions({
    String? from,
    String? to,
    String? type,
    String? q,
    int page = 1,
    int pageSize = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;
      if (type != null) queryParams['type'] = type;
      if (q != null && q.isNotEmpty) queryParams['q'] = q;

      final response = await dio.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = (data['items'] as List)
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final totals = data['totals'] as Map<String, dynamic>?;
        final income = totals != null ? Decimal.parse((totals['income'] ?? '0').toString()) : Decimal.zero;
        final expense = totals != null ? Decimal.parse((totals['expense'] ?? '0').toString()) : Decimal.zero;
        final total = (data['total'] ?? 0) as int;

        state = state.copyWith(
          isLoading: false,
          transactions: items,
          totalIncome: income,
          totalExpense: expense,
          totalCount: total,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Map<String, dynamic>?> addTransaction({
    required String type,
    required Decimal amount,
    required DateTime txnDate,
    required String categoryId,
    String? paymentMethodId,
    String? note,
  }) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final payload = {
        'type': type,
        'amount': amount.toString(),
        'txnDate': txnDate.toIso8601String().substring(0, 10),
        'categoryId': categoryId,
        'paymentMethodId': paymentMethodId,
        'note': note,
      };

      final response = await dio.post(ApiEndpoints.transactions, data: payload);
      if (response.statusCode == 201) {
        await loadTransactions();
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<void> deleteTransaction(String id) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.delete('${ApiEndpoints.transactions}/$id');
      if (response.statusCode == 204 || response.statusCode == 200) {
        await loadTransactions();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction({
    required String id,
    String? type,
    Decimal? amount,
    DateTime? txnDate,
    String? categoryId,
    String? paymentMethodId,
    String? note,
  }) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final payload = <String, dynamic>{};
      if (type != null) payload['type'] = type;
      if (amount != null) payload['amount'] = amount.toString();
      if (txnDate != null) payload['txnDate'] = txnDate.toIso8601String().substring(0, 10);
      if (categoryId != null) payload['categoryId'] = categoryId;
      if (paymentMethodId != null) payload['paymentMethodId'] = paymentMethodId;
      if (note != null) payload['note'] = note;

      final response = await dio.patch('${ApiEndpoints.transactions}/$id', data: payload);
      if (response.statusCode == 200) {
        await loadTransactions();
      }
    } catch (e) {
      rethrow;
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref);
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final dio = ref.read(apiClientProvider).dio;
  final response = await dio.get(ApiEndpoints.categories);
  if (response.statusCode == 200) {
    return (response.data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return [];
});

final paymentMethodsProvider = FutureProvider<List<PaymentMethodModel>>((ref) async {
  final dio = ref.read(apiClientProvider).dio;
  final response = await dio.get(ApiEndpoints.paymentMethods);
  if (response.statusCode == 200) {
    return (response.data as List)
        .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return [];
});
