import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/category_breakdown_tab.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/daily_cumulative_tab.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/monthly_trend_tab.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/report_kpi_strip.dart';
import 'package:expense_tracker_frontend/views/reports/widgets/report_month_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            'Báo Cáo Tài Chính',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Semantics(
            label: 'Các chế độ phân tích báo cáo tài chính',
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
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          ReportMonthSelector(
            currentMonthDate: _currentMonthDate,
            onChangeMonth: _changeMonth,
          ),
          const ReportKpiStrip(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CategoryBreakdownTab(),
                MonthlyTrendTab(),
                DailyCumulativeTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
