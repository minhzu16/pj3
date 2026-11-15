import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/v1';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8080/api/v1';
      default:
        return 'http://localhost:8080/api/v1';
    }
  }

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/me';

  // Categories & Payment Methods
  static const String categories = '/categories';
  static const String paymentMethods = '/payment-methods';

  // Transactions
  static const String transactions = '/transactions';
  static const String exportCsv = '/transactions/export.csv';

  // Budgets
  static const String budgets = '/budgets';
  static const String copyBudgets = '/budgets/copy';

  // Recurring
  static const String recurring = '/recurring';
  static const String upcomingRecurring = '/recurring/upcoming';

  // Reports
  static const String reportSummary = '/reports/summary';
  static const String reportByCategory = '/reports/by-category';
  static const String reportMonthlyTrend = '/reports/monthly-trend';
  static const String reportDaily = '/reports/daily';
  static const String reportByPaymentMethod = '/reports/by-payment-method';
}
