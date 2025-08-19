// lib/widgets/dashboard/chart_card.dart

import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartCard extends StatefulWidget {
  const ChartCard({Key? key}) : super(key: key);

  @override
  _ChartCardState createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  List<FlSpot> _spots = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _resetData();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _updateData();
      } else {
        timer.cancel();
      }
    });
  }

  void _generateSpots() {
    _spots = List.generate(16, (index) {
      return FlSpot(index.toDouble(), 40 + _random.nextDouble() * 60);
    });
  }

  void _resetData() {
    setState(() {
      _generateSpots();
    });
  }

  void _updateData() {
    setState(() {
      _spots.removeAt(0);
      _spots.add(FlSpot(15, 40 + _random.nextDouble() * 60));
      _spots = _spots
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.y))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biểu đồ xuất/nhập',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                        onPressed: _updateData,
                        child: const Text('Cập nhật',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        onPressed: _resetData,
                        child:
                            const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: isDark ? Colors.white10 : Colors.black12,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 15,
                  minY: 0,
                  maxY: 120,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _spots,
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BFFF), Color(0xFF32CD32)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00BFFF).withOpacity(0.3),
                            const Color(0xFF32CD32).withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}