import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart'; // Нужен для доступа к лимитам
import '../widgets/neumorphic_card.dart';
import '../widgets/spending_chart.dart';
import '../widgets/add_transaction_sheet.dart';
import '../screens/qr_scanner_screen.dart';
import 'categories_screen.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadData();
    });
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + monthsToAdd,
        _selectedDate.day,
      );
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryMint,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _onScanAndAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (result == null) return;

    double? scannedSum;
    DateTime? scannedDate;
    String? scannedCategory;

    try {
      if (result is Map) {
        if (result.containsKey('amount'))
          scannedSum = double.tryParse(result['amount'].toString());
        if (result.containsKey('date'))
          scannedDate = DateTime.tryParse(result['date'].toString());
        if (result.containsKey('category'))
          scannedCategory = result['category'].toString();
      }
    } catch (e) {
      debugPrint("Ошибка парсинга QR: $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        scannedAmount: scannedSum,
        scannedDate: scannedDate,
        scannedCategory: scannedCategory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: "ru_RU",
      name: "BYN",
    );

    List<double> weeklyIncome = List.filled(7, 0.0);
    List<double> weeklyExpense = List.filled(7, 0.0);

    DateTime startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    for (var t in provider.transactions) {
      if (t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(startOfWeek.add(const Duration(days: 8)))) {
        int dayIndex = t.date.weekday - 1;
        if (t.isIncome) {
          weeklyIncome[dayIndex] += t.amount;
        } else {
          weeklyExpense[dayIndex] += t.amount;
        }
      }
    }

    // Фильтруем транзакции за выбранный месяц
    final monthlyTransactions = provider.transactions.where((t) {
      return t.date.year == _selectedDate.year &&
          t.date.month == _selectedDate.month;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildBalanceCard(provider.balance, currencyFormat),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      "Доходы и Расходы",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowDark.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            size: 20,
                            color: AppColors.textGrey,
                          ),
                          onPressed: () => _changeMonth(-1),
                        ),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Row(
                            children: [
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: AppColors.primaryMint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'd MMM yyyy',
                                  'ru',
                                ).format(_selectedDate).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 2),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24),
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.textGrey,
                          ),
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SpendingChart(
                weeklyIncome: weeklyIncome,
                weeklyExpense: weeklyExpense,
              ),

              const SizedBox(height: 30),

              // Список транзакций (Теперь с лимитами!)
              monthlyTransactions.isEmpty
                  ? _buildEmptyState()
                  : _buildGroupedTransactions(monthlyTransactions, provider),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- МЕТОДЫ ---

  String _getStatusMessage(double balance) {
    if (balance >= 1000) return "Финансовая подушка в безопасности! 🦁";
    if (balance > 0) return "Всё под контролем 👌";
    if (balance == 0) return "По нулям. Время заработать! 🔨";
    return "Мы в минусе! Пора экономить 📉";
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Добрый вечер,",
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            Text(
              "Владелец",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        NeumorphicCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 15,
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: AppColors.textDark,
          ),
          onTap: _onScanAndAdd,
        ),
      ],
    );
  }

  Widget _buildBalanceCard(double balance, NumberFormat format) {
    return NeumorphicCard(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 25),
      borderRadius: 30,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const Text(
              "Текущий баланс",
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 15),
            Text(
              format.format(balance),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: balance >= 0
                    ? AppColors.textDark
                    : AppColors.secondarySalmon,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusMessage(balance),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTransactions(
    List<TransactionModel> transactions,
    TransactionProvider provider,
  ) {
    // 1. Группируем по датам
    Map<String, List<TransactionModel>> grouped = {};
    // 2. Считаем суммы по категориям для текущего месяца (для лимитов)
    Map<String, double> categorySpent = {};

    for (var t in transactions) {
      // Группировка по дате
      String dateKey = DateFormat('yyyy-MM-dd').format(t.date);
      if (grouped[dateKey] == null) grouped[dateKey] = [];
      grouped[dateKey]!.add(t);

      // Подсчет трат по категориям (только расходы)
      if (!t.isIncome) {
        categorySpent[t.category] =
            (categorySpent[t.category] ?? 0.0) + t.amount;
      }
    }

    var sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        String dateKey = sortedKeys[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _getDateTitle(dateKey),
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...grouped[dateKey]!.map((t) {
              // Ищем лимит для этой категории
              CategoryModel? catModel;
              try {
                catModel = provider.categories.firstWhere(
                  (c) => c.name == t.category,
                );
              } catch (e) {
                catModel = null;
              }

              // Передаем в виджет потраченную сумму за месяц, если это расход
              double spentInMonth = !t.isIncome
                  ? (categorySpent[t.category] ?? 0.0)
                  : 0.0;

              return _buildDismissibleTransaction(
                t,
                provider,
                catModel,
                spentInMonth,
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _getDateTitle(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));
    if (dateKey == today) return "Сегодня";
    if (dateKey == yesterday) return "Вчера";
    DateTime date = DateTime.parse(dateKey);
    return DateFormat('d MMMM', 'ru').format(date);
  }

  Widget _buildDismissibleTransaction(
    TransactionModel t,
    TransactionProvider provider,
    CategoryModel? categoryModel,
    double spentInMonth,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Dismissible(
        key: ValueKey(t.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.secondarySalmon.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppColors.secondarySalmon,
          ),
        ),
        onDismissed: (_) => provider.deleteTransaction(t.id!),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddTransactionSheet(transaction: t),
            );
          },
          child: _buildTransactionItem(t, categoryModel, spentInMonth),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    TransactionModel t,
    CategoryModel? cat,
    double spent,
  ) {
    IconData icon = Icons.shopping_bag_outlined;
    if (cat != null) icon = IconData(cat.iconCode, fontFamily: 'MaterialIcons');

    // Логика лимитов
    bool showLimit = !t.isIncome && cat != null && cat.budgetLimit > 0;
    double progress = 0.0;
    Color progressColor = AppColors.primaryMint;

    if (showLimit) {
      progress = (spent / cat!.budgetLimit).clamp(0.0, 1.0);
      if (progress >= 1.0)
        progressColor = AppColors.secondarySalmon; // Перерасход
      else if (progress > 0.75)
        progressColor = Colors.orangeAccent; // Опасно
    }

    return NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.textDark, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (t.comment.isNotEmpty)
                      Text(
                        t.comment,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textGrey,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                "${t.isIncome ? '+' : ''}${t.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: t.isIncome
                      ? AppColors.primaryMint
                      : AppColors.secondarySalmon,
                ),
              ),
            ],
          ),

          // ПОЛОСА ЛИМИТА (Если есть)
          if (showLimit) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Лимит: ${cat!.budgetLimit.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  spent > cat.budgetLimit
                      ? "Превышено!"
                      : "${(cat.budgetLimit - spent).toStringAsFixed(0)} ост.",
                  style: TextStyle(
                    fontSize: 10,
                    color: spent > cat.budgetLimit
                        ? AppColors.secondarySalmon
                        : AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Container(
    padding: const EdgeInsets.all(30),
    alignment: Alignment.center,
    child: Column(
      children: const [
        Icon(
          Icons.history_toggle_off_rounded,
          size: 60,
          color: AppColors.textGrey,
        ),
        SizedBox(height: 10),
        Text(
          "В этом месяце операций нет",
          style: TextStyle(color: AppColors.textGrey),
        ),
      ],
    ),
  );
}
