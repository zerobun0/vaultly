import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalSpend,
  });

  final double totalIncome;
  final double totalSpend;

  @override
  Widget build(BuildContext context) {
    final net = totalIncome + totalSpend;
    final netColor = net >= 0 ? AppColors.success : AppColors.danger;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.arrow_upward_rounded,
            label: 'Income',
            value: totalIncome,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            icon: Icons.arrow_downward_rounded,
            label: 'Spending',
            value: totalSpend.abs(),
            color: AppColors.danger,
            negate: true,
          ),
          const Divider(height: 24, color: Colors.white12),
          _NetRow(net: net, color: netColor),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.negate = false,
  });

  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool negate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, v, _) {
            return Text(
              v.formatGBP(),
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NetRow extends StatelessWidget {
  const _NetRow({required this.net, required this.color});

  final double net;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Net Balance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: net),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, v, _) {
            return Text(
              v.formatGBPSigned(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
      ],
    );
  }
}
