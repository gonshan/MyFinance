import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'dart:math';

class SpendingChart extends StatefulWidget {
  final List<double> weeklyIncome;
  final List<double> weeklyExpense;

  const SpendingChart({
    Key? key, 
    required this.weeklyIncome, 
    required this.weeklyExpense
  }) : super(key: key);

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Ищем максимум среди ВСЕХ сумм (и доходов, и расходов), чтобы настроить высоту
    double maxIncome = widget.weeklyIncome.reduce(max);
    double maxExpense = widget.weeklyExpense.reduce(max);
    double maxY = max(maxIncome, maxExpense);

    // Минимальная высота графика (чтобы не был плоским при 0)
    if (maxY < 50) maxY = 50;
    
    return AspectRatio(
      aspectRatio: 1.8,
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2, // +20% воздуха сверху
          minY: 0,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.textDark,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                // Показываем цифру в зависимости от того, какой столбик нажат
                String value = rod.toY.toStringAsFixed(2);
                return BarTooltipItem(
                  "$value BYN",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              color: AppColors.textGrey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          
          // Группы столбиков (по дням)
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barsSpace: 4, // Расстояние между зеленым и красным столбиком
              barRods: [
                // 1. Столбик Дохода (Зеленый)
                BarChartRodData(
                  toY: widget.weeklyIncome[index],
                  color: AppColors.primaryMint,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                // 2. Столбик Расхода (Красный)
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
    const style = TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.bold, fontSize: 12);
    String text;
    switch (value.toInt()) {
      case 0: text = 'Пн'; break;
      case 1: text = 'Вт'; break;
      case 2: text = 'Ср'; break;
      case 3: text = 'Чт'; break;
      case 4: text = 'Пт'; break;
      case 5: text = 'Сб'; break;
      case 6: text = 'Вс'; break;
      default: text = '';
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }
}