import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/dashboard_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class NetPositionCard extends ConsumerWidget {
  const NetPositionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);

    return summaryAsync.when(
      data: (summary) {
        if (summary == null) return const SizedBox.shrink();

        final isPositive = summary.net >= Decimal.zero;
        final totalFlow = (summary.totalIncome + summary.totalExpense).toDouble();
        final incomeRatio = totalFlow > 0
            ? (summary.totalIncome.toDouble() / totalFlow).clamp(0.05, 0.95)
            : 0.5;
        final netFormatted = '${isPositive ? '+' : ''}${formatDashboardCurrency(summary.net)}';
        final statusLabel = isPositive ? 'Thặng dư an toàn' : 'Thâm hụt chi tiêu';
        final incomeFormatted = formatDashboardCurrency(summary.totalIncome);
        final expenseFormatted = formatDashboardCurrency(summary.totalExpense);

        return Semantics(
          container: true,
          label: 'Thẻ tổng quan số dư ròng tháng này: $netFormatted, $statusLabel',
          child: Container(
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
                        statusLabel,
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
                Semantics(
                  label: 'Số dư ròng: $netFormatted',
                  excludeSemantics: true,
                  child: Text(
                    netFormatted,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      color: isPositive ? AppColors.textPrimary : AppColors.expense,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (summary.expenseChangePercent != null)
                  Row(
                    children: [
                      Icon(
                        summary.expenseChangePercent! > Decimal.zero
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: summary.expenseChangePercent! > Decimal.zero
                            ? AppColors.warning
                            : AppColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Chi tiêu ${summary.expenseChangePercent! > Decimal.zero ? 'tăng' : 'giảm'} ${summary.expenseChangePercent!.abs()}% so với tháng trước',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'Tỷ lệ dòng tiền: thu vào ${(incomeRatio * 100).round()}%, chi ra ${((1 - incomeRatio) * 100).round()}%',
                  excludeSemantics: true,
                  child: ClipRRect(
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
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        container: true,
                        label: 'Thu vào: $incomeFormatted',
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: AppColors.income, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                const Text('Thu vào', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              incomeFormatted,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.income),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 32, color: AppColors.divider),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Semantics(
                        container: true,
                        label: 'Chi ra: $expenseFormatted',
                        excludeSemantics: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(color: AppColors.expense, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                const Text('Chi ra', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expenseFormatted,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.expense),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Semantics(
        label: 'Đang tải tổng hợp số dư ròng',
        child: Container(
          height: 180,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(22)),
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ),
      error: (e, _) => Text('Không thể tải tổng hợp: $e', style: const TextStyle(color: AppColors.expense)),
    );
  }
}
