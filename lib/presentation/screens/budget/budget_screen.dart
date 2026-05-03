import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/currency_extensions.dart';
import '../../../data/database/app_database.dart';
import '../../providers/budget_providers.dart';
import '../../providers/transaction_providers.dart';

const _kCategories = [
  'groceries', 'transport', 'fuel', 'eating_out', 'subscriptions',
  'utilities', 'shopping', 'health', 'entertainment', 'uncategorized',
];

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref,
      [BudgetsTableData? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BudgetFormSheet(existing: existing, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(activeBudgetsProvider);
    final txAsync = ref.watch(transactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openForm(context, ref),
          ),
        ],
      ),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, size: 64),
                  const SizedBox(height: 16),
                  const Text('No budgets set.',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _openForm(context, ref),
                    child: const Text('Add First Budget'),
                  ),
                ],
              ),
            );
          }

          // Compute spend per category name from transactions
          final txList = txAsync.valueOrNull ?? [];
          final spentByCategory = <String, double>{};
          for (final tx in txList) {
            if (tx.isTransfer) continue;
            if (tx.amount >= 0) continue;
            final cat = tx.description.isNotEmpty ? tx.description : 'uncategorized';
            spentByCategory[cat] =
                (spentByCategory[cat] ?? 0) + tx.amount.abs();
          }

          double totalBudget = 0;
          double totalSpent = 0;
          for (final b in budgets) {
            final catName = b.notes ?? 'uncategorized';
            totalBudget += b.amount;
            totalSpent += spentByCategory[catName] ?? 0;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Period chips
              _PeriodChips(onSelected: (start, end) {
                ref.read(selectedDateRangeProvider.notifier).update(
                    DateTimeRange(start: start, end: end));
              }),
              const SizedBox(height: 12),
              for (final budget in budgets) ...[
                _BudgetTile(
                  budget: budget,
                  spent: spentByCategory[budget.notes ?? 'uncategorized'] ?? 0,
                  onEdit: () => _openForm(context, ref, budget),
                  onDelete: () => _delete(context, ref, budget),
                ),
                const SizedBox(height: 8),
              ],
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${totalSpent.formatGBP()} / ${totalBudget.formatGBP()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: totalSpent > totalBudget ? Colors.red : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, BudgetsTableData budget) async {
    await ref.read(budgetNotifierProvider.notifier).delete(budget.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted')),
      );
    }
  }
}

class _PeriodChips extends StatefulWidget {
  const _PeriodChips({required this.onSelected});
  final void Function(DateTime start, DateTime end) onSelected;

  @override
  State<_PeriodChips> createState() => _PeriodChipsState();
}

class _PeriodChipsState extends State<_PeriodChips> {
  int _selected = 0;

  static final _now = DateTime.now();
  static final _options = [
    ('This Month', DateTime(_now.year, _now.month, 1),
        DateTime(_now.year, _now.month + 1, 0)),
    ('Last Month', DateTime(_now.year, _now.month - 1, 1),
        DateTime(_now.year, _now.month, 0)),
    ('Last 3M', DateTime(_now.year, _now.month - 3, 1), _now),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_options[i].$1),
                selected: _selected == i,
                onSelected: (_) {
                  setState(() => _selected = i);
                  widget.onSelected(_options[i].$2, _options[i].$3);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetsTableData budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress =
        budget.amount > 0 ? (spent / budget.amount).clamp(0.0, double.infinity) : 0.0;
    final barValue = progress.clamp(0.0, 1.0);
    final over = spent > budget.amount;

    Color barColor;
    if (over) {
      barColor = Colors.red;
    } else if (progress >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.green;
    }

    final catName = budget.notes ?? 'uncategorized';

    return Dismissible(
      key: ValueKey(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      catName[0].toUpperCase() +
                          catName.substring(1).replaceAll('_', ' '),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  if (over)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Over budget',
                          style: TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: onEdit),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: barValue,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: barColor,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Spent: ${spent.formatGBP()}'),
                  Text('Budget: ${budget.amount.formatGBP()}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({this.existing, required this.ref});
  final BudgetsTableData? existing;
  final WidgetRef ref;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _amountCtrl = TextEditingController();
  String _category = _kCategories.first;
  String _periodType = 'monthly';
  bool _isActive = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _category = e.notes ?? _kCategories.first;
      _periodType = e.periodType;
      _isActive = e.isActive;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final companion = BudgetsTableCompanion(
      id: widget.existing != null
          ? Value(widget.existing!.id)
          : const Value.absent(),
      categoryId: const Value(0),
      periodType: Value(_periodType),
      amount: Value(double.tryParse(_amountCtrl.text) ?? 0),
      periodStart: Value(DateTime(now.year, now.month, 1)),
      isActive: Value(_isActive),
      notes: Value(_category),
    );
    await widget.ref.read(budgetNotifierProvider.notifier).upsert(companion);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'New Budget' : 'Edit Budget',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final cat in _kCategories)
                  DropdownMenuItem(
                    value: cat,
                    child: Text(
                        cat[0].toUpperCase() +
                            cat.substring(1).replaceAll('_', ' ')),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration:
                  const InputDecoration(labelText: 'Budget amount', prefixText: '£'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Enter amount' : null,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'yearly', label: Text('Yearly')),
              ],
              selected: {_periodType},
              onSelectionChanged: (s) =>
                  setState(() => _periodType = s.first),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
