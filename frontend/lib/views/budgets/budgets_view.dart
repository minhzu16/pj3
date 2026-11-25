import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/budget_model.dart';
import 'package:expense_tracker_frontend/providers/budget_provider.dart';
import 'package:expense_tracker_frontend/views/budgets/widgets/budget_item_card.dart';
import 'package:expense_tracker_frontend/views/budgets/widgets/budget_month_selector.dart';
import 'package:expense_tracker_frontend/views/budgets/widgets/budgets_empty_state.dart';
import 'package:expense_tracker_frontend/views/budgets/widgets/create_budget_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class BudgetsView extends ConsumerStatefulWidget {
  const BudgetsView({super.key});

  @override
  ConsumerState<BudgetsView> createState() => _BudgetsViewState();
}

class _BudgetsViewState extends ConsumerState<BudgetsView> {
  DateTime _currentMonthDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _syncProviderMonth();
  }

  void _syncProviderMonth() {
    final monthStr = _currentMonthDate.month < 10 ? '0${_currentMonthDate.month}' : '${_currentMonthDate.month}';
    final formatted = '${_currentMonthDate.year}-$monthStr';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedBudgetMonthProvider.notifier).state = formatted;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonthDate = DateTime(_currentMonthDate.year, _currentMonthDate.month + delta, 1);
    });
    _syncProviderMonth();
  }

  void _openCreateBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => CreateBudgetModal(
        monthStr: ref.read(selectedBudgetMonthProvider),
      ),
    );
  }

  Future<void> _handleCopyBudgets() async {
    final prevDate = DateTime(_currentMonthDate.year, _currentMonthDate.month - 1, 1);
    final prevMonthStr = '${prevDate.year}-${prevDate.month < 10 ? '0${prevDate.month}' : '${prevDate.month}'}';
    final currentMonthStr = ref.read(selectedBudgetMonthProvider);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('Sao chép ngân sách', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Sao chép toàn bộ hạn mức từ tháng $prevMonthStr sang tháng $currentMonthStr?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sao chép ngay'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(budgetActionProvider).copyBudgets(from: prevMonthStr, to: currentMonthStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã sao chép ngân sách thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }

  void _confirmDeleteBudget(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: const Text('Xoá ngân sách', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        content: Text(
          'Bạn có chắc chắn muốn gỡ bỏ ngân sách "${budget.categoryName}"?',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(budgetActionProvider).deleteBudget(budget.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xoá ngân sách')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              }
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Semantics(
          header: true,
          child: Text(
            'Kế Hoạch Ngân Sách',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sao chép từ tháng trước',
            icon: const Icon(Icons.copy_rounded, color: AppColors.primaryLight, size: 20),
            onPressed: _handleCopyBudgets,
          ),
        ],
      ),
      body: Column(
        children: [
          BudgetMonthSelector(
            currentMonthDate: _currentMonthDate,
            onChangeMonth: _changeMonth,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async => ref.invalidate(budgetsListProvider),
              child: budgetsAsync.when(
                data: (budgets) {
                  if (budgets.isEmpty) {
                    return BudgetsEmptyState(onCopyBudgets: _handleCopyBudgets);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: budgets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = budgets[index];
                      return BudgetItemCard(
                        budget: item,
                        onDelete: () => _confirmDeleteBudget(item),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Lỗi tải ngân sách: $e', style: const TextStyle(color: AppColors.expense))),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Thêm ngân sách mới',
        child: FloatingActionButton(
          tooltip: 'Thêm ngân sách mới',
          backgroundColor: AppColors.primary,
          foregroundColor: const Color(0xFF062217),
          elevation: 4,
          onPressed: () => _openCreateBudgetDialog(context),
          child: const Icon(Icons.add_rounded, size: 24),
        ),
      ),
    );
  }
}
