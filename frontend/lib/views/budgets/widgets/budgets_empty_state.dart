import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class BudgetsEmptyState extends StatelessWidget {
  final VoidCallback onCopyBudgets;

  const BudgetsEmptyState({
    super.key,
    required this.onCopyBudgets,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                container: true,
                label: 'Chưa có ngân sách cho tháng này',
                child: Column(
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
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'Sao chép ngân sách từ tháng trước',
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Sao chép từ tháng trước'),
                  onPressed: onCopyBudgets,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
