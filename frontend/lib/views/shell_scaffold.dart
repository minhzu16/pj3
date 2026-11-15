import 'package:expense_tracker_frontend/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/reports')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/transactions');
        break;
      case 2:
        context.go('/budgets');
        break;
      case 3:
        context.go('/reports');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            selectedIndex: selectedIndex,
            onDestinationSelected: (idx) => _onItemTapped(idx, context),
            backgroundColor: Colors.transparent,
            indicatorColor: AppColors.primary.withValues(alpha: 0.15),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.space_dashboard_outlined, color: AppColors.textSecondary, size: 22),
                selectedIcon: Icon(Icons.space_dashboard_rounded, color: AppColors.primaryLight, size: 22),
                label: 'Tổng quan',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary, size: 22),
                selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 22),
                label: 'Sổ giao dịch',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary, size: 22),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primaryLight, size: 22),
                label: 'Ngân sách',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined, color: AppColors.textSecondary, size: 22),
                selectedIcon: Icon(Icons.insights_rounded, color: AppColors.primaryLight, size: 22),
                label: 'Phân tích',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
