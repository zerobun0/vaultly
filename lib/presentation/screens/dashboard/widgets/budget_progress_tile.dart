import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../data/database/app_database.dart';

class BudgetProgressTile extends StatelessWidget {
  const BudgetProgressTile({
    super.key,
    required this.budget,
    required this.spent,
  });

  final BudgetsTableData budget;
  final double spent;

  @override
  Widget build(BuildContext context) {
    final progress =
        budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.5) : 0.0;
    final pct = progress * 100;

    final Color barColor;
    if (pct >= 100) {
      barColor = AppColors.danger;
    } else if (pct >= 80) {
      barColor = AppColors.warning;
    } else {
      barColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
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
                'Category ${budget.categoryId}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${spent.formatGBP()} / ${budget.amount.formatGBP()}',
                style: TextStyle(
                  color: barColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
