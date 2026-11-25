import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/dashboard_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RecentTransactionsSection extends ConsumerWidget {
  final VoidCallback onAddTransaction;

  const RecentTransactionsSection({
    super.key,
    required this.onAddTransaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionProvider).transactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Sổ ghi gần đây',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: 'Ghi khoản giao dịch mới',
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: onAddTransaction,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ghi khoản mới', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (txns.isEmpty)
          Semantics(
            container: true,
            label: 'Chưa có giao dịch nào được ghi nhận',
            child: Container(
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
              final categoryName = item.category?.name ?? 'Khoản khác';
              final dateFormatted = DateFormat('dd/MM/yyyy').format(item.txnDate);
              final amountFormatted = '${isExpense ? '-' : '+'}${formatDashboardCurrency(item.amount)}';
              final noteSuffix = item.note != null && item.note!.isNotEmpty ? ', ghi chú ${item.note}' : '';

              return Semantics(
                container: true,
                label: '${isExpense ? 'Chi tiêu' : 'Thu nhập'} $categoryName, $amountFormatted, ngày $dateFormatted$noteSuffix',
                excludeSemantics: true,
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
                              categoryName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateFormatted +
                                  (item.note != null && item.note!.isNotEmpty ? ' • ${item.note}' : ''),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        amountFormatted,
                        style: TextStyle(
                          color: isExpense ? AppColors.expense : AppColors.income,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
