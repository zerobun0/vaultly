import 'package:intl/intl.dart';

extension CurrencyExtensions on double {
  static final _gbpFormatter = NumberFormat('#,##0.00', 'en_GB');

  /// Formats as GBP, e.g. "£1,234.56"
  String formatGBP() => '£${_gbpFormatter.format(this)}';

  /// Formats as signed GBP, e.g. "+£1,234.56" or "-£1,234.56"
  String formatGBPSigned() {
    if (this >= 0) {
      return '+£${_gbpFormatter.format(this)}';
    } else {
      return '-£${_gbpFormatter.format(abs())}';
    }
  }

  /// Absolute value formatted as GBP, e.g. "£1,234.56"
  String toAbsGBP() => '£${_gbpFormatter.format(abs())}';
}
