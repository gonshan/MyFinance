import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../widgets/neumorphic_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int touchedIndex = -1; // Для анимации нажатия на кусок пирога

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    // 1. Подготовка данных
    // Берем только расходы
    final expenses = provider.transactions.where((t) => !t.isIncome).toList();
    
    // Группируем по категориям: {"Еда": 500, "Транспорт": 200}
    Map<String, double> categoryTotals = {};
    double totalExpense = 0;

    for (var t in expenses) {
      if (categoryTotals.containsKey(t.category)) {
        categoryTotals[t.category] = categoryTotals[t.category]! + t.amount;
      } else {
        categoryTotals[t.category] = t.amount;
      }
      totalExpense += t.amount;
    }

    // Сортируем: сверху самые большие траты
    var sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Структура расходов", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 30),

              if (totalExpense == 0)
                _buildEmptyState()
              else ...[
                // --- ДИАГРАММА ---
                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2, // Расстояние между кусками
                          centerSpaceRadius: 60, // Дырка внутри (пончик)
                          sections: _buildChartSections(sortedEntries, totalExpense),
                        ),
                      ),
                      // Текст в центре пончика
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Всего", style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
                            Text(
                              "${totalExpense.toStringAsFixed(0)} BYN",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- СПИСОК (ЛЕГЕНДА) ---
                ...List.generate(sortedEntries.length, (index) {
                  final entry = sortedEntries[index];
                  final percent = (entry.value / totalExpense * 100).toStringAsFixed(1);
                  final color = _getColor(index);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: NeumorphicCard(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      borderRadius: 15,
                      child: Row(
                        children: [
                          // Цветной кружок
                          Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 15),
                          Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text("-${entry.value.toStringAsFixed(2)} BYN", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              Text("$percent%", style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(List<MapEntry<String, double>> data, double total) {
    return List.generate(data.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      final value = data[i].value;
      final color = _getColor(i);

      return PieChartSectionData(
        color: color,
        value: value,
        title: '${(value / total * 100).toStringAsFixed(0)}%', // Проценты внутри куска
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  // Генератор цветов для категорий
  Color _getColor(int index) {
    const colors = [
      AppColors.secondarySalmon,
      AppColors.primaryMint,
      Color(0xFF5E63B6), // Фиолетовый
      Color(0xFFFACD60), // Желтый
      Color(0xFF2AC4E8), // Голубой
      Color(0xFFA3A3A3), // Серый
      Color(0xFFE88D67), // Оранжевый
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.pie_chart_outline, size: 60, color: AppColors.textGrey),
          SizedBox(height: 10),
          Text("Нет данных о расходах", style: TextStyle(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}