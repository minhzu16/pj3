import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/providers/budget_provider.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateBudgetModal extends ConsumerStatefulWidget {
  final String monthStr;

  const CreateBudgetModal({
    super.key,
    required this.monthStr,
  });

  @override
  ConsumerState<CreateBudgetModal> createState() => _CreateBudgetModalState();
}

class _CreateBudgetModalState extends ConsumerState<CreateBudgetModal> {
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
              Semantics(
                header: true,
                child: Text(
                  'Thiết lập ngân sách',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Đóng',
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
                    child: Text(
                      'Toàn bộ chi tiêu (Tổng ngân sách)',
                      style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                    ),
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
              Text(
                '${_threshold.round()}%',
                style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          Semantics(
            label: 'Điều chỉnh ngưỡng cảnh báo sớm, hiện tại ${_threshold.round()}%',
            child: Slider(
              value: _threshold,
              min: 50.0,
              max: 100.0,
              divisions: 10,
              activeColor: AppColors.warning,
              inactiveColor: AppColors.surfaceVariant,
              label: '${_threshold.round()}%',
              onChanged: (val) => setState(() => _threshold = val),
            ),
          ),
          const SizedBox(height: 20),

          Semantics(
            button: true,
            label: 'Lưu hạn mức ngân sách',
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Lưu ngân sách'),
            ),
          ),
        ],
      ),
    );
  }
}
