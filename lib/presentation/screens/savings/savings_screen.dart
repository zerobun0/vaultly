import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/currency_extensions.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../data/database/app_database.dart';
import '../../providers/savings_providers.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref,
      [SavingsGoalsTableData? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _GoalFormSheet(existing: existing, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openForm(context, ref),
          ),
        ],
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.savings_rounded, size: 64),
                  const SizedBox(height: 16),
                  const Text('No savings goals yet.',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _openForm(context, ref),
                    child: const Text('Add First Goal'),
                  ),
                ],
              ),
            );
          }

          final totalSaved =
              goals.fold<double>(0, (s, g) => s + g.currentAmount);
          final totalTarget =
              goals.fold<double>(0, (s, g) => s + g.targetAmount);
          final overallProgress =
              totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Saved',
                              style: Theme.of(context).textTheme.titleSmall),
                          Text(totalSaved.formatGBP(),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${totalSaved.formatGBP()} of ${totalTarget.formatGBP()}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOut),
              const SizedBox(height: 8),
              ...List.generate(
                goals.length,
                (index) => _SavingsGoalTile(
                  goal: goals[index],
                  onEdit: () => _openForm(context, ref, goals[index]),
                  onAddFunds: () =>
                      _showAddFundsDialog(context, ref, goals[index]),
                  onDelete: () => _delete(context, ref, goals[index]),
                  onMarkDone: () => ref
                      .read(savingsNotifierProvider.notifier)
                      .markCompleted(goals[index].id),
                )
                    .animate(delay: (index * 60).ms)
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.05, curve: Curves.easeOut),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddFundsDialog(
      BuildContext context, WidgetRef ref, SavingsGoalsTableData goal) async {
    final ctrl = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to "${goal.name}"'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              prefixText: '£', labelText: 'Amount to add'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text);
                Navigator.pop(ctx, v);
              },
              child: const Text('Add')),
        ],
      ),
    );
    if (result != null && result > 0) {
      await ref
          .read(savingsNotifierProvider.notifier)
          .updateProgress(goal.id, goal.currentAmount + result);
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, SavingsGoalsTableData goal) async {
    await ref.read(savingsNotifierProvider.notifier).delete(goal.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${goal.name}" deleted')),
      );
    }
  }
}

class _SavingsGoalTile extends StatelessWidget {
  const _SavingsGoalTile({
    required this.goal,
    required this.onEdit,
    required this.onAddFunds,
    required this.onDelete,
    required this.onMarkDone,
  });

  final SavingsGoalsTableData goal;
  final VoidCallback onEdit;
  final VoidCallback onAddFunds;
  final VoidCallback onDelete;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;

    Color barColor;
    if (goal.isCompleted) {
      barColor = Colors.green;
    } else if (progress >= 0.8) {
      barColor = Colors.green;
    } else if (progress >= 0.5) {
      barColor = Colors.orange;
    } else {
      barColor = Theme.of(context).colorScheme.primary;
    }

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.savings_rounded,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(goal.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  if (goal.isCompleted)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                ],
              ),
              if (goal.targetDate != null) ...[
                const SizedBox(height: 4),
                Text('Target: ${goal.targetDate!.formatMedium()}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: barColor,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(goal.currentAmount.formatGBP()),
                  Text(goal.targetAmount.formatGBP(),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: goal.isCompleted ? null : onAddFunds,
                      tooltip: 'Add funds'),
                  IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: onEdit,
                      tooltip: 'Edit'),
                  if (!goal.isCompleted)
                    IconButton(
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        onPressed: onMarkDone,
                        tooltip: 'Mark complete'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalFormSheet extends StatefulWidget {
  const _GoalFormSheet({this.existing, required this.ref});
  final SavingsGoalsTableData? existing;
  final WidgetRef ref;

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _targetDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _targetCtrl.text = e.targetAmount.toStringAsFixed(2);
      _currentCtrl.text = e.currentAmount.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _targetDate = e.targetDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final companion = SavingsGoalsTableCompanion(
      id: widget.existing != null
          ? Value(widget.existing!.id)
          : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      targetAmount:
          Value(double.tryParse(_targetCtrl.text) ?? 0),
      currentAmount:
          Value(double.tryParse(_currentCtrl.text) ?? 0),
      targetDate: Value(_targetDate),
      notes: Value(
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim()),
    );
    await widget.ref
        .read(savingsNotifierProvider.notifier)
        .upsert(companion);
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
            Text(widget.existing == null ? 'New Goal' : 'Edit Goal',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Goal name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _targetCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Target', prefixText: '£'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Enter amount' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _currentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Saved so far', prefixText: '£'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_targetDate == null
                  ? 'No target date'
                  : 'Target: ${_targetDate!.formatMedium()}'),
              trailing: const Icon(Icons.calendar_month_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _targetDate ?? DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365 * 10)),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
