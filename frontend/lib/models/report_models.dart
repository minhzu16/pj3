import 'package:decimal/decimal.dart';

class MonthlySummaryModel {
  final String month;
  final String currency;
  final Decimal totalIncome;
  final Decimal totalExpense;
  final Decimal net;
  final Decimal previousMonthExpense;
  final Decimal? expenseChangePercent;

  MonthlySummaryModel({
    required this.month,
    required this.currency,
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.previousMonthExpense,
    this.expenseChangePercent,
  });

  factory MonthlySummaryModel.fromJson(Map<String, dynamic> json) {
    return MonthlySummaryModel(
      month: json['month'] as String,
      currency: (json['currency'] ?? 'VND') as String,
      totalIncome: Decimal.parse((json['totalIncome'] ?? '0').toString()),
      totalExpense: Decimal.parse((json['totalExpense'] ?? '0').toString()),
      net: Decimal.parse((json['net'] ?? '0').toString()),
      previousMonthExpense: Decimal.parse((json['previousMonthExpense'] ?? '0').toString()),
      expenseChangePercent: json['expenseChangePercent'] != null
          ? Decimal.parse(json['expenseChangePercent'].toString())
          : null,
    );
  }
}

class CategoryBreakdownItemModel {
  final String categoryId;
  final String categoryName;
  final String color;
  final Decimal total;
  final Decimal percent;

  CategoryBreakdownItemModel({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.total,
    required this.percent,
  });

  factory CategoryBreakdownItemModel.fromJson(Map<String, dynamic> json) {
    return CategoryBreakdownItemModel(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      color: (json['color'] ?? '#9E9E9E') as String,
      total: Decimal.parse((json['total'] ?? '0').toString()),
      percent: Decimal.parse((json['percent'] ?? '0').toString()),
    );
  }
}

class MonthlyTrendPointModel {
  final String month;
  final Decimal income;
  final Decimal expense;
  final Decimal net;

  MonthlyTrendPointModel({
    required this.month,
    required this.income,
    required this.expense,
    required this.net,
  });

  factory MonthlyTrendPointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPointModel(
      month: json['month'] as String,
      income: Decimal.parse((json['income'] ?? '0').toString()),
      expense: Decimal.parse((json['expense'] ?? '0').toString()),
      net: Decimal.parse((json['net'] ?? '0').toString()),
    );
  }
}

class DailyReportPointModel {
  final DateTime date;
  final Decimal income;
  final Decimal expense;
  final Decimal cumulativeExpense;

  DailyReportPointModel({
    required this.date,
    required this.income,
    required this.expense,
    required this.cumulativeExpense,
  });

  factory DailyReportPointModel.fromJson(Map<String, dynamic> json) {
    return DailyReportPointModel(
      date: DateTime.parse(json['date'] as String),
      income: Decimal.parse((json['income'] ?? '0').toString()),
      expense: Decimal.parse((json['expense'] ?? '0').toString()),
      cumulativeExpense: Decimal.parse((json['cumulativeExpense'] ?? '0').toString()),
    );
  }
}
