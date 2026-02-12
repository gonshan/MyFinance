import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_transaction_sheet.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Экраны для навигации
  // 0 - Дом
  // 1 - Аналитика
  // 2 - Кошелек (заглушка)
  // 3 - Настройки
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const Scaffold(body: Center(child: Text("Раздел Кошелек в разработке"))),
    const SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onAddTapped() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // Используем Stack, чтобы поднять кнопку над панелью
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none, // Разрешаем элементам выходить за границы Stack
        alignment: Alignment.bottomCenter,
        children: [
          // Основная панель навигации
          Container(
            height: 80,
            padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Главная
                _buildNavItem(0, Icons.home_rounded),

                // 2. Аналитика
                _buildNavItem(1, Icons.pie_chart_rounded),

                // Пустое место для центральной кнопки
                const SizedBox(width: 55),

                // 3. Кошелек
                _buildNavItem(2, Icons.account_balance_wallet_rounded),

                // 4. Настройки (бывший профиль)
                _buildNavItem(3, Icons.settings_rounded),
              ],
            ),
          ),

          // Приподнятая центральная кнопка ПЛЮС
          Positioned(
            bottom: 30, // Поднимаем кнопку на 30 пикселей вверх
            child: GestureDetector(
              onTap: _onAddTapped,
              child: Container(
                width: 60, // Чуть увеличил размер для акцента
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryMint,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMint.withOpacity(0.4),
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
            color: isSelected ? AppColors.textDark : AppColors.textGrey.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(height: 5),
          // Точка-индикатор только для активного элемента
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
            const SizedBox(height: 5), // Пустое место для выравнивания
        ],
      ),
    );
  }
}