import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/report_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportKpiStrip extends ConsumerWidget {
  const ReportKpiStrip({super.key});

  Widget _buildKpiItem(String label, Decimal amount, Color color) {
    final formatted = formatReportCurrency(amount);
    return Semantics(
      container: true,
      label: '$label: $formatted',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            formatted,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();
        final incomeStr = formatReportCurrency(summary.totalIncome);
        final expenseStr = formatReportCurrency(summary.totalExpense);
        final netStr = formatReportCurrency(summary.net);

        return Semantics(
          container: true,
          label: 'Tóm tắt chỉ số tháng: Thu nhập $incomeStr, Chi tiêu $expenseStr, Số dư $netStr',
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 0.8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpiItem('Thu nhập', summary.totalIncome, AppColors.income),
                Container(height: 28, width: 1, color: AppColors.divider),
                _buildKpiItem('Chi tiêu', summary.totalExpense, AppColors.expense),
                Container(height: 28, width: 1, color: AppColors.divider),
                _buildKpiItem(
                  'Số dư',
                  summary.net,
                  summary.net >= Decimal.zero ? AppColors.income : AppColors.expense,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12),
        child: LinearProgressIndicator(color: AppColors.primary),
      ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
