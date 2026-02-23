import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart'; // <--- ДОБАВИЛИ
import '../../core/theme.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late ConfettiController _confettiController; // <--- КОНТРОЛЛЕР САЛЮТА

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const Scaffold(body: Center(child: Text("Раздел Кошелек в разработке"))),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Инициализируем салют (будет длиться 2 секунды)
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _onAddTapped() async {
    // Ждем результат закрытия шторки
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );

    // Если вернулся true (добавили доход) -> запускаем праздник
    if (result == true) {
      setState(() => _currentIndex = 0); // Переключаем на главную, чтобы видеть баланс
      _confettiController.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 👇 ИСПОЛЬЗУЕМ STACK ДЛЯ НАЛОЖЕНИЯ САЛЮТА ПОВЕРХ ЭКРАНОВ
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          // 👇 САМ ВИДЖЕТ КОНФЕТТИ
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2, // Направление: вниз
            maxBlastForce: 15, // Сила выстрела
            minBlastForce: 5,
            emissionFrequency: 0.05, // Плотность
            numberOfParticles: 20, // Количество частиц
            gravity: 0.2,
            colors: const [
              AppColors.primaryMint,
              Colors.blue,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home_rounded),
                _buildNavItem(1, Icons.pie_chart_rounded),
                const SizedBox(width: 55),
                _buildNavItem(2, Icons.account_balance_wallet_rounded),
                _buildNavItem(3, Icons.settings_rounded),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: _onAddTapped,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryMint,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMint.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.textDark : AppColors.textGrey.withValues(alpha: 0.5),
            size: 28,
          ),
          const SizedBox(height: 5),
          if (isSelected)
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.secondarySalmon,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }
}