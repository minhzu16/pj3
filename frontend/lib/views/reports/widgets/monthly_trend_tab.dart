import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/report_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyTrendTab extends ConsumerWidget {
  const MonthlyTrendTab({super.key});

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(monthlyTrendProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async => ref.invalidate(monthlyTrendProvider),
      child: trendAsync.when(
        data: (trendPoints) {
          if (trendPoints.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu xu hướng', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final barGroups = <BarChartGroupData>[];
          double maxY = 0;
          for (var i = 0; i < trendPoints.length; i++) {
            final p = trendPoints[i];
            final inc = p.income.toDouble();
            final exp = p.expense.toDouble();
            if (inc > maxY) maxY = inc;
            if (exp > maxY) maxY = exp;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: inc,
                    color: AppColors.income,
                    width: 6,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: exp,
                    color: AppColors.expense,
                    width: 6,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            );
          }
          if (maxY == 0) maxY = 100000;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Thu / Chi 12 tháng gần nhất',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            _buildLegendItem('Thu', AppColors.income),
                            const SizedBox(width: 12),
                            _buildLegendItem('Chi', AppColors.expense),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      label: 'Biểu đồ cột thu và chi 12 tháng gần nhất gồm ${trendPoints.length} tháng',
                      excludeSemantics: true,
                      child: SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY * 1.15,
                            barGroups: barGroups,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: AppColors.cardBorder.withValues(alpha: 0.5),
                                strokeWidth: 0.8,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget: (val, _) => Text(
                                    formatShortCurrency(val),
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                  ),
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, _) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < trendPoints.length) {
                                      final monthStr = trendPoints[idx].month;
                                      final parts = monthStr.split('-');
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          'T${parts.length > 1 ? parts[1] : monthStr}',
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Lịch sử theo tháng',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...trendPoints.reversed.map((p) {
                final incStr = formatReportCurrency(p.income);
                final expStr = formatReportCurrency(p.expense);
                final netStr = formatReportCurrency(p.net);
                return Semantics(
                  container: true,
                  label: 'Tháng ${p.month}: thu $incStr, chi $expStr, dư $netStr',
                  excludeSemantics: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder, width: 0.8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          'Tháng ${p.month}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text('+$incStr', style: const TextStyle(color: AppColors.income, fontSize: 12)),
                                const SizedBox(width: 8),
                                Text('-$expStr', style: const TextStyle(color: AppColors.expense, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dư: $netStr',
                              style: TextStyle(
                                color: p.net >= Decimal.zero ? AppColors.income : AppColors.expense,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Lỗi: $e', style: const TextStyle(color: AppColors.expense))),
      ),
    );
  }
}
