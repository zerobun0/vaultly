import 'dart:math';

import '../../core/constants/tax_constants.dart';

class TaxBreakdown {
  const TaxBreakdown({
    required this.grossSalaryIncome,
    required this.grossDividendIncome,
    required this.salaryTaxableIncome,
    required this.dividendTaxableIncome,
    required this.incomeTax,
    required this.nationalInsurance,
    required this.dividendTax,
    required this.totalTax,
  });

  final double grossSalaryIncome;
  final double grossDividendIncome;
  final double salaryTaxableIncome;
  final double dividendTaxableIncome;
  final double incomeTax;
  final double nationalInsurance;
  final double dividendTax;
  final double totalTax;

  double get grossIncome => grossSalaryIncome + grossDividendIncome;

  double get totalTaxableIncome => salaryTaxableIncome + dividendTaxableIncome;

  double get netIncome => grossIncome - totalTax;
}

class TaxCalculator {
  const TaxCalculator();

  TaxBreakdown calculate({
    required double salaryIncome,
    double dividendIncome = 0,
  }) {
    final normalizedSalary = max(0.0, salaryIncome);
    final normalizedDividends = max(0.0, dividendIncome);

    final salaryTaxableIncome = max(
      0.0,
      normalizedSalary - TaxConstants.personalAllowance,
    );
    final incomeTax = _calculateIncomeTax(salaryTaxableIncome);
    final nationalInsurance = _calculateNationalInsurance(normalizedSalary);

    final remainingPersonalAllowance = max(
      0.0,
      TaxConstants.personalAllowance - normalizedSalary,
    );
    final dividendAfterPersonalAllowance = max(
      0.0,
      normalizedDividends - remainingPersonalAllowance,
    );
    final dividendTaxableIncome = max(
      0.0,
      dividendAfterPersonalAllowance - TaxConstants.dividendAllowance,
    );
    final dividendTax = _calculateDividendTax(
      dividendTaxableIncome,
      salaryTaxableIncome,
    );

    final totalTax = incomeTax + nationalInsurance + dividendTax;

    return TaxBreakdown(
      grossSalaryIncome: normalizedSalary,
      grossDividendIncome: normalizedDividends,
      salaryTaxableIncome: salaryTaxableIncome,
      dividendTaxableIncome: dividendTaxableIncome,
      incomeTax: incomeTax,
      nationalInsurance: nationalInsurance,
      dividendTax: dividendTax,
      totalTax: totalTax,
    );
  }

  double _calculateIncomeTax(double taxableSalaryIncome) {
    final basicBand = min(taxableSalaryIncome, TaxConstants.basicRateBandWidth).toDouble();
    final higherBand = min(
      max(0, taxableSalaryIncome - TaxConstants.basicRateBandWidth),
      TaxConstants.higherRateBandWidth,
    ).toDouble();
    final additionalBand = max(
      0.0,
      taxableSalaryIncome - TaxConstants.basicRateBandWidth -
          TaxConstants.higherRateBandWidth,
    );

    return (basicBand * TaxConstants.basicRate) +
        (higherBand * TaxConstants.higherRate) +
        (additionalBand * TaxConstants.additionalRate);
  }

  double _calculateNationalInsurance(double salaryIncome) {
    if (salaryIncome <= TaxConstants.niPrimaryThreshold) {
      return 0;
    }

    final mainBandIncome = min(
      salaryIncome,
      TaxConstants.niUpperThreshold,
    ) -
        TaxConstants.niPrimaryThreshold;
    final upperBandIncome = max(0.0, salaryIncome - TaxConstants.niUpperThreshold);

    return (mainBandIncome * TaxConstants.niMainRate) +
        (upperBandIncome * TaxConstants.niUpperRate);
  }

  double _calculateDividendTax(
    double taxableDividendIncome,
    double taxableSalaryIncome,
  ) {
    if (taxableDividendIncome <= 0) {
      return 0;
    }

    final basicBandRemaining = max(
      0.0,
      TaxConstants.basicRateBandWidth - taxableSalaryIncome,
    );
    final higherBandRemaining = max(
      0.0,
      TaxConstants.higherRateBandWidth - max(0.0, taxableSalaryIncome - TaxConstants.basicRateBandWidth),
    );

    final dividendAtBasicRate = min(taxableDividendIncome, basicBandRemaining).toDouble();
    final dividendAtHigherRate = min(
      max(0, taxableDividendIncome - dividendAtBasicRate),
      higherBandRemaining,
    ).toDouble();
    final dividendAtAdditionalRate = max(
      0.0,
      taxableDividendIncome - dividendAtBasicRate - dividendAtHigherRate,
    );

    return (dividendAtBasicRate * 0.0875) +
        (dividendAtHigherRate * 0.3375) +
        (dividendAtAdditionalRate * 0.3935);
  }
}