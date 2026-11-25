import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/budget_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetItemCard extends StatelessWidget {
  final BudgetModel budget;
  final VoidCallback onDelete;

  const BudgetItemCard({
    super.key,
    required this.budget,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(budget.status);
    final statusText = _getStatusText(budget.status);
    final progressVal = (budget.percent.toDouble() / 100.0).clamp(0.0, 1.0);
    final spentFormatted = _formatCurrency(budget.spent);
    final limitFormatted = _formatCurrency(budget.amountLimit);

    return Semantics(
      container: true,
      label:
          'Ngân sách ${budget.categoryName}, $statusText, đã dùng $spentFormatted trên hạn mức $limitFormatted, tiến độ ${budget.percent}% trên ngưỡng ${budget.alertThreshold}%',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: budget.status == 'exceeded'
                ? AppColors.expense.withValues(alpha: 0.4)
                : AppColors.cardBorder,
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
                    budget.categoryName,
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
                Semantics(
                  button: true,
                  label: 'Xoá ngân sách ${budget.categoryName}',
                  child: Tooltip(
                    message: 'Xoá ngân sách',
                    child: InkWell(
                      onTap: onDelete,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress Track
            Semantics(
              label: 'Thanh tiến độ ngân sách đạt ${budget.percent}%',
              excludeSemantics: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Figures Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Semantics(
                  container: true,
                  label: 'Đã dùng: $spentFormatted',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đã dùng', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        spentFormatted,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  container: true,
                  label: 'Tiến độ: ${budget.percent}% trên ngưỡng cảnh báo ${budget.alertThreshold}%',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Tiến độ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '${budget.percent}% / ${budget.alertThreshold}%',
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  container: true,
                  label: 'Hạn mức: $limitFormatted',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Hạn mức', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        limitFormatted,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
