import 'package:flutter_test/flutter_test.dart';

import 'package:vaultly/core/constants/tax_constants.dart';
import 'package:vaultly/domain/calculators/tax_calculator.dart';

void main() {
  const calculator = TaxCalculator();

  test('exposes the 2025/26 UK constants', () {
    expect(TaxConstants.personalAllowance, 12570.0);
    expect(TaxConstants.basicRateLimit, 50270.0);
    expect(TaxConstants.higherRateLimit, 125140.0);
    expect(TaxConstants.dividendAllowance, 500.0);
  });

  test('calculates salary-only tax and NI at the basic rate ceiling', () {
    final breakdown = calculator.calculate(salaryIncome: 50270.0);

    expect(breakdown.salaryTaxableIncome, 37700.0);
    expect(breakdown.incomeTax, closeTo(7540.0, 0.0001));
    expect(breakdown.nationalInsurance, closeTo(3016.0, 0.0001));
    expect(breakdown.dividendTax, 0);
    expect(breakdown.totalTax, closeTo(10556.0, 0.0001));
  });

  test('applies the dividend allowance after personal allowance', () {
    final breakdown = calculator.calculate(
      salaryIncome: 12570.0,
      dividendIncome: 1000.0,
    );

    expect(breakdown.salaryTaxableIncome, 0);
    expect(breakdown.incomeTax, 0);
    expect(breakdown.nationalInsurance, 0);
    expect(breakdown.dividendTaxableIncome, 500.0);
    expect(breakdown.dividendTax, closeTo(43.75, 0.0001));
    expect(breakdown.totalTax, closeTo(43.75, 0.0001));
  });
}