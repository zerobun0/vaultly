import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../screens/dashboard/dashboard_screen.dart';
import '../screens/income_tax/income_tax_screen.dart';
import '../screens/investments/investments_screen.dart';
import '../screens/savings/savings_screen.dart';
import '../screens/settings/api_key_screen.dart';
import '../screens/budget/budget_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/transactions/import_screen.dart';
import '../screens/transactions/transactions_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/investments',
            builder: (context, state) => const InvestmentsScreen(),
          ),
          GoRoute(
            path: '/savings',
            builder: (context, state) => const SavingsScreen(),
          ),
          GoRoute(
            path: '/tax',
            builder: (context, state) => const IncomeTaxScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'api-key',
            builder: (context, state) => const ApiKeyScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/budget',
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportScreen(),
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const _tabs = [
    ('/', Icons.dashboard_rounded, 'Dashboard'),
    ('/transactions', Icons.receipt_long_rounded, 'Transactions'),
    ('/investments', Icons.show_chart_rounded, 'Investments'),
    ('/savings', Icons.savings_rounded, 'Savings'),
    ('/tax', Icons.calculate_rounded, 'Tax'),
  ];

  int _locationToIndex(String location) {
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (location.startsWith(_tabs[i].$1)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          context.go(_tabs[index].$1);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.$2),
              label: tab.$3,
            ),
        ],
      ),
    );
  }
}
