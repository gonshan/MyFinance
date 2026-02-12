import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для настройки статус бара
import 'package:google_fonts/google_fonts.dart'; // Шрифты
import 'package:provider/provider.dart'; // Управление состоянием

// Импорты наших файлов
import 'core/theme.dart';
import 'core/providers/transaction_provider.dart';
import 'presentation/screens/pin_screen.dart'; // Экран ввода PIN-кода

void main() {
  // Обязательно вызываем это перед использованием системных каналов (SystemChrome)
  WidgetsFlutterBinding.ensureInitialized();

  // Настраиваем прозрачный статус бар (верхняя полоска с часами),
  // чтобы фон приложения заходил под него.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Прозрачный фон
      statusBarIconBrightness: Brightness.dark, // Темные иконки (часы, заряд)
    ),
  );

  // Запускаем приложение
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider позволяет "раздавать" данные (транзакции, баланс)
    // на любой экран приложения.
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TransactionProvider())],
      child: MaterialApp(
        title: 'MyFinance',
        debugShowCheckedModeBanner: false, // Убираем красную ленточку DEBUG
        // Настройка глобальной темы
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background, // Наш фирменный фон
          primaryColor: AppColors.primaryMint,
          // Применяем шрифт Nunito ко всем текстовым стилям
          textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
          useMaterial3: true, // Используем современный Material 3
        ),

        // ВАЖНО: Точка входа в приложение — Экран PIN-кода
        // Если PIN не задан — предложит создать. Если задан — попросит ввести.
        home: const PinScreen(),
      ),
    );
  }
}
