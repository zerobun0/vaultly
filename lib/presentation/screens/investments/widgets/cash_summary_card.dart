import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../data/services/trading212_service.dart';

class CashSummaryCard extends StatelessWidget {
  const CashSummaryCard({super.key, required this.cash});

  final T212Cash cash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pplColor =
        cash.ppl >= 0 ? AppColors.success : AppColors.danger;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Summary',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Free Cash', value: cash.free.formatGBP()),
            const Divider(height: 16),
            _SummaryRow(label: 'Invested', value: cash.invested.formatGBP()),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Total P&L',
              value: cash.ppl.formatGBP(),
              valueColor: pplColor,
            ),
            const Divider(height: 16),
            _SummaryRow(label: 'Result', value: cash.result.formatGBP()),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
