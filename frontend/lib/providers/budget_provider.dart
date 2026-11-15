import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/api_endpoints.dart';
import 'package:expense_tracker_frontend/models/budget_model.dart';
import 'package:expense_tracker_frontend/providers/api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedBudgetMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  final monthStr = now.month < 10 ? '0${now.month}' : '${now.month}';
  return '${now.year}-$monthStr';
});

final budgetsListProvider = FutureProvider<List<BudgetModel>>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final month = ref.watch(selectedBudgetMonthProvider);

  final response = await dio.get(
    ApiEndpoints.budgets,
    queryParameters: {'month': month},
  );

  if (response.statusCode == 200) {
    return (response.data as List)
        .map((e) => BudgetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return [];
});

class BudgetActionNotifier {
  final Ref ref;
  BudgetActionNotifier(this.ref);

  Future<void> createBudget({
    String? categoryId,
    required String month,
    required Decimal amountLimit,
    int alertThreshold = 80,
  }) async {
    final dio = ref.read(apiClientProvider).dio;
    final payload = {
      'categoryId': categoryId,
      'month': '$month-01',
      'amountLimit': amountLimit.toString(),
      'alertThreshold': alertThreshold,
    };

    await dio.post(ApiEndpoints.budgets, data: payload);
    ref.invalidate(budgetsListProvider);
  }

  Future<void> deleteBudget(String id) async {
    final dio = ref.read(apiClientProvider).dio;
    await dio.delete('${ApiEndpoints.budgets}/$id');
    ref.invalidate(budgetsListProvider);
  }

  Future<void> copyBudgets({required String from, required String to}) async {
    final dio = ref.read(apiClientProvider).dio;
    await dio.post(
      ApiEndpoints.copyBudgets,
      data: {'from': from, 'to': to},
    );
    ref.invalidate(budgetsListProvider);
  }
}

final budgetActionProvider = Provider<BudgetActionNotifier>((ref) {
  return BudgetActionNotifier(ref);
});
