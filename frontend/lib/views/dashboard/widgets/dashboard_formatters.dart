import 'package:decimal/decimal.dart';
import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatDashboardCurrency(Decimal amount) {
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  return formatter.format(amount.toDouble());
}

Color parseDashboardCategoryColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) return AppColors.primary;
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  final parsed = int.tryParse(buffer.toString(), radix: 16);
  return parsed != null ? Color(parsed) : AppColors.primary;
}
