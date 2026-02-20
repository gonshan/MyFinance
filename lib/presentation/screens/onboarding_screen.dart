import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../widgets/neumorphic_card.dart';
import 'pin_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Данные для слайдов
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "Умный учет",
      "desc": "Контролируйте свои доходы и расходы легко и стильно.",
      "icon": Icons.account_balance_wallet_rounded,
      "color": AppColors.primaryMint,
    },
    {
      "title": "Сканер чеков",
      "desc": "Сканируйте QR-коды для мгновенного добавления покупок.",
      "icon": Icons.qr_code_scanner_rounded,
      "color": const Color(0xFF5E63B6), // Красивый фиолетовый
    },
    {
      "title": "Бюджетирование",
      "desc": "Устанавливайте лимиты на категории и избегайте перерасхода.",
      "icon": Icons.pie_chart_rounded,
      "color": AppColors.secondarySalmon,
    },
    {
      "title": "Безопасность",
      "desc": "Ваши финансы под надежной защитой ПИН-кода и биометрии.",
      "icon": Icons.security_rounded,
      "color": const Color(0xFFFACD60), // Теплый желтый
    },
  ];

  // Метод завершения онбординга
  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_run', false); // Запоминаем, что уже показывали

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PinScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Кнопка "Пропустить" в правом верхнем углу
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text("Пропустить", style: TextStyle(color: AppColors.textGrey, fontSize: 16)),
              ),
            ),
            
            // Слайдер
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Круглая неоморфная карточка с иконкой
                        NeumorphicCard(
                          padding: const EdgeInsets.all(40),
                          borderRadius: 100, // Делаем идеальный круг
                          child: Icon(item['icon'], size: 80, color: item['color']),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          item['title'],
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          item['desc'],
                          style: const TextStyle(fontSize: 16, color: AppColors.textGrey, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Нижняя панель: Индикаторы и Кнопка
            Padding(
              padding: const EdgeInsets.all(30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Точки (индикаторы страниц)
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primaryMint : AppColors.textGrey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Кнопка "Далее" / "Начать"
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        _finishOnboarding(); // Если последний слайд - идем дальше
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), 
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? "Начать" : "Далее",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}