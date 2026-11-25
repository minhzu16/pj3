import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BudgetMonthSelector extends StatelessWidget {
  final DateTime currentMonthDate;
  final ValueChanged<int> onChangeMonth;

  const BudgetMonthSelector({
    super.key,
    required this.currentMonthDate,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    final monthFormat = DateFormat('MM/yyyy');
    final formattedMonth = 'Tháng ${monthFormat.format(currentMonthDate)}';

    return Semantics(
      container: true,
      label: 'Thanh chọn tháng ngân sách, hiện tại $formattedMonth',
      child: Container(
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
                tooltip: 'Tháng trước',
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textPrimary, size: 22),
                onPressed: () => onChangeMonth(-1),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Text(
                    formattedMonth,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Tháng sau',
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textPrimary, size: 22),
                onPressed: () => onChangeMonth(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
