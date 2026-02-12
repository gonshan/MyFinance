import 'package:flutter/material.dart';
import 'package:flutter_application_1/presentation/widgets/add_transaction_sheet.dart';
import '../../core/theme.dart';
import '../widgets/neumorphic_card.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Center(child: Text("Analytics")), // Заглушки
    const Center(child: Text("Wallet")),
    const Center(child: Text("Profile")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Важно! Чтобы контент был ПОД прозрачной панелью
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25, left: 20, right: 20),
      child: NeumorphicCard(
        borderRadius: 25,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 0),
            _navItem(Icons.pie_chart_rounded, 1),
            // Центральная кнопка добавления
            // Центральная кнопка добавления
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddTransactionSheet(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                // ВОТ ЗДЕСЬ ВАЖНО:
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryMint, AppColors.primaryMint.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle, // <--- Эта строка делает её круглой!
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryMint.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            _navItem(Icons.account_balance_wallet_rounded, 2),
            _navItem(Icons.person_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.textDark : AppColors.textGrey,
            size: 26,
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: isSelected ? 4 : 0,
            decoration: const BoxDecoration(
              color: AppColors.secondarySalmon, // Акцентная точка
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// Плавающая навигация
