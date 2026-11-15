import 'package:expense_tracker_frontend/providers/auth_provider.dart';
import 'package:expense_tracker_frontend/views/auth/login_view.dart';
import 'package:expense_tracker_frontend/views/auth/register_view.dart';
import 'package:expense_tracker_frontend/views/budgets/budgets_view.dart';
import 'package:expense_tracker_frontend/views/dashboard/dashboard_view.dart';
import 'package:expense_tracker_frontend/views/reports/reports_view.dart';
import 'package:expense_tracker_frontend/views/shell_scaffold.dart';
import 'package:expense_tracker_frontend/views/transactions/transactions_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      if (authState.isLoading) {
        return null;
      }

      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!authState.isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return ShellScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardView(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsView(),
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsView(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsView(),
          ),
        ],
      ),
    ],
  );
});
