import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  static final _shortFormatter = DateFormat('d MMM');
  static final _mediumFormatter = DateFormat('d MMM yyyy');
  static final _fullFormatter = DateFormat('d MMMM yyyy');

  /// e.g. "12 Jan"
  String formatShort() => _shortFormatter.format(this);

  /// e.g. "12 Jan 2025"
  String formatMedium() => _mediumFormatter.format(this);

  /// e.g. "12 January 2025"
  String formatFull() => _fullFormatter.format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  DateTime get startOfDay => DateTime(year, month, day);

  DateTime get endOfDay =>
      DateTime(year, month, day, 23, 59, 59, 999, 999);

  DateTime get startOfMonth => DateTime(year, month);

  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999, 999);
}
