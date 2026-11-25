import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/report_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryBreakdownTab extends ConsumerWidget {
  const CategoryBreakdownTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryBreakdownProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(categoryBreakdownProvider);
        ref.invalidate(monthlySummaryProvider);
      },
      child: categoryAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'Không có dữ liệu chi tiêu trong tháng này',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder, width: 0.8),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Tỷ trọng chi tiêu theo danh mục',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Semantics(
                      label: 'Biểu đồ tròn tỷ trọng chi tiêu theo danh mục, gồm ${categories.length} hạng mục',
                      excludeSemantics: true,
                      child: SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 46,
                            sections: categories.map((c) {
                              final color = parseReportColor(c.color);
                              return PieChartSectionData(
                                color: color,
                                value: c.total.toDouble(),
                                title: '${c.percent}%',
                                radius: 32,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  'Chi tiết từng hạng mục',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...categories.map((c) {
                final color = parseReportColor(c.color);
                final progressVal = (c.percent.toDouble() / 100.0).clamp(0.0, 1.0);
                final formattedTotal = formatReportCurrency(c.total);
                return Semantics(
                  container: true,
                  label: 'Hạng mục ${c.categoryName}: đã chi $formattedTotal, chiếm ${c.percent}%',
                  excludeSemantics: true,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder, width: 0.8),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.categoryName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              formattedTotal,
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${c.percent}%',
                                textAlign: TextAlign.end,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressVal,
                            minHeight: 5,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
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
