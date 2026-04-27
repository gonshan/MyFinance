import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/app_state.dart';               // импорт вместо main.dart
import '../../core/services/notification_service.dart';
import '../../core/providers/transaction_provider.dart';
import '../widgets/neumorphic_card.dart';
import 'categories_screen.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _useBiometrics = false;
  bool _canCheckBiometrics = false;
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = LocalAuthentication();
    bool canCheck = false;
    try {
      canCheck = await auth.canCheckBiometrics && await auth.isDeviceSupported();
    } catch (_) {}
    final int hour = prefs.getInt('notification_hour') ?? 20;
    final int minute = prefs.getInt('notification_minute') ?? 0;
    final bool darkMode = prefs.getBool('dark_mode') ?? false;

    setState(() {
      _useBiometrics = prefs.getBool('use_biometrics') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _canCheckBiometrics = canCheck;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
      _isDarkMode = darkMode;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometrics', value);
    setState(() => _useBiometrics = value);
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
    if (value) {
      await NotificationService().scheduleDailyNotification(_notificationTime.hour, _notificationTime.minute);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Напоминание включено на ${_formatTime(_notificationTime)}")),
        );
      }
    } else {
      await NotificationService().cancelNotifications();
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() => _isDarkMode = value);
    // Вызываем смену темы через глобальный ключ
    myAppKey.currentState?.toggleTheme(value);
  }

  void _pickTime() {
    TimeOfDay tempTime = _notificationTime;
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Выберите время", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _notificationTime = tempTime);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('notification_hour', tempTime.hour);
                      await prefs.setInt('notification_minute', tempTime.minute);
                      if (_notificationsEnabled) {
                        await NotificationService().scheduleDailyNotification(tempTime.hour, tempTime.minute);
                      }
                    },
                    child: const Text("Готово", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(brightness: Theme.of(context).brightness),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
                    initialDateTime: DateTime(2023, 1, 1, _notificationTime.hour, _notificationTime.minute),
                    onDateTimeChanged: (DateTime newDateTime) {
                      tempTime = TimeOfDay(hour: newDateTime.hour, minute: newDateTime.minute);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _resetPin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PinScreen()),
      (route) => false,
    );
  }

  void _showResetDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text("Сброс PIN-кода", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Вы уверены? При следующем входе приложение попросит создать новый код."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPin(context);
            },
            child: const Text("Сбросить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, TransactionProvider provider) {
    final currencies = ['BYN', 'USD', 'EUR', 'RUB', 'KZT'];
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text("Выберите валюту", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.map((c) => ListTile(
            title: Text(c),
            trailing: provider.currency == c ? Icon(Icons.check_circle_rounded, color: colorScheme.primary) : null,
            onTap: () {
              provider.updateCurrency(c);
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final provider = Provider.of<TransactionProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final textGrey = AppColors.textGrey(brightness);
    final onSurfaceColor = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Настройки", style: theme.textTheme.headlineMedium?.copyWith(color: onSurfaceColor)),
              const SizedBox(height: 30),
              _buildSectionTitle("Отображение", textGrey),
              _buildSettingsTile(
                icon: Icons.payments_rounded,
                title: "Основная валюта",
                subtitle: provider.currency,
                onTap: () => _showCurrencyDialog(context, provider),
                textGrey: textGrey,
              ),
              _buildSettingsTile(
                icon: Icons.dark_mode_rounded,
                title: "Тёмная тема",
                subtitle: _isDarkMode ? "Включена" : "Выключена",
                trailing: Switch(
                  value: _isDarkMode,
                  activeThumbColor: colorScheme.primary,
                  onChanged: _toggleDarkMode,
                ),
                onTap: () {},
                textGrey: textGrey,
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("Управление", textGrey),
              _buildSettingsTile(
                icon: Icons.category_rounded,
                title: "Категории",
                subtitle: "Добавить или удалить",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen())),
                textGrey: textGrey,
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("Уведомления", textGrey),
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                borderRadius: 20,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: colorScheme.primary, size: 28),
                        const SizedBox(width: 20),
                        Expanded(child: Text("Напоминать о расходах", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurfaceColor))),
                        Switch(value: _notificationsEnabled, activeThumbColor: colorScheme.primary, onChanged: _toggleNotifications),
                      ],
                    ),
                    if (_notificationsEnabled) ...[
                      const Divider(height: 20),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Время напоминания", style: TextStyle(color: textGrey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time_rounded, size: 16, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(_formatTime(_notificationTime), style: TextStyle(fontWeight: FontWeight.bold, color: onSurfaceColor)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("Безопасность", textGrey),
              if (_canCheckBiometrics) ...[
                NeumorphicCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Вход по биометрии", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("FaceID / Отпечаток", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(value: _useBiometrics, activeThumbColor: colorScheme.primary, onChanged: _toggleBiometrics),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],
              _buildSettingsTile(
                icon: Icons.lock_reset_rounded,
                title: "Сбросить PIN-код",
                subtitle: "Придумать новый код доступа",
                isDestructive: true,
                onTap: () => _showResetDialog(context),
                textGrey: textGrey,
              ),
              const SizedBox(height: 15),
              _buildSectionTitle("О приложении", textGrey),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: "Версия",
                subtitle: "1.0.0 (Diploma Release)",
                onTap: () {},
                textGrey: textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textGrey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 10),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textGrey)),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    bool isDestructive = false,
    required Color textGrey,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: NeumorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        borderRadius: 20,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : colorScheme.primary, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDestructive ? Colors.red : colorScheme.onSurface)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: textGrey)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: textGrey),
          ],
        ),
      ),
    );
  }
}