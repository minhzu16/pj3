import 'package:expense_tracker_frontend/core/constants/api_endpoints.dart';
import 'package:expense_tracker_frontend/models/report_models.dart';
import 'package:expense_tracker_frontend/providers/api_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedReportMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  final monthStr = now.month < 10 ? '0${now.month}' : '${now.month}';
  return '${now.year}-$monthStr';
});

final monthlySummaryProvider = FutureProvider<MonthlySummaryModel?>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final month = ref.watch(selectedReportMonthProvider);

  final response = await dio.get(
    ApiEndpoints.reportSummary,
    queryParameters: {'month': month},
  );

  if (response.statusCode == 200) {
    return MonthlySummaryModel.fromJson(response.data as Map<String, dynamic>);
  }
  return null;
});

final categoryBreakdownProvider = FutureProvider<List<CategoryBreakdownItemModel>>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final month = ref.watch(selectedReportMonthProvider);

  final parts = month.split('-');
  final year = int.parse(parts[0]);
  final m = int.parse(parts[1]);
  final lastDay = DateTime(year, m + 1, 0).day;

  final response = await dio.get(
    ApiEndpoints.reportByCategory,
    queryParameters: {
      'from': '$month-01',
      'to': '$month-$lastDay',
      'type': 'EXPENSE',
    },
  );

  if (response.statusCode == 200) {
    final items = response.data['items'] as List;
    return items.map((e) => CategoryBreakdownItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
});

final monthlyTrendProvider = FutureProvider<List<MonthlyTrendPointModel>>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final response = await dio.get(
    ApiEndpoints.reportMonthlyTrend,
    queryParameters: {'months': 12},
  );

  if (response.statusCode == 200) {
    final points = response.data['points'] as List;
    return points.map((e) => MonthlyTrendPointModel.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
});

final dailyReportProvider = FutureProvider<List<DailyReportPointModel>>((ref) async {
  final dio = ref.watch(apiClientProvider).dio;
  final month = ref.watch(selectedReportMonthProvider);

  final response = await dio.get(
    ApiEndpoints.reportDaily,
    queryParameters: {'month': month},
  );

  if (response.statusCode == 200) {
    final points = response.data['points'] as List;
    return points.map((e) => DailyReportPointModel.fromJson(e as Map<String, dynamic>)).toList();
  }
  return [];
});
