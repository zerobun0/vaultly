import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/currency_extensions.dart';
import '../../../../domain/calculators/tax_calculator.dart';
import '../../../../core/constants/tax_constants.dart';

class TaxSummaryCard extends StatelessWidget {
  const TaxSummaryCard({super.key, required this.breakdown});

  final TaxBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    // Derive basic/higher/additional splits from the breakdown.
    final taxableIncome = breakdown.salaryTaxableIncome;
    const basicBandWidth = TaxConstants.basicRateBandWidth;
    const higherBandWidth = TaxConstants.higherRateBandWidth;

    final basicTaxableAmount =
        taxableIncome.clamp(0.0, basicBandWidth);
    final higherTaxableAmount =
        (taxableIncome - basicBandWidth).clamp(0.0, higherBandWidth);
    final additionalTaxableAmount =
        (taxableIncome - basicBandWidth - higherBandWidth).clamp(0.0, double.infinity);

    final basicTax = basicTaxableAmount * TaxConstants.basicRate;
    final higherTax = higherTaxableAmount * TaxConstants.higherRate;
    final additionalTax = additionalTaxableAmount * TaxConstants.additionalRate;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildRow(
            label: 'Gross Income',
            value: breakdown.grossIncome,
            isHeader: true,
          ),
          _buildDivider(),
          _buildRow(
            label: 'Personal Allowance',
            value: TaxConstants.personalAllowance,
            valueColor: AppColors.success,
          ),
          _buildRow(
            label: 'Taxable Income',
            value: breakdown.salaryTaxableIncome,
          ),
          _buildDivider(),
          _buildRow(
            label: 'Basic Rate Tax (20%)',
            value: basicTax,
            valueColor: basicTax > 0 ? AppColors.warning : null,
          ),
          if (higherTax > 0)
            _buildRow(
              label: 'Higher Rate Tax (40%)',
              value: higherTax,
              valueColor: AppColors.danger,
            ),
          if (additionalTax > 0)
            _buildRow(
              label: 'Additional Rate Tax (45%)',
              value: additionalTax,
              valueColor: AppColors.danger,
            ),
          _buildRow(
            label: 'Total Income Tax',
            value: breakdown.incomeTax,
            valueColor: AppColors.danger,
            isBold: true,
          ),
          _buildDivider(),
          _buildRow(
            label: 'NI Main Rate (8%)',
            value: (breakdown.nationalInsurance > 0)
                ? _niMainPart(breakdown.grossSalaryIncome)
                : 0.0,
          ),
          _buildRow(
            label: 'NI Upper Rate (2%)',
            value: (breakdown.nationalInsurance > 0)
                ? _niUpperPart(breakdown.grossSalaryIncome)
                : 0.0,
          ),
          _buildRow(
            label: 'Total NI',
            value: breakdown.nationalInsurance,
            isBold: true,
          ),
          if (breakdown.dividendTax > 0) ...[
            _buildDivider(),
            _buildRow(
              label: 'Dividend Tax',
              value: breakdown.dividendTax,
            ),
          ],
          _buildDivider(),
          _buildRow(
            label: 'Take-Home Pay',
            value: breakdown.netIncome,
            valueColor: AppColors.success,
            isBold: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  double _niMainPart(double salary) {
    final mainBand =
        salary.clamp(TaxConstants.niPrimaryThreshold, TaxConstants.niUpperThreshold) -
            TaxConstants.niPrimaryThreshold;
    return mainBand * TaxConstants.niMainRate;
  }

  double _niUpperPart(double salary) {
    final upperBand =
        (salary - TaxConstants.niUpperThreshold).clamp(0.0, double.infinity);
    return upperBand * TaxConstants.niUpperRate;
  }

  Widget _buildDivider() => const Divider(
        color: Colors.white12,
        height: 1,
        indent: 16,
        endIndent: 16,
      );

  Widget _buildRow({
    required String label,
    required double value,
    Color? valueColor,
    bool isBold = false,
    bool isHeader = false,
    bool isLast = false,
  }) {
    final textColor = valueColor ?? Colors.white;
    final labelColor = isHeader ? Colors.white : Colors.white70;
    final fontSize = isHeader ? 15.0 : 14.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        isHeader ? 16 : 10,
        16,
        isLast ? 16 : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: fontSize,
              fontWeight:
                  isBold || isHeader ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value.formatGBP(),
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight:
                  isBold || isHeader ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
