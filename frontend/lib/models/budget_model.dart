import 'package:decimal/decimal.dart';

class BudgetModel {
  final String id;
  final String? categoryId;
  final String categoryName;
  final String categoryColor;
  final DateTime month;
  final Decimal amountLimit;
  final Decimal spent;
  final Decimal remaining;
  final Decimal percent;
  final String status; // 'safe', 'warning', 'exceeded'
  final int alertThreshold;

  BudgetModel({
    required this.id,
    this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.month,
    required this.amountLimit,
    required this.spent,
    required this.remaining,
    required this.percent,
    required this.status,
    required this.alertThreshold,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String?,
      categoryName: (json['categoryName'] ?? 'Tổng ngân sách') as String,
      categoryColor: (json['categoryColor'] ?? '#2196F3') as String,
      month: DateTime.parse(json['month'] as String),
      amountLimit: Decimal.parse((json['amountLimit'] ?? '0').toString()),
      spent: Decimal.parse((json['spent'] ?? '0').toString()),
      remaining: Decimal.parse((json['remaining'] ?? '0').toString()),
      percent: Decimal.parse((json['percent'] ?? '0').toString()),
      status: (json['status'] ?? 'safe') as String,
      alertThreshold: (json['alertThreshold'] ?? 80) as int,
    );
  }
}
