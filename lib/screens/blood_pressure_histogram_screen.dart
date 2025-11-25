import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/blood_pressure.dart';

class BloodPressureHistogramScreen extends StatelessWidget {
  final List<BloodPressure> measurements;

  const BloodPressureHistogramScreen({
    super.key,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    final stats = _buildMonthlyStats();
    final breakdownStats = stats.reversed.toList();
    final minPressure = _minPressure(stats);
    final maxPressure = _maxPressure(stats);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text(
            'Blood pressure histogram',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: stats.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChartCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly averages',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 260,
                          child: BarChart(
                            _buildBarChartData(
                              stats,
                              minPressure,
                              maxPressure,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Legend(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly breakdown',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...breakdownStats.map(
                          (stat) => _MonthlyBreakdownRow(stat: stat),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 56,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Add a few measurements\nto see the histogram.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData(
    List<_MonthlyStats> stats,
    double minPressure,
    double maxPressure,
  ) {
    final interval = _pressureAxisInterval(minPressure, maxPressure);
    return BarChartData(
      maxY: maxPressure,
      minY: minPressure,
      barGroups: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return BarChartGroupData(
          x: index,
          barsSpace: 0,
          barRods: [
            BarChartRodData(
              toY: stat.avgSystolic,
              color: _Legend.systolicColor,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(2),
              ),
            ),
            BarChartRodData(
              toY: stat.avgDiastolic,
              color: _Legend.diastolicColor,
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            reservedSize: 36,
            getTitlesWidget: (value, _) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 11),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 44,
            getTitlesWidget: (value, _) {
              final index = value.toInt();
              if (index < 0 || index >= stats.length) {
                return const SizedBox.shrink();
              }
              final stat = stats[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stat.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${stat.measurementCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.black87,
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final stat = stats[groupIndex];
            final label = rodIndex == 0 ? 'Systolic' : 'Diastolic';
            return BarTooltipItem(
              '${stat.label}\n$label: ${rod.toY.toStringAsFixed(0)} mmHg',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
      ),
    );
  }

  List<_MonthlyStats> _buildMonthlyStats() {
    if (measurements.isEmpty) return [];
    final dateFormatter = DateFormat('yyyy-MM');
    final chartLabelFormatter = DateFormat('MMM');
    final fullLabelFormatter = DateFormat('MMM yyyy');
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month - 11, 1);

    final Map<String, List<BloodPressure>> grouped = {};
    for (final measurement in measurements) {
      final key = dateFormatter.format(measurement.timestamp);
      grouped.putIfAbsent(key, () => []).add(measurement);
    }

    var stats = grouped.entries.map((entry) {
      final monthDate = dateFormatter.parse(entry.key);
      final measurementsInMonth = entry.value;
      final totalSystolic =
          measurementsInMonth.fold<int>(0, (sum, m) => sum + m.systolic);
      final totalDiastolic =
          measurementsInMonth.fold<int>(0, (sum, m) => sum + m.diastolic);
      final count = measurementsInMonth.length;
      return _MonthlyStats(
        monthKey: entry.key,
        monthStart: monthDate,
        label: chartLabelFormatter.format(monthDate),
        fullLabel: fullLabelFormatter.format(monthDate),
        avgSystolic: totalSystolic / count,
        avgDiastolic: totalDiastolic / count,
        measurementCount: count,
      );
    }).toList()
      ..sort((a, b) => a.monthKey.compareTo(b.monthKey));

    stats = stats.where((stat) => !stat.monthStart.isBefore(cutoff)).toList();
    if (stats.length > 12) {
      stats = stats.sublist(stats.length - 12);
    }

    return stats;
  }

  double _maxPressure(List<_MonthlyStats> stats) {
    if (stats.isEmpty) return 200;
    final highest =
        stats.map((s) => max(s.avgSystolic, s.avgDiastolic)).reduce(max);
    return highest + 10;
  }

  double _minPressure(List<_MonthlyStats> stats) {
    if (stats.isEmpty) return 0;
    final lowest =
        stats.map((s) => min(s.avgSystolic, s.avgDiastolic)).reduce(min);
    return max(0, lowest - 10);
  }

  double _pressureAxisInterval(double min, double max) {
    final range = (max - min).abs();
    if (range <= 20) return 5;
    if (range <= 60) return 10;
    if (range <= 120) return 20;
    return 40;
  }
}

class _MonthlyBreakdownRow extends StatelessWidget {
  final _MonthlyStats stat;

  const _MonthlyBreakdownRow({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${stat.fullLabel} • ${stat.measurementCount} readings',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          Row(
            children: [
              _PressureChip(
                label: 'SYS',
                value: stat.avgSystolic,
                color: _Legend.systolicColor,
              ),
              const SizedBox(width: 8),
              _PressureChip(
                label: 'DIA',
                value: stat.avgDiastolic,
                color: _Legend.diastolicColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PressureChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PressureChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value.toStringAsFixed(0),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyStats {
  final String monthKey;
  final DateTime monthStart;
  final String label;
  final String fullLabel;
  final double avgSystolic;
  final double avgDiastolic;
  final int measurementCount;

  const _MonthlyStats({
    required this.monthKey,
    required this.monthStart,
    required this.label,
    required this.fullLabel,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.measurementCount,
  });
}

class _ChartCard extends StatelessWidget {
  final Widget child;

  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Legend extends StatelessWidget {
  static const Color systolicColor = Color(0xFF1E88E5);
  static const Color diastolicColor = Color(0xFFFFA726);

  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _LegendItem(
          label: 'Systolic',
          color: systolicColor,
          isLine: false,
        ),
        SizedBox(width: 16),
        _LegendItem(
          label: 'Diastolic',
          color: diastolicColor,
          isLine: false,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLine;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.isLine,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 20 : 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
