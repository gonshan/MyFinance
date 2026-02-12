import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../widgets/neumorphic_card.dart';
import '../widgets/spending_chart.dart';
import '../widgets/add_transaction_sheet.dart';
import 'categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency(
      locale: "ru_RU",
      name: "BYN",
    );

    // --- ПОДГОТОВКА ДАННЫХ (ДОХОДЫ И РАСХОДЫ) ---
    List<double> weeklyIncome = List.filled(7, 0.0);
    List<double> weeklyExpense = List.filled(7, 0.0);

    DateTime now = DateTime.now();

    // Определяем начало текущей недели (Понедельник)
    // Чтобы график показывал именно ЭТУ неделю (Пн-Вс)
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    for (var t in provider.transactions) {
      // Проверяем, что дата входит в текущую неделю
      if (t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(startOfWeek.add(const Duration(days: 8)))) {
        int dayIndex = t.date.weekday - 1; // 0..6 (Пн..Вс)

        if (t.isIncome) {
          weeklyIncome[dayIndex] += t.amount;
        } else {
          weeklyExpense[dayIndex] += t.amount;
        }
      }
    }
    // --------------------------------------------------

    return Scaffold(
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

              // Обновленный заголовок
              const Text(
                "Доходы и Расходы",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 20),

              // Наш новый двойной график
              SpendingChart(
                weeklyIncome: weeklyIncome,
                weeklyExpense: weeklyExpense,
              ),

              const SizedBox(height: 30),

              provider.transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildGroupedTransactions(provider),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // --- МЕТОДЫ (Остаются без изменений, копируем для надежности) ---

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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Добрый вечер,", style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
            Text("Владелец", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        // КНОПКА УПРАВЛЕНИЯ КАТЕГОРИЯМИ
        NeumorphicCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 15,
          // Меняем иконку шестеренки на иконку категорий
          child: const Icon(Icons.category_rounded, color: AppColors.textDark), 
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoriesScreen()),
            );
          },
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

  Widget _buildGroupedTransactions(TransactionProvider provider) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var transaction in provider.transactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (grouped[dateKey] == null) grouped[dateKey] = [];
      grouped[dateKey]!.add(transaction);
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
            ...grouped[dateKey]!
                .map((t) => _buildDismissibleTransaction(t, provider))
                .toList(),
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
    return DateFormat('d MMM', 'ru').format(DateTime.parse(dateKey));
  }

  Widget _buildDismissibleTransaction(
    TransactionModel t,
    TransactionProvider provider,
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
            color: AppColors.secondarySalmon.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: AppColors.secondarySalmon,
          ),
        ),
        onDismissed: (_) {
          provider.deleteTransaction(t.id!);
        },
        // Оборачиваем карточку в детектор нажатий
        child: GestureDetector(
          onTap: () {
            // ОТКРЫТИЕ ШТОРКИ РЕДАКТИРОВАНИЯ
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddTransactionSheet(
                transaction: t,
              ), // Теперь здесь не будет ошибки
            );
          },
          child: _buildTransactionItem(t),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    IconData icon;
    switch (t.category) {
      case 'Еда':
        icon = Icons.fastfood_rounded;
        break;
      case 'Транспорт':
        icon = Icons.directions_bus_rounded;
        break;
      case 'Дом':
        icon = Icons.home_rounded;
        break;
      case 'Здоровье':
        icon = Icons.favorite_rounded;
        break;
      case 'Зарплата':
        icon = Icons.attach_money_rounded;
        break;
      case 'Развлечения':
        icon = Icons.movie_rounded;
        break;
      case 'Подарки':
        icon = Icons.card_giftcard_rounded;
        break;
      default:
        icon = Icons.shopping_bag_outlined;
    }
    return NeumorphicCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
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
    );
  }

  Widget _buildEmptyState() => const Center(
    child: Text("Пока пусто", style: TextStyle(color: AppColors.textGrey)),
  );
}
