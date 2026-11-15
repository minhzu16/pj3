import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Expense Tracker Model Tests', () {
    test('CategoryModel deserialization', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Ăn uống',
        'type': 'expense',
        'color': '#FF5722',
        'icon': 'restaurant',
      };

      final cat = CategoryModel.fromJson(json);
      expect(cat.id, '11111111-1111-1111-1111-111111111111');
      expect(cat.name, 'Ăn uống');
      expect(cat.type, 'expense');
      expect(cat.color, '#FF5722');
      expect(cat.icon, 'restaurant');
    });

    test('TransactionModel decimal precision', () {
      final json = {
        'id': '22222222-2222-2222-2222-222222222222',
        'type': 'expense',
        'amount': '1250000.50',
        'txnDate': '2026-10-01',
        'category': {
          'id': '11111111-1111-1111-1111-111111111111',
          'name': 'Ăn uống',
          'type': 'expense',
        },
        'note': 'Ăn trưa',
      };

      final txn = TransactionModel.fromJson(json);
      expect(txn.amount, Decimal.parse('1250000.50'));
      expect(txn.type, 'expense');
      expect(txn.category?.name, 'Ăn uống');
      expect(txn.note, 'Ăn trưa');
    });
  });
}
