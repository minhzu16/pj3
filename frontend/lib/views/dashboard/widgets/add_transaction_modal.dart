import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:expense_tracker_frontend/models/category_model.dart';
import 'package:expense_tracker_frontend/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  const AddTransactionModal({super.key});

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';
  CategoryModel? _selectedCategory;
  final DateTime _txnDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amountVal = Decimal.tryParse(_amountController.text.replaceAll(',', ''));
    if (amountVal == null || amountVal <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ (> 0)')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục tương ứng')),
      );
      return;
    }

    try {
      final res = await ref.read(transactionProvider.notifier).addTransaction(
            type: _type,
            amount: amountVal,
            txnDate: _txnDate,
            categoryId: _selectedCategory!.id,
            note: _noteController.text,
          );

      if (mounted) {
        Navigator.pop(context);

        if (res != null && res['budgetAlerts'] != null) {
          final alerts = res['budgetAlerts'] as List;
          if (alerts.isNotEmpty) {
            final alert = alerts.first as Map<String, dynamic>;
            final message = alert['message'] ?? 'Cảnh báo hạn mức!';
            final status = alert['status'];
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: status == 'exceeded' ? AppColors.expense : AppColors.warning,
                content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
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
                  'Ghi nhận giao dịch',
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

          // Flow Segment Pill
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _type == 'expense',
                    label: 'Loại giao dịch Chi tiêu',
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = 'expense';
                        _selectedCategory = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'expense' ? AppColors.surfaceElevated : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: _type == 'expense' ? Border.all(color: AppColors.cardBorder) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Chi tiêu',
                          style: TextStyle(
                            color: _type == 'expense' ? AppColors.expense : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _type == 'income',
                    label: 'Loại giao dịch Thu nhập',
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = 'income';
                        _selectedCategory = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == 'income' ? AppColors.surfaceElevated : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: _type == 'income' ? Border.all(color: AppColors.cardBorder) : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Thu nhập',
                          style: TextStyle(
                            color: _type == 'income' ? AppColors.income : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              labelText: 'Số tiền (VND)',
              prefixIcon: Icon(Icons.payments_outlined, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Category Select
          categoriesAsync.when(
            data: (cats) {
              final filtered = cats.where((c) => c.type == _type).toList();
              return DropdownButtonFormField<CategoryModel>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Hạng mục chi tiêu'),
                dropdownColor: AppColors.surfaceElevated,
                items: filtered.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  );
                }).toList(),
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              );
            },
            loading: () => const LinearProgressIndicator(color: AppColors.primary),
            error: (_, _) => const Text('Không thể tải danh mục', style: TextStyle(color: AppColors.expense)),
          ),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Ghi chú (tuỳ chọn)',
              prefixIcon: Icon(Icons.notes_rounded, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(height: 24),

          Semantics(
            button: true,
            label: 'Lưu giao dịch vào sổ cái',
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Lưu vào sổ cái'),
            ),
          ),
        ],
      ),
    );
  }
}
