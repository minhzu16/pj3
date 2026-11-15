import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentMonthDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _syncProviderMonth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _syncProviderMonth() {
    final monthStr = _currentMonthDate.month < 10 ? '0${_currentMonthDate.month}' : '${_currentMonthDate.month}';
    final formatted = '${_currentMonthDate.year}-$monthStr';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedReportMonthProvider.notifier).state = formatted;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonthDate = DateTime(_currentMonthDate.year, _currentMonthDate.month + delta, 1);
    });
    _syncProviderMonth();
  }

  String _formatCurrency(Decimal amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount.toDouble());
  }

  String _formatShortCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}Tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final monthFormat = DateFormat('MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Báo Cáo Tài Chính',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Cơ cấu chi'),
                Tab(text: 'Xu hướng năm'),
                Tab(text: 'Lũy kế ngày'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // Month navigation bar capsule
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 20),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Tháng ${monthFormat.format(_currentMonthDate)}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 20),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
          ),

          // Overview KPI strip
          summaryAsync.when(
            data: (summary) {
              if (summary == null) return const SizedBox.shrink();
              return Container(
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
                    _buildKpiItem('Số dư', summary.net, summary.net >= Decimal.zero ? AppColors.income : AppColors.expense),
                  ],
                ),
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator(color: AppColors.primary)),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryBreakdownTab(),
                _buildMonthlyTrendTab(),
                _buildDailyCumulativeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String label, Decimal amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // 1. Category Breakdown Tab
  Widget _buildCategoryBreakdownTab() {
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
              child: Text('Không có dữ liệu chi tiêu trong tháng này', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                    Text(
                      'Tỷ trọng chi tiêu theo danh mục',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 46,
                          sections: categories.map((c) {
                            final color = _parseColor(c.color);
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chi tiết từng hạng mục',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...categories.map((c) {
                final color = _parseColor(c.color);
                final progressVal = (c.percent.toDouble() / 100.0).clamp(0.0, 1.0);
                return Container(
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
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                          Text(
                            _formatCurrency(c.total),
                            style: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700, fontSize: 13),
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

  // 2. 12-Month Trend Tab
  Widget _buildMonthlyTrendTab() {
    final trendAsync = ref.watch(monthlyTrendProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async => ref.invalidate(monthlyTrendProvider),
      child: trendAsync.when(
        data: (trendPoints) {
          if (trendPoints.isEmpty) {
            return const Center(child: Text('Không có dữ liệu xu hướng', style: TextStyle(color: AppColors.textSecondary)));
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
                        Text(
                          'Thu / Chi 12 tháng gần nhất',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                    SizedBox(
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
                                  _formatShortCurrency(val),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Lịch sử theo tháng',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              ...trendPoints.reversed.map((p) {
                return Container(
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
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text('+${_formatCurrency(p.income)}', style: const TextStyle(color: AppColors.income, fontSize: 12)),
                              const SizedBox(width: 8),
                              Text('-${_formatCurrency(p.expense)}', style: const TextStyle(color: AppColors.expense, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Dư: ${_formatCurrency(p.net)}',
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

  // 3. Daily Cumulative Tab
  Widget _buildDailyCumulativeTab() {
    final dailyAsync = ref.watch(dailyReportProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async => ref.invalidate(dailyReportProvider),
      child: dailyAsync.when(
        data: (dailyPoints) {
          if (dailyPoints.isEmpty) {
            return const Center(child: Text('Không có dữ liệu chi tiêu từng ngày', style: TextStyle(color: AppColors.textSecondary)));
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
                    Text(
                      'Quỹ đạo chi tiêu tích luỹ trong tháng',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Đường cong thể hiện tốc độ tiêu tiền tích lũy mỗi ngày để sớm phát hiện chi tiêu bất thường.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
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
                                  _formatShortCurrency(val),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
