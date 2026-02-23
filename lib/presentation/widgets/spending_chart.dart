import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'dart:math';

class SpendingChart extends StatefulWidget {
  final List<double> weeklyIncome;
  final List<double> weeklyExpense;
  final String currency;

  const SpendingChart({
    super.key,
    required this.weeklyIncome,
    required this.weeklyExpense,
    required this.currency,
  });

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    double maxIncome = widget.weeklyIncome.isEmpty
        ? 0
        : widget.weeklyIncome.reduce(max);
    double maxExpense = widget.weeklyExpense.isEmpty
        ? 0
        : widget.weeklyExpense.reduce(max);
    double maxY = max(maxIncome, maxExpense);

    if (maxY < 50) maxY = 50;

    return AspectRatio(
      aspectRatio: 1.8,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              // 👇 ИСПРАВЛЕНИЕ: Используем tooltipBgColor для твоей версии fl_chart
              tooltipBgColor: AppColors.textDark,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String value = rod.toY.toStringAsFixed(2);
                return BarTooltipItem(
                  "$value ${widget.currency}",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    barTouchResponse == null ||
                    barTouchResponse.spot == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: _getBottomTitles,
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.textGrey.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barsSpace: 4,
              barRods: [
                BarChartRodData(
                  toY: widget.weeklyIncome[index],
                  color: AppColors.primaryMint,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: widget.weeklyExpense[index],
                  color: AppColors.secondarySalmon,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.textGrey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'Пн';
        break;
      case 1:
        text = 'Вт';
        break;
      case 2:
        text = 'Ср';
        break;
      case 3:
        text = 'Чт';
        break;
      case 4:
        text = 'Пт';
        break;
      case 5:
        text = 'Сб';
        break;
      case 6:
        text = 'Вс';
        break;
      default:
        text = '';
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(text, style: style),
    );
  }
}
