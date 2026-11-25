import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/models/budget_model.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/models/payment_method_model.dart';
import 'package:expense_tracker_frontend/models/transaction_model.dart';
import 'package:expense_tracker_frontend/providers/budget_provider.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryModel & PaymentMethodModel Tests', () {
    test('1. CategoryModel deserializes full JSON and defaults archived to false', () {
      final json = {
        'id': 'cat-1',
        'name': 'Ăn uống',
        'type': 'expense',
        'color': '#FF5722',
        'icon': 'restaurant',
      };
      final model = CategoryModel.fromJson(json);
      expect(model.id, 'cat-1');
      expect(model.name, 'Ăn uống');
      expect(model.type, 'expense');
      expect(model.color, '#FF5722');
      expect(model.icon, 'restaurant');
      expect(model.archived, false);
    });

    test('2. CategoryModel serializes to JSON correctly', () {
      final model = CategoryModel(
        id: 'cat-2',
        name: 'Lương',
        type: 'income',
        color: '#4CAF50',
        archived: true,
      );
      final json = model.toJson();
      expect(json['id'], 'cat-2');
      expect(json['name'], 'Lương');
      expect(json['type'], 'income');
      expect(json['archived'], true);
    });

    test('3. PaymentMethodModel deserializes and serializes with default archived false', () {
      final json = {'id': 'pm-1', 'name': 'Thẻ tín dụng'};
      final model = PaymentMethodModel.fromJson(json);
      expect(model.id, 'pm-1');
      expect(model.name, 'Thẻ tín dụng');
      expect(model.archived, false);

      final exported = model.toJson();
      expect(exported['id'], 'pm-1');
      expect(exported['name'], 'Thẻ tín dụng');
      expect(exported['archived'], false);
    });
  });

  group('TransactionModel & Decimal Precision Tests', () {
    test('4. TransactionModel parses high-precision Decimal without floating point loss', () {
      final json = {
        'id': 'tx-1',
        'type': 'expense',
        'amount': '125000000.75',
        'txnDate': '2026-11-24T15:30:00.000Z',
        'note': 'Mua thiết bị văn phòng',
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.amount, Decimal.parse('125000000.75'));
      expect(tx.type, 'expense');
      expect(tx.note, 'Mua thiết bị văn phòng');
    });

    test('5. TransactionModel formats txnDate to YYYY-MM-DD in toJson', () {
      final tx = TransactionModel(
        id: 'tx-2',
        type: 'income',
        amount: Decimal.parse('50000000'),
        txnDate: DateTime(2026, 11, 24, 18, 45),
        note: 'Doanh thu hợp đồng',
      );
      final json = tx.toJson();
      expect(json['txnDate'], '2026-11-24');
      expect(json['amount'], '50000000');
    });

    test('6. TransactionModel deserializes nested category and paymentMethod', () {
      final json = {
        'id': 'tx-3',
        'type': 'expense',
        'amount': '450000',
        'txnDate': '2026-11-24',
        'category': {
          'id': 'cat-1',
          'name': 'Tiếp khách',
          'type': 'expense',
        },
        'paymentMethod': {
          'id': 'pm-1',
          'name': 'Ví điện tử',
        },
      };
      final tx = TransactionModel.fromJson(json);
      expect(tx.category?.name, 'Tiếp khách');
      expect(tx.paymentMethod?.name, 'Ví điện tử');
    });
  });

  group('BudgetModel & Budget Arithmetic Logic Tests', () {
    test('7. BudgetModel parses all Decimal fields correctly', () {
      final json = {
        'id': 'b-1',
        'categoryId': 'cat-1',
        'categoryName': 'Ẩm thực',
        'categoryColor': '#E91E63',
        'month': '2026-11-01T00:00:00.000Z',
        'amountLimit': '10000000',
        'spent': '7500000',
        'remaining': '2500000',
        'percent': '75.0',
        'status': 'safe',
        'alertThreshold': 80,
      };
      final budget = BudgetModel.fromJson(json);
      expect(budget.amountLimit, Decimal.parse('10000000'));
      expect(budget.spent, Decimal.parse('7500000'));
      expect(budget.remaining, Decimal.parse('2500000'));
      expect(budget.percent, Decimal.parse('75.0'));
      expect(budget.status, 'safe');
    });

    test('8. BudgetModel uses defaults when optional JSON values are omitted', () {
      final json = {
        'id': 'b-default',
        'month': '2026-11-01T00:00:00.000Z',
      };
      final budget = BudgetModel.fromJson(json);
      expect(budget.categoryName, 'Tổng ngân sách');
      expect(budget.categoryColor, '#2196F3');
      expect(budget.amountLimit, Decimal.zero);
      expect(budget.spent, Decimal.zero);
      expect(budget.remaining, Decimal.zero);
      expect(budget.status, 'safe');
      expect(budget.alertThreshold, 80);
    });

    test('9. Budget arithmetic calculates remaining and spent correctly', () {
      final limit = Decimal.parse('15000000');
      final spent = Decimal.parse('6200000');
      final remaining = limit - spent;
      expect(remaining, Decimal.parse('8800000'));
      expect(remaining > Decimal.zero, true);
    });

    test('10. Budget status transition from safe to warning when threshold reached', () {
      final limit = Decimal.parse('10000000');
      final spent = Decimal.parse('8500000'); // 85%
      final percent = (spent / limit).toDecimal(scaleOnInfinitePrecision: 4) * Decimal.fromInt(100);
      const threshold = 80;

      String status = 'safe';
      if (spent > limit) {
        status = 'exceeded';
      } else if (percent >= Decimal.fromInt(threshold)) {
        status = 'warning';
      }
      expect(status, 'warning');
    });

    test('11. Budget status transition to exceeded when spent exceeds limit', () {
      final limit = Decimal.parse('5000000');
      final spent = Decimal.parse('5500000');
      final remaining = limit - spent;
      expect(remaining, Decimal.parse('-500000'));

      String status = 'safe';
      if (spent > limit) {
        status = 'exceeded';
      }
      expect(status, 'exceeded');
    });
  });

  group('Riverpod Providers Tests', () {
    test('12. selectedBudgetMonthProvider initializes to current YYYY-MM', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final month = container.read(selectedBudgetMonthProvider);
      final now = DateTime.now();
      final expectedMonth = now.month < 10 ? '0${now.month}' : '${now.month}';
      final expected = '${now.year}-$expectedMonth';

      expect(month, expected);
    });

    test('13. selectedBudgetMonthProvider updates and notifies listeners', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedBudgetMonthProvider.notifier).state = '2026-12';
      expect(container.read(selectedBudgetMonthProvider), '2026-12');
    });

    test('14. TransactionState copyWith preserves unmutated state', () {
      final state = TransactionState(
        isLoading: false,
        totalIncome: Decimal.parse('20000000'),
        totalExpense: Decimal.parse('8000000'),
        totalCount: 5,
      );

      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.totalIncome, Decimal.parse('20000000'));
      expect(updated.totalExpense, Decimal.parse('8000000'));
      expect(updated.totalCount, 5);
      expect(updated.error, null);
    });

    test('15. TransactionState net balance calculation with Decimal precision', () {
      final income = Decimal.parse('45000000.50');
      final expense = Decimal.parse('18250000.25');
      final state = TransactionState(
        totalIncome: income,
        totalExpense: expense,
      );

      final netBalance = state.totalIncome - state.totalExpense;
      expect(netBalance, Decimal.parse('26750000.25'));
    });

    test('16. Accumulating multiple Decimal transactions preserves zero rounding error', () {
      final amounts = [
        Decimal.parse('100.10'),
        Decimal.parse('200.20'),
        Decimal.parse('300.30'),
      ];
      final total = amounts.fold(Decimal.zero, (prev, curr) => prev + curr);
      // In standard IEEE 754 float: 100.1 + 200.2 + 300.3 = 600.6000000000001
      // In Decimal: exactly 600.60
      expect(total, Decimal.parse('600.60'));
    });
  });
}
