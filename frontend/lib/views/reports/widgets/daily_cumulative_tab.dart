import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/report_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyCumulativeTab extends ConsumerWidget {
  const DailyCumulativeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailyReportProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async => ref.invalidate(dailyReportProvider),
      child: dailyAsync.when(
        data: (dailyPoints) {
          if (dailyPoints.isEmpty) {
            return const Center(
              child: Text('Không có dữ liệu chi tiêu từng ngày', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          final spots = <FlSpot>[];
          double maxCumulative = 0;
          for (var i = 0; i < dailyPoints.length; i++) {
            final p = dailyPoints[i];
            final cum = p.cumulativeExpense.toDouble();
            if (cum > maxCumulative) maxCumulative = cum;
            spots.add(FlSpot((i + 1).toDouble(), cum));
          }
          if (maxCumulative == 0) maxCumulative = 100000;

          final latestCumulative = formatReportCurrency(dailyPoints.last.cumulativeExpense);

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
                    Semantics(
                      header: true,
                      child: Text(
                        'Quỹ đạo chi tiêu tích luỹ trong tháng',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đường cong thể hiện tốc độ tiêu tiền tích lũy mỗi ngày để sớm phát hiện chi tiêu bất thường.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      label:
                          'Biểu đồ đường quỹ đạo chi tiêu tích luỹ trong tháng gồm ${dailyPoints.length} ngày, tổng tích luỹ hiện tại $latestCumulative',
                      excludeSemantics: true,
                      child: SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            maxY: maxCumulative * 1.1,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (val) => FlLine(
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
                                  interval: 5,
                                  getTitlesWidget: (val, _) => Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'N${val.toInt()}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: AppColors.primary,
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
