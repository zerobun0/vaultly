import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../data/database/app_database.dart';
import '../../../providers/savings_providers.dart';

class SavingsGoalTile extends ConsumerWidget {
  const SavingsGoalTile({
    super.key,
    required this.goal,
    required this.onEdit,
  });

  final SavingsGoalsTableData goal;
  final VoidCallback onEdit;

  Color _progressColor(double ratio, bool completed) {
    if (completed || ratio > 0.8) return AppColors.success;
    if (ratio >= 0.5) return AppColors.warning;
    return AppColors.primary;
  }

  Future<void> _showAddFundsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Funds'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Amount to add (£)',
            prefixText: '£',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final added = double.tryParse(controller.text.trim()) ?? 0.0;
      if (added > 0) {
        await ref
            .read(savingsNotifierProvider.notifier)
            .updateProgress(goal.id, goal.currentAmount + added);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio =
        goal.targetAmount > 0 ? goal.currentAmount / goal.targetAmount : 0.0;
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final progressColor = _progressColor(ratio, goal.isCompleted);
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text('Delete "${goal.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(savingsNotifierProvider.notifier).delete(goal.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        progressColor.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.savings_rounded,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (goal.targetDate != null)
                          Text(
                            'Target: ${goal.targetDate!.formatMedium()}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (goal.isCompleted)
                    Chip(
                      label: const Text('Done'),
                      backgroundColor:
                          AppColors.success.withValues(alpha: 0.15),
                      labelStyle:
                          const TextStyle(color: AppColors.success, fontSize: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: clampedRatio,
                  minHeight: 8,
                  color: progressColor,
                  backgroundColor:
                      progressColor.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 8),
              // Amount row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentAmount.formatGBP()} / ${goal.targetAmount.formatGBP()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(clampedRatio * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Add funds',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showAddFundsDialog(context, ref),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Mark done',
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      color: goal.isCompleted
                          ? AppColors.success
                          : null,
                    ),
                    onPressed: goal.isCompleted
                        ? null
                        : () => ref
                            .read(savingsNotifierProvider.notifier)
                            .markCompleted(goal.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
