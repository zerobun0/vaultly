import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../data/services/trading212_service.dart';

class PortfolioPositionTile extends StatelessWidget {
  const PortfolioPositionTile({super.key, required this.position});

  final T212Position position;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = position.ppl >= 0;
    final pplColor = isPositive ? AppColors.success : AppColors.danger;

    final initials = position.ticker.length >= 2
        ? position.ticker.substring(0, 2).toUpperCase()
        : position.ticker.toUpperCase();

    final pplPct = position.averagePrice > 0
        ? ((position.currentPrice - position.averagePrice) /
                position.averagePrice *
                100)
        : 0.0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        child: Text(
          initials,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        position.ticker,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Qty: ${position.quantity.toStringAsFixed(4)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            position.ppl.formatGBPSigned(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: pplColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${pplPct.toStringAsFixed(2)}%',
            style: theme.textTheme.bodySmall?.copyWith(color: pplColor),
          ),
        ],
      ),
    );
  }
}
