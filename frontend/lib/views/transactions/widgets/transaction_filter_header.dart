import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionFilterHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedType;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onApplyFilters;

  const TransactionFilterHeader({
    super.key,
    required this.searchController,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onApplyFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Tìm theo nội dung ghi chú...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onApplyFilters();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => onApplyFilters(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _FilterPill(
                label: 'Tất cả',
                isSelected: selectedType == null,
                onTap: () => onTypeChanged(null),
              ),
              const SizedBox(width: 8),
              _FilterPill(
                label: 'Chi tiêu',
                isSelected: selectedType == 'expense',
                accentColor: AppColors.expense,
                onTap: () => onTypeChanged('expense'),
              ),
              const SizedBox(width: 8),
              _FilterPill(
                label: 'Thu nhập',
                isSelected: selectedType == 'income',
                accentColor: AppColors.income,
                onTap: () => onTypeChanged('income'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TransactionBalanceRibbon extends StatelessWidget {
  final int totalCount;
  final Decimal totalIncome;
  final Decimal totalExpense;

  const TransactionBalanceRibbon({
    super.key,
    required this.totalCount,
    required this.totalIncome,
    required this.totalExpense,
  });

  String _formatCurrency(Decimal amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$totalCount bản ghi',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Row(
                children: [
                  const Icon(Icons.arrow_downward_rounded, color: AppColors.income, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatCurrency(totalIncome),
                    style: const TextStyle(color: AppColors.income, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatCurrency(totalExpense),
                    style: const TextStyle(color: AppColors.expense, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.5) : AppColors.cardBorder,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (accentColor ?? AppColors.primaryLight) : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
