import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/transaction_model.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:expense_tracker_frontend/views/dashboard/dashboard_view.dart';
import 'package:expense_tracker_frontend/views/transactions/widgets/transaction_filter_header.dart';
import 'package:expense_tracker_frontend/views/transactions/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key});

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  final _searchController = TextEditingController();
  String? _selectedType; // null = all, 'expense', 'income'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(transactionProvider.notifier).loadTransactions(
          type: _selectedType,
          q: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        );
  }

  String _formatCurrency(Decimal amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount.toDouble());
  }

  void _confirmDelete(BuildContext context, TransactionModel txn) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('Xác nhận xoá', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Xoá khoản giao dịch "${txn.category?.name ?? 'này'}" trị giá ${_formatCurrency(txn.amount)} khỏi sổ sách?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(transactionProvider.notifier).deleteTransaction(txn.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xoá giao dịch khỏi sổ')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Xoá ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnState = ref.watch(transactionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Sổ Giao Dịch',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ),
      body: Column(
        children: [
          TransactionFilterHeader(
            searchController: _searchController,
            selectedType: _selectedType,
            onTypeChanged: (type) {
              setState(() => _selectedType = type);
              _applyFilters();
            },
            onApplyFilters: _applyFilters,
          ),
          TransactionBalanceRibbon(
            totalCount: txnState.totalCount,
            totalIncome: txnState.totalIncome,
            totalExpense: txnState.totalExpense,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async => _applyFilters(),
              child: txnState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : txnState.transactions.isEmpty
                      ? const TransactionsEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: txnState.transactions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = txnState.transactions[index];
                            return TransactionListItem(
                              item: item,
                              onDeleteRequested: () => _confirmDelete(context, item),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF062217),
        elevation: 4,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => const AddTransactionModal(),
          );
        },
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }
}
