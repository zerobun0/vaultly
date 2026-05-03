import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/database/app_database.dart';

// Top-level function for compute() isolate.
Map<String, double> _computeMonthlyTotals(List<TransactionsTableData> txs) {
  final now = DateTime.now();
  final result = <String, double>{};
  final monthFmt = DateFormat('MMM yy');

  // Build ordered keys for last 6 months.
  for (var i = 5; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i, 1);
    result[monthFmt.format(d)] = 0.0;
  }

  for (final tx in txs) {
    if (tx.isIncome) continue;
    final key = monthFmt.format(tx.transactionDate);
    if (result.containsKey(key)) {
      result[key] = (result[key] ?? 0) + tx.amount.abs();
    }
  }
  return result;
}

class MonthlyBarChart extends StatefulWidget {
  const MonthlyBarChart({super.key, required this.transactions});

  final List<TransactionsTableData> transactions;

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  Map<String, double>? _monthlyTotals;
  bool _computing = false;

  @override
  void initState() {
    super.initState();
    _recompute(widget.transactions);
  }

  @override
  void didUpdateWidget(MonthlyBarChart old) {
    super.didUpdateWidget(old);
    if (old.transactions != widget.transactions) {
      _recompute(widget.transactions);
    }
  }

  Future<void> _recompute(List<TransactionsTableData> txs) async {
    if (!mounted) return;
    setState(() => _computing = true);
    final result = await compute(_computeMonthlyTotals, txs);
    if (!mounted) return;
    setState(() {
      _monthlyTotals = result;
      _computing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_computing || _monthlyTotals == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final entries = _monthlyTotals!.entries.toList();
    final maxY = entries.fold(0.0, (m, e) => e.value > m ? e.value : m);
    final yMax = maxY > 0 ? (maxY * 1.2).ceilToDouble() : 100.0;

    final barGroups = <BarChartGroupData>[];
    for (var i = 0; i < entries.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value,
              color: AppColors.primary,
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Colors.white12,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    '£${(value / 1000).toStringAsFixed(0)}k',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      entries[idx].key,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '£${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 600),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }
}
