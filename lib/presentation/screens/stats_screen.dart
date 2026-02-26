import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../widgets/neumorphic_card.dart';
import '../../core/services/pdf_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int touchedIndex = -1; 
  DateTime _selectedDate = DateTime.now();
  bool _isDailyMode = false;

  void _changePeriod(int step) {
    setState(() {
      if (_isDailyMode) {
        _selectedDate = _selectedDate.add(Duration(days: step));
      } else {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + step,
          _selectedDate.day,
        );
      }
    });
  }

  Future<void> _exportToPdf() async {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    final filteredTransactions = provider.transactions.where((t) {
      if (_isDailyMode) {
        return t.date.year == _selectedDate.year && 
               t.date.month == _selectedDate.month &&
               t.date.day == _selectedDate.day;
      } else {
        return t.date.year == _selectedDate.year && 
               t.date.month == _selectedDate.month;
      }
    }).toList();

    if (filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isDailyMode ? "Нет данных за этот день" : "Нет данных за этот месяц")),
      );
      return;
    }

    try {
      await PdfService().generateAndPrintPdf(
        transactions: filteredTransactions,
        date: _selectedDate,
      );
    } catch (e) {
      debugPrint("Ошибка PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ошибка при создании PDF")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    final expenses = provider.transactions.where((t) {
      if (t.isIncome) return false;
      
      if (_isDailyMode) {
        return t.date.year == _selectedDate.year && 
               t.date.month == _selectedDate.month &&
               t.date.day == _selectedDate.day;
      } else {
        return t.date.year == _selectedDate.year && 
               t.date.month == _selectedDate.month;
      }
    }).toList();
    
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

    var sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String dateText = _isDailyMode
        ? DateFormat('d MMMM yyyy', 'ru').format(_selectedDate)
        : DateFormat('LLLL yyyy', 'ru').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Аналитика", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  
                  NeumorphicCard(
                    padding: const EdgeInsets.all(10),
                    borderRadius: 12,
                    onTap: _exportToPdf,
                    child: const Icon(
                      Icons.picture_as_pdf_rounded, 
                      color: AppColors.secondarySalmon, 
                      size: 24
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              NeumorphicCard(
                padding: const EdgeInsets.all(5),
                borderRadius: 15,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isDailyMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isDailyMode ? AppColors.primaryMint : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "За месяц", 
                            style: TextStyle(
                              color: !_isDailyMode ? Colors.white : AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isDailyMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isDailyMode ? AppColors.primaryMint : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "За день", 
                            style: TextStyle(
                              color: _isDailyMode ? Colors.white : AppColors.textGrey,
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              NeumorphicCard(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                borderRadius: 15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textGrey),
                      onPressed: () => _changePeriod(-1),
                    ),
                    Text(
                      dateText.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
                      onPressed: () => _changePeriod(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              if (totalExpense == 0)
                _buildEmptyState()
              else ...[
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
                          sectionsSpace: 2,
                          centerSpaceRadius: 60,
                          sections: _buildChartSections(sortedEntries, totalExpense),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Расход", style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
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
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
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
        title: '${(value / total * 100).toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }

  Color _getColor(int index) {
    const colors = [
      AppColors.secondarySalmon, AppColors.primaryMint, Color(0xFF5E63B6),
      Color(0xFFFACD60), Color(0xFF2AC4E8), Color(0xFFA3A3A3), Color(0xFFE88D67),
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_chart_outlined_rounded, size: 80, color: AppColors.shadowDark),
          const SizedBox(height: 20),
          Text(
            _isDailyMode ? "В этот день трат нет" : "В этом месяце трат нет", 
            style: const TextStyle(color: AppColors.textGrey, fontSize: 16)
          ),
          const Text("Самое время сэкономить! 💰", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}