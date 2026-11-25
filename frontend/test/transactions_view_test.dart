import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/models/transaction_model.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:expense_tracker_frontend/views/transactions/transactions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTransactionNotifier extends TransactionNotifier {
  final TransactionState _initialState;
  String? lastTypeFilter;

  _FakeTransactionNotifier(super.ref, this._initialState) {
    state = _initialState;
  }

  @override
  Future<void> loadTransactions({
    String? from,
    String? to,
    String? type,
    String? q,
    int page = 1,
    int pageSize = 20,
  }) async {
    lastTypeFilter = type;
    state = _initialState;
  }
}

void main() {
  testWidgets('TransactionsView renders transactions and responds to filter pills', (tester) async {
    final sampleState = TransactionState(
      isLoading: false,
      totalCount: 1,
      totalIncome: Decimal.parse('500000'),
      totalExpense: Decimal.parse('120000'),
      transactions: [
        TransactionModel(
          id: 'tx-1',
          type: 'expense',
          amount: Decimal.parse('120000'),
          txnDate: DateTime(2026, 11, 25),
          category: CategoryModel(id: 'c-1', name: 'Ăn uống', type: 'expense'),
          note: 'Cơm trưa',
        ),
      ],
    );

    late _FakeTransactionNotifier fakeNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionProvider.overrideWith((ref) {
            fakeNotifier = _FakeTransactionNotifier(ref, sampleState);
            return fakeNotifier;
          }),
        ],
        child: const MaterialApp(home: TransactionsView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sổ Giao Dịch'), findsOneWidget);
    expect(find.text('1 bản ghi'), findsOneWidget);
    expect(find.text('Ăn uống'), findsOneWidget);
    expect(find.text('• Cơm trưa'), findsOneWidget);

    await tester.tap(find.text('Chi tiêu'));
    await tester.pumpAndSettle();
    expect(fakeNotifier.lastTypeFilter, 'expense');

    await tester.tap(find.text('Thu nhập'));
    await tester.pumpAndSettle();
    expect(fakeNotifier.lastTypeFilter, 'income');
  });
}
