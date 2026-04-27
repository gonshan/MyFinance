import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_state.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint("Ошибка уведомлений: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool('is_first_run') ?? true;
  final isDarkMode = prefs.getBool('dark_mode') ?? false;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
    ),
  );

  runApp(MyApp(key: myAppKey, isFirstRun: isFirstRun, initialDarkMode: isDarkMode));
}