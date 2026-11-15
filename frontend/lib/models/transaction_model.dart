import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/models/payment_method_model.dart';

class TransactionModel {
  final String id;
  final String type; // 'income' or 'expense'
  final Decimal amount;
  final DateTime txnDate;
  final CategoryModel? category;
  final PaymentMethodModel? paymentMethod;
  final String? note;
  final String? recurringRuleId;
  final DateTime? occurrenceDate;
  final DateTime? createdAt;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.txnDate,
    this.category,
    this.paymentMethod,
    this.note,
    this.recurringRuleId,
    this.occurrenceDate,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: Decimal.parse(json['amount'].toString()),
      txnDate: DateTime.parse(json['txnDate'] as String),
      category: json['category'] != null ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>) : null,
      paymentMethod: json['paymentMethod'] != null ? PaymentMethodModel.fromJson(json['paymentMethod'] as Map<String, dynamic>) : null,
      note: json['note'] as String?,
      recurringRuleId: json['recurringRuleId'] as String?,
      occurrenceDate: json['occurrenceDate'] != null ? DateTime.parse(json['occurrenceDate'] as String) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount.toString(),
      'txnDate': txnDate.toIso8601String().substring(0, 10),
      'categoryId': category?.id,
      'paymentMethodId': paymentMethod?.id,
      'note': note,
    };
  }
}
