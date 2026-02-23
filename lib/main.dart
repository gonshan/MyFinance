import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme.dart';
import 'core/providers/transaction_provider.dart';
import 'core/services/notification_service.dart';
import 'presentation/screens/pin_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await NotificationService().init();

  // Проверяем, первый ли это запуск
  final prefs = await SharedPreferences.getInstance();
  final bool isFirstRun = prefs.getBool('is_first_run') ?? true;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(MyApp(isFirstRun: isFirstRun));
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;

  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 👇 ИСПРАВЛЕНИЕ: Вызываем loadData() сразу при создании провайдера
      providers: [
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..loadData(),
        ),
      ],
      child: MaterialApp(
        title: 'MyFinance',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru', 'RU')],
        locale: const Locale('ru', 'RU'),
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.primaryMint,
          textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme),
          useMaterial3: true,
        ),
        home: isFirstRun ? const OnboardingScreen() : const PinScreen(),
      ),
    );
  }
}
