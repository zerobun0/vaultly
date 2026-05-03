import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/database/app_database.dart';
import '../../providers/budget_providers.dart';
import '../../providers/savings_providers.dart';
import '../../providers/transaction_providers.dart';
import 'widgets/budget_progress_tile.dart';
import 'widgets/category_pie_chart.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/recent_transaction_tile.dart';
import 'widgets/summary_card.dart';

// ---------------------------------------------------------------------------
// Period chip definitions
// ---------------------------------------------------------------------------

class _PeriodOption {
  const _PeriodOption(this.label, this.start, this.end);
  final String label;
  final DateTime start;
  final DateTime end;
}

List<_PeriodOption> _buildPeriods() {
  final now = DateTime.now();
  return [
    _PeriodOption(
      'This Month',
      DateTime(now.year, now.month),
      DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999, 999),
    ),
    _PeriodOption(
      'Last Month',
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month, 0, 23, 59, 59, 999, 999),
    ),
    _PeriodOption(
      'Last 3M',
      DateTime(now.year, now.month - 2),
      DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999, 999),
    ),
    _PeriodOption(
      'Last 6M',
      DateTime(now.year, now.month - 5),
      DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999, 999),
    ),
    _PeriodOption(
      'This Year',
      DateTime(now.year),
      DateTime(now.year, 12, 31, 23, 59, 59, 999, 999),
    ),
  ];
}

// ---------------------------------------------------------------------------
// DashboardScreen
// ---------------------------------------------------------------------------

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = _buildPeriods();
    final selectedRange = ref.watch(selectedDateRangeProvider);

    // Find selected chip index by matching start date.
    int selectedIndex = 0;
    for (var i = 0; i < periods.length; i++) {
      if (periods[i].start == selectedRange.start) {
        selectedIndex = i;
        break;
      }
    }

    final totalIncomeAsync = ref.watch(totalIncomeProvider);
    final totalSpendAsync = ref.watch(totalSpendProvider);
    final spendByCategoryAsync = ref.watch(spendByCategoryProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final activeBudgetsAsync = ref.watch(activeBudgetsProvider);
    final savingsGoalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: CustomScrollView(
        slivers: [
          // ----------------------------------------------------------------
          // App bar
          // ----------------------------------------------------------------
          SliverAppBar(
            backgroundColor: AppColors.darkBg,
            surfaceTintColor: Colors.transparent,
            floating: true,
            snap: true,
            title: const Text(
              'Vaultly',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),

          // ----------------------------------------------------------------
          // Period selector chips
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final isSelected = i == selectedIndex;
                  return ChoiceChip(
                    label: Text(periods[i].label),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(selectedDateRangeProvider.notifier).update(
                            DateTimeRange(
                              start: periods[i].start,
                              end: periods[i].end,
                            ),
                          );
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.cardDark,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                  );
                },
              ),
            ).animate().fadeIn(duration: 300.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ----------------------------------------------------------------
          // Summary card
          // ----------------------------------------------------------------
          SliverToBoxAdapter(
            child: _buildSummarySection(totalIncomeAsync, totalSpendAsync)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.06, curve: Curves.easeOut),
          ),

          // ----------------------------------------------------------------
          // Spending by category
          // ----------------------------------------------------------------
          _sectionHeader('Spending by Category'),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: spendByCategoryAsync.when(
                loading: () => const _ShimmerBox(height: 240),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (data) => CategoryPieChart(spendByCategory: data),
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOut),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ----------------------------------------------------------------
          // Monthly spend bar chart
          // ----------------------------------------------------------------
          _sectionHeader('Monthly Spending'),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: transactionsAsync.when(
                loading: () => const _ShimmerBox(height: 200),
                error: (e, _) => _ErrorCard(message: e.toString()),
                data: (txs) => MonthlyBarChart(transactions: txs),
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOut),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ----------------------------------------------------------------
          // Recent transactions
          // ----------------------------------------------------------------
          _sectionHeader('Recent Transactions'),
          transactionsAsync.when(
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    5,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _ShimmerBox(height: 68),
                    ),
                  ),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: _ErrorCard(message: e.toString()),
            ),
            data: (txs) {
              if (txs.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyTransactions(onImport: () => context.push('/import')),
                );
              }
              final recent = txs.take(5).toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => RecentTransactionTile(transaction: recent[i])
                      .animate(delay: (300 + i * 60).ms)
                      .fadeIn(duration: 400.ms),
                  childCount: recent.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ----------------------------------------------------------------
          // Active budgets
          // ----------------------------------------------------------------
          _sectionHeader('Active Budgets'),
          activeBudgetsAsync.when(
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _ShimmerBox(height: 72),
                    ),
                  ),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: _ErrorCard(message: e.toString()),
            ),
            data: (budgets) {
              if (budgets.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextButton.icon(
                      onPressed: () => context.push('/budget'),
                      icon: const Icon(Icons.add_rounded,
                          color: AppColors.primary),
                      label: const Text(
                        'Add budget',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BudgetTileWithSpend(
                    budget: budgets[i],
                    transactionsAsync: transactionsAsync,
                  ),
                  childCount: budgets.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ----------------------------------------------------------------
          // Savings goals
          // ----------------------------------------------------------------
          _sectionHeader('Savings Goals'),
          savingsGoalsAsync.when(
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(
                    2,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _ShimmerBox(height: 96),
                    ),
                  ),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: _ErrorCard(message: e.toString()),
            ),
            data: (goals) {
              if (goals.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No savings goals yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _SavingsGoalCard(goal: goals[i]),
                  childCount: goals.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    AsyncValue<double> incomeAsync,
    AsyncValue<double> spendAsync,
  ) {
    final income = incomeAsync.valueOrNull ?? 0.0;
    final spend = spendAsync.valueOrNull ?? 0.0;
    final isLoading =
        incomeAsync.isLoading || spendAsync.isLoading;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _ShimmerBox(height: 130),
      );
    }

    if (incomeAsync.hasError || spendAsync.hasError) {
      return _ErrorCard(
        message: (incomeAsync.error ?? spendAsync.error).toString(),
      );
    }

    return SummaryCard(totalIncome: income, totalSpend: spend);
  }

  SliverToBoxAdapter _sectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget tile with computed spend from transaction list
// ---------------------------------------------------------------------------

class _BudgetTileWithSpend extends StatelessWidget {
  const _BudgetTileWithSpend({
    required this.budget,
    required this.transactionsAsync,
  });

  final BudgetsTableData budget;
  final AsyncValue<List<TransactionsTableData>> transactionsAsync;

  @override
  Widget build(BuildContext context) {
    final txs = transactionsAsync.valueOrNull ?? [];
    final spent = txs
        .where((t) =>
            !t.isIncome && t.categoryId == budget.categoryId)
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    return BudgetProgressTile(budget: budget, spent: spent);
  }
}

// ---------------------------------------------------------------------------
// Savings goal card
// ---------------------------------------------------------------------------

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({required this.goal});

  final SavingsGoalsTableData goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '£${goal.currentAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                '£${goal.targetAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state widget
// ---------------------------------------------------------------------------

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded,
              size: 48, color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'No transactions yet.\nImport a CSV to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder
// ---------------------------------------------------------------------------

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error card
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
