import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/dashboard_formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CategoryBreakdownCard extends ConsumerWidget {
  const CategoryBreakdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = ref.watch(categoryBreakdownProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Cơ cấu chi tiêu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        categoryAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return Semantics(
                container: true,
                label: 'Chưa ghi nhận khoản chi tiêu nào trong tháng này',
                child: Container(
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
                  Semantics(
                    label: 'Biểu đồ tròn cơ cấu chi tiêu theo danh mục, gồm ${categories.length} hạng mục',
                    excludeSemantics: true,
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 52,
                          sections: categories.map((c) {
                            final color = parseDashboardCategoryColor(c.color);
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
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 12),
                  ...categories.take(4).map((c) {
                    final color = parseDashboardCategoryColor(c.color);
                    final formattedTotal = formatDashboardCurrency(c.total);
                    return Semantics(
                      container: true,
                      label: '${c.categoryName}: $formattedTotal, chiếm ${c.percent}%',
                      excludeSemantics: true,
                      child: Padding(
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
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              formattedTotal,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ),
          error: (e, _) => Text('Lỗi tải cơ cấu: $e', style: const TextStyle(color: AppColors.expense)),
        ),
      ],
    );
  }
}
