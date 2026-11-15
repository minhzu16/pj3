import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/transaction_model.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:expense_tracker_frontend/views/dashboard/dashboard_view.dart';
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
          // Filter & Search Controls Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                // Clean Search TextField
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo nội dung ghi chú...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),

                // Flow Filter Segmented Buttons
                Row(
                  children: [
                    _buildFilterPill('Tất cả', _selectedType == null, () {
                      setState(() => _selectedType = null);
                      _applyFilters();
                    }),
                    const SizedBox(width: 8),
                    _buildFilterPill('Chi tiêu', _selectedType == 'expense', () {
                      setState(() => _selectedType = 'expense');
                      _applyFilters();
                    }, accentColor: AppColors.expense),
                    const SizedBox(width: 8),
                    _buildFilterPill('Thu nhập', _selectedType == 'income', () {
                      setState(() => _selectedType = 'income');
                      _applyFilters();
                    }, accentColor: AppColors.income),
                  ],
                ),
              ],
            ),
          ),

          // Balance Ledger Tape Ribbon
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${txnState.totalCount} bản ghi',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatCurrency(txnState.totalIncome),
                          style: const TextStyle(color: AppColors.income, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatCurrency(txnState.totalExpense),
                          style: const TextStyle(color: AppColors.expense, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Ledger Items List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async => _applyFilters(),
              child: txnState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : txnState.transactions.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.6)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Không tìm thấy giao dịch phù hợp',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Hãy thử từ khoá khác hoặc thêm giao dịch mới',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: txnState.transactions.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = txnState.transactions[index];
                            final isExpense = item.type == 'expense';

                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                _confirmDelete(context, item);
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.expense,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                                        color: isExpense ? AppColors.expense : AppColors.income,
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.category?.name ?? 'Chưa phân loại',
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(item.txnDate),
                                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                              ),
                                              if (item.paymentMethod != null) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceVariant,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    item.paymentMethod!.name,
                                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                                  ),
                                                ),
                                              ],
                                              if (item.note != null && item.note!.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '• ${item.note}',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isExpense ? '-' : '+'}${_formatCurrency(item.amount)}',
                                          style: TextStyle(
                                            color: isExpense ? AppColors.expense : AppColors.income,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        InkWell(
                                          onTap: () => _confirmDelete(context, item),
                                          child: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted, size: 18),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildFilterPill(String label, bool isSelected, VoidCallback onTap, {Color? accentColor}) {
    final activeColor = accentColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : AppColors.cardBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (accentColor ?? AppColors.primaryLight) : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
