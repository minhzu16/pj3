import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/providers/auth_provider.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  String _formatCurrency(Decimal amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount.toDouble());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final categoryAsync = ref.watch(categoryBreakdownProvider);
    final txns = ref.watch(transactionProvider).transactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user != null && user.fullName.isNotEmpty ? user.fullName : 'Sổ Chi Tiêu & Tài Chính',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('MMMM, yyyy', 'vi_VN').format(DateTime.now()),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          ref.invalidate(monthlySummaryProvider);
          ref.invalidate(categoryBreakdownProvider);
          await ref.read(transactionProvider.notifier).loadTransactions();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. MEMORABLE CENTERPIECE: The Net Position Vault Hero
              summaryAsync.when(
                data: (summary) {
                  if (summary == null) return const SizedBox.shrink();

                  final isPositive = summary.net >= Decimal.zero;
                  final totalFlow = (summary.totalIncome + summary.totalExpense).toDouble();
                  final incomeRatio = totalFlow > 0 ? (summary.totalIncome.toDouble() / totalFlow).clamp(0.05, 0.95) : 0.5;

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.cardBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Số dư ròng tháng này',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isPositive ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: (isPositive ? AppColors.income : AppColors.expense).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                isPositive ? 'Thặng dư an toàn' : 'Thâm hụt chi tiêu',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isPositive ? AppColors.income : AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Large Net Figure
                        Text(
                          '${isPositive ? '+' : ''}${_formatCurrency(summary.net)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: isPositive ? AppColors.textPrimary : AppColors.expense,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Comparison sentence
                        if (summary.expenseChangePercent != null)
                          Row(
                            children: [
                              Icon(
                                summary.expenseChangePercent! > Decimal.zero ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 14,
                                color: summary.expenseChangePercent! > Decimal.zero ? AppColors.warning : AppColors.primaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Chi tiêu ${summary.expenseChangePercent! > Decimal.zero ? 'tăng' : 'giảm'} ${summary.expenseChangePercent!.abs()}% so với tháng trước',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Cashflow dual progress track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 6,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (incomeRatio * 100).toInt(),
                                  child: Container(color: AppColors.income),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  flex: ((1 - incomeRatio) * 100).toInt(),
                                  child: Container(color: AppColors.expense),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bottom split metrics
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      const Text('Thu vào', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(summary.totalIncome),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.income),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: AppColors.divider),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.expense, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      const Text('Chi ra', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency(summary.totalExpense),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.expense),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                loading: () => Container(
                  height: 180,
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
                  child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Text('Không thể tải tổng hợp: $e', style: const TextStyle(color: AppColors.expense)),
              ),

              const SizedBox(height: 28),

              // 2. CATEGORY BREAKDOWN SECTION
              Text(
                'Cơ cấu chi tiêu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              categoryAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'Chưa ghi nhận khoản chi tiêu nào trong tháng này',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 52,
                              sections: categories.map((c) {
                                final color = _parseColor(c.color);
                                return PieChartSectionData(
                                  color: color,
                                  value: c.total.toDouble(),
                                  title: '${c.percent}%',
                                  radius: 28,
                                  titleStyle: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.divider),
                        const SizedBox(height: 12),
                        ...categories.take(4).map((c) {
                          final color = _parseColor(c.color);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.categoryName,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  _formatCurrency(c.total),
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    '${c.percent}%',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
                error: (e, _) => Text('Lỗi tải cơ cấu: $e', style: const TextStyle(color: AppColors.expense)),
              ),

              const SizedBox(height: 28),

              // 3. RECENT TRANSACTIONS LEDGER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sổ ghi gần đây',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryLight,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () => _openAddTransactionModal(context, ref),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ghi khoản mới', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (txns.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.textMuted.withValues(alpha: 0.6)),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có giao dịch nào được ghi nhận',
                          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bắt đầu ghi chép để theo dõi bức tranh tài chính chính xác',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: txns.take(5).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = txns[index];
                    final isExpense = item.type == 'expense';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder, width: 0.8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: (isExpense ? AppColors.expense : AppColors.income).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                              color: isExpense ? AppColors.expense : AppColors.income,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.category?.name ?? 'Khoản khác',
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(item.txnDate) +
                                      (item.note != null && item.note!.isNotEmpty ? ' • ${item.note}' : ''),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isExpense ? '-' : '+'}${_formatCurrency(item.amount)}',
                            style: TextStyle(
                              color: isExpense ? AppColors.expense : AppColors.income,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF062217),
        elevation: 4,
        onPressed: () => _openAddTransactionModal(context, ref),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Ghi chép', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  void _openAddTransactionModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AddTransactionModal(),
    );
  }
}

class AddTransactionModal extends ConsumerStatefulWidget {
  const AddTransactionModal({super.key});

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';
  CategoryModel? _selectedCategory;
  final DateTime _txnDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountVal = Decimal.tryParse(_amountController.text.replaceAll(',', ''));
    if (amountVal == null || amountVal <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ (> 0)')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục tương ứng')),
      );
      return;
    }

    try {
      final res = await ref.read(transactionProvider.notifier).addTransaction(
        type: _type,
        amount: amountVal,
        txnDate: _txnDate,
        categoryId: _selectedCategory!.id,
        note: _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context);

        if (res != null && res['budgetAlerts'] != null) {
          final alerts = res['budgetAlerts'] as List;
          if (alerts.isNotEmpty) {
            final alert = alerts.first as Map<String, dynamic>;
            final message = alert['message'] ?? 'Cảnh báo hạn mức!';
            final status = alert['status'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: status == 'exceeded' ? AppColors.expense : AppColors.warning,
                content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ghi nhận giao dịch',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Flow Segment Pill
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = 'expense'; _selectedCategory = null; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == 'expense' ? AppColors.surfaceElevated : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _type == 'expense' ? Border.all(color: AppColors.cardBorder) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Chi tiêu',
                        style: TextStyle(
                          color: _type == 'expense' ? AppColors.expense : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _type = 'income'; _selectedCategory = null; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _type == 'income' ? AppColors.surfaceElevated : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _type == 'income' ? Border.all(color: AppColors.cardBorder) : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Thu nhập',
                        style: TextStyle(
                          color: _type == 'income' ? AppColors.income : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Số tiền (VND)',
              prefixIcon: Icon(Icons.payments_outlined, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Category Select
          categoriesAsync.when(
            data: (cats) {
              final filtered = cats.where((c) => c.type == _type).toList();
              return DropdownButtonFormField<CategoryModel>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Hạng mục chi tiêu'),
                dropdownColor: AppColors.surfaceElevated,
                items: filtered.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              );
            },
            loading: () => const LinearProgressIndicator(color: AppColors.primary),
            error: (_, _) => const Text('Không thể tải danh mục', style: TextStyle(color: AppColors.expense)),
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tuỳ chọn)',
              prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _submit,
            child: const Text('Lưu vào sổ cái'),
          ),
        ],
      ),
    );
  }
}
