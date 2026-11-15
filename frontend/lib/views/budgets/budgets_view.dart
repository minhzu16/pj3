import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/budget_model.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/providers/budget_provider.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

  String _formatCurrency(Decimal amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount.toDouble());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'exceeded':
        return AppColors.expense;
      case 'warning':
        return AppColors.warning;
      case 'safe':
      default:
        return AppColors.income;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'exceeded':
        return 'Vượt hạn mức';
      case 'warning':
        return 'Sắp chạm ngưỡng';
      case 'safe':
      default:
        return 'Trong tầm kiểm soát';
    }
  }

  void _openCreateBudgetDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateBudgetModal(
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
    final monthFormat = DateFormat('MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Kế Hoạch Ngân Sách',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
          // Month Selector Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 22),
                    onPressed: () => _changeMonth(-1),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        'Tháng ${monthFormat.format(_currentMonthDate)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 22),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
          ),

          // Budgets List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              onRefresh: () async => ref.invalidate(budgetsListProvider),
              child: budgetsAsync.when(
                data: (budgets) {
                  if (budgets.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.savings_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.6)),
                              const SizedBox(height: 16),
                              const Text(
                                'Chưa có ngân sách cho tháng này',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Thiết lập hạn mức hoặc sao chép từ tháng trước để giữ kỷ luật chi tiêu',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryLight,
                                  side: const BorderSide(color: AppColors.cardBorder),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Sao chép từ tháng trước'),
                                onPressed: _handleCopyBudgets,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: budgets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = budgets[index];
                      final statusColor = _getStatusColor(item.status);
                      final statusText = _getStatusText(item.status);
                      final progressVal = (item.percent.toDouble() / 100.0).clamp(0.0, 1.0);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.status == 'exceeded' ? AppColors.expense.withValues(alpha: 0.4) : AppColors.cardBorder,
                            width: 0.8,
                          ),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.categoryName,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _confirmDeleteBudget(item),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Progress Track
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressVal,
                                minHeight: 7,
                                backgroundColor: AppColors.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Figures Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Đã dùng', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(item.spent),
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text('Tiến độ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.percent}% / ${item.alertThreshold}%',
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Hạn mức', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(item.amountLimit),
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF062217),
        elevation: 4,
        onPressed: () => _openCreateBudgetDialog(context),
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }
}

class _CreateBudgetModal extends ConsumerStatefulWidget {
  final String monthStr;

  const _CreateBudgetModal({required this.monthStr});

  @override
  ConsumerState<_CreateBudgetModal> createState() => _CreateBudgetModalState();
}

class _CreateBudgetModalState extends ConsumerState<_CreateBudgetModal> {
  final _amountController = TextEditingController();
  CategoryModel? _selectedCategory;
  double _threshold = 80.0;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountVal = Decimal.tryParse(_amountController.text.replaceAll(',', ''));
    if (amountVal == null || amountVal <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập hạn mức hợp lệ (> 0)')),
      );
      return;
    }

    try {
      await ref.read(budgetActionProvider).createBudget(
            categoryId: _selectedCategory?.id,
            month: widget.monthStr,
            amountLimit: amountVal,
            alertThreshold: _threshold.round(),
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu hạn mức ngân sách!')),
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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thiết lập ngân sách',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18),

          categoriesAsync.when(
            data: (cats) {
              final expenseCategories = cats.where((c) => c.type == 'expense').toList();
              return DropdownButtonFormField<CategoryModel?>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Hạng mục áp dụng'),
                dropdownColor: AppColors.surfaceElevated,
                items: [
                  const DropdownMenuItem<CategoryModel?>(
                    value: null,
                    child: Text('Toàn bộ chi tiêu (Tổng ngân sách)', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600)),
                  ),
                  ...expenseCategories.map((c) {
                    return DropdownMenuItem<CategoryModel?>(
                      value: c,
                      child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
                    );
                  }),
                ],
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              );
            },
            loading: () => const LinearProgressIndicator(color: AppColors.primary),
            error: (_, _) => const Text('Lỗi tải danh mục', style: TextStyle(color: AppColors.expense)),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Hạn mức cho phép (VND)',
              prefixIcon: Icon(Icons.attach_money_rounded, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ngưỡng cảnh báo sớm:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('${_threshold.round()}%', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          Slider(
            value: _threshold,
            min: 50.0,
            max: 100.0,
            divisions: 10,
            activeColor: AppColors.warning,
            inactiveColor: AppColors.surfaceVariant,
            label: '${_threshold.round()}%',
            onChanged: (val) => setState(() => _threshold = val),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _submit,
            child: const Text('Lưu ngân sách'),
          ),
        ],
      ),
    );
  }
}
