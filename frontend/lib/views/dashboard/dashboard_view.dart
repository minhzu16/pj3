import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/providers/auth_provider.dart';
import 'package:expense_tracker_frontend/providers/report_provider.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/add_transaction_modal.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/category_breakdown_card.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/net_position_card.dart';
import 'package:expense_tracker_frontend/views/dashboard/widgets/recent_transactions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

export 'package:expense_tracker_frontend/views/dashboard/widgets/add_transaction_modal.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  void _openAddTransactionModal(BuildContext context) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Column(
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
              const NetPositionCard(),
              const SizedBox(height: 28),

              // 2. CATEGORY BREAKDOWN SECTION
              const CategoryBreakdownCard(),
              const SizedBox(height: 28),

              // 3. RECENT TRANSACTIONS LEDGER
              RecentTransactionsSection(
                onAddTransaction: () => _openAddTransactionModal(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Ghi chép giao dịch mới',
        child: FloatingActionButton.extended(
          tooltip: 'Ghi chép giao dịch mới',
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF062217),
          elevation: 4,
          onPressed: () => _openAddTransactionModal(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Ghi chép', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}
