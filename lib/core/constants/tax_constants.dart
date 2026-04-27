abstract final class TaxConstants {
  static const double personalAllowance = 12570.0;
  static const double basicRateLimit = 50270.0;
  static const double higherRateLimit = 125140.0;
  static const double basicRate = 0.20;
  static const double higherRate = 0.40;
  static const double additionalRate = 0.45;
  static const double niMainRate = 0.08;
  static const double niUpperRate = 0.02;
  static const double niPrimaryThreshold = 12570.0;
  static const double niUpperThreshold = 50270.0;
  static const double isaAllowance = 20000.0;
  static const double cgtExemption = 3000.0;
  static const double dividendAllowance = 500.0;

  static const double basicRateBandWidth =
      basicRateLimit - personalAllowance;
  static const double higherRateBandWidth =
      higherRateLimit - basicRateLimit;

  const TaxConstants._();
}