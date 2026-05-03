import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../domain/calculators/tax_calculator.dart';
import '../../../../core/constants/tax_constants.dart';

class TaxBreakdownChart extends StatelessWidget {
  const TaxBreakdownChart({super.key, required this.breakdown});

  final TaxBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final grossIncome = breakdown.grossIncome;
    if (grossIncome <= 0) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Enter an income to see the breakdown.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    // Derive basic / higher tax slices.
    final taxableIncome = breakdown.salaryTaxableIncome;
    const basicBandWidth = TaxConstants.basicRateBandWidth;
    const higherBandWidth = TaxConstants.higherRateBandWidth;

    final basicTax =
        taxableIncome.clamp(0.0, basicBandWidth) * TaxConstants.basicRate;
    final higherTax =
        (taxableIncome - basicBandWidth).clamp(0.0, higherBandWidth) *
            TaxConstants.higherRate;
    final additionalTax =
        (taxableIncome - basicBandWidth - higherBandWidth)
            .clamp(0.0, double.infinity) *
            TaxConstants.additionalRate;

    final ni = breakdown.nationalInsurance;
    final takeHome = breakdown.netIncome.clamp(0.0, double.infinity);
    final totalTax = basicTax + higherTax + additionalTax + ni + breakdown.dividendTax;

    // Only include sections with a non-zero value.
    final sections = <PieChartSectionData>[
      if (takeHome > 0)
        _section(takeHome, grossIncome, AppColors.success, 'Take-Home'),
      if (basicTax > 0)
        _section(basicTax, grossIncome, AppColors.warning, 'Basic Tax'),
      if (higherTax > 0)
        _section(higherTax, grossIncome, AppColors.danger, 'Higher Tax'),
      if (additionalTax > 0)
        _section(additionalTax, grossIncome, const Color(0xFFB03A2E), 'Add. Tax'),
      if (ni > 0)
        _section(ni, grossIncome, AppColors.primary, 'NI'),
    ];

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              sections: sections,
            ),
            swapAnimationDuration: const Duration(milliseconds: 600),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            takeHome.formatGBP(),
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Take-home pay',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (takeHome > 0)
              _legendItem(AppColors.success, 'Take-Home'),
            if (basicTax > 0)
              _legendItem(AppColors.warning, 'Basic Tax'),
            if (higherTax > 0)
              _legendItem(AppColors.danger, 'Higher Tax'),
            if (additionalTax > 0)
              _legendItem(const Color(0xFFB03A2E), 'Add. Tax'),
            if (ni > 0)
              _legendItem(AppColors.primary, 'NI'),
          ],
        ),
        if (totalTax > 0) ...[
          const SizedBox(height: 8),
          Text(
            'Effective rate: ${(totalTax / grossIncome * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ],
    );
  }

  PieChartSectionData _section(
    double value,
    double total,
    Color color,
    String title,
  ) {
    final pct = (value / total * 100);
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 40,
      title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
