import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

const List<Color> _kPalette = [
  AppColors.primary,
  AppColors.success,
  AppColors.danger,
  AppColors.warning,
  Color(0xFF3498DB),
  Color(0xFF9B59B6),
  Color(0xFF1ABC9C),
  Color(0xFFE67E22),
];

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.spendByCategory});

  final Map<String, double> spendByCategory;

  @override
  Widget build(BuildContext context) {
    if (spendByCategory.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No spending data for this period.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final sorted = spendByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top6 = sorted.take(6).toList();
    final otherTotal = sorted.skip(6).fold(0.0, (sum, e) => sum + e.value);

    final displayEntries = [
      ...top6,
      if (otherTotal > 0) MapEntry('Other', otherTotal),
    ];

    final total = displayEntries.fold(0.0, (sum, e) => sum + e.value);

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < displayEntries.length; i++) {
      final entry = displayEntries[i];
      final color = _kPalette[i % _kPalette.length];
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
            swapAnimationDuration: const Duration(milliseconds: 600),
            swapAnimationCurve: Curves.easeInOut,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < displayEntries.length; i++)
              _LegendItem(
                color: _kPalette[i % _kPalette.length],
                label: displayEntries[i].key,
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
