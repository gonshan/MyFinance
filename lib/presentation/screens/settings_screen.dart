import 'package:flutter/cupertino.dart'; // <--- НУЖЕН ДЛЯ БАРАБАНА
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../core/services/notification_service.dart';
import '../widgets/neumorphic_card.dart';
import 'categories_screen.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useBiometrics = false;
  bool _canCheckBiometrics = false;
  
  // Уведомления
  bool _notificationsEnabled = false;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 20, minute: 0);

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
    } catch (e) {
      // ignore
    }

    final int hour = prefs.getInt('notification_hour') ?? 20;
    final int minute = prefs.getInt('notification_minute') ?? 0;

    setState(() {
      _useBiometrics = prefs.getBool('use_biometrics') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _canCheckBiometrics = canCheck;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
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
      await NotificationService().scheduleDailyNotification(
        _notificationTime.hour, 
        _notificationTime.minute
      );
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Напоминание включено на ${_formatTime(_notificationTime)}"))
         );
      }
    } else {
      await NotificationService().cancelNotifications();
    }
  }

  // --- НОВЫЙ МЕТОД ВЫБОРА ВРЕМЕНИ (БАРАБАН) ---
  void _pickTime() {
    // Временная переменная, чтобы не менять настройки пока крутишь
    TimeOfDay tempTime = _notificationTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext builder) {
        return Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Заголовок и кнопка Готово
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Выберите время",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context); // Закрываем шторку
                      
                      // Сохраняем результат
                      setState(() => _notificationTime = tempTime);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('notification_hour', tempTime.hour);
                      await prefs.setInt('notification_minute', tempTime.minute);

                      if (_notificationsEnabled) {
                        await NotificationService().scheduleDailyNotification(tempTime.hour, tempTime.minute);
                      }
                    },
                    child: const Text("Готово", style: TextStyle(color: AppColors.primaryMint, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Сам барабан
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(color: AppColors.textDark, fontSize: 22),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true, // 24-часовой формат
                    // Конвертируем TimeOfDay в DateTime для пикера (берем сегодняшнюю дату)
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
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text("Сброс PIN-кода", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Вы уверены? При следующем входе приложение попросит создать новый код."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetPin(context);
            }, 
            child: const Text("Сбросить", style: TextStyle(color: AppColors.secondarySalmon))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Настройки", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 30),

              _buildSectionTitle("Управление"),
              _buildSettingsTile(
                icon: Icons.category_rounded,
                title: "Категории",
                subtitle: "Добавить или удалить",
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen())),
              ),
              const SizedBox(height: 15),

              _buildSectionTitle("Уведомления"),
              NeumorphicCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                borderRadius: 20,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: AppColors.primaryMint, size: 28),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Text("Напоминать о расходах", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          activeColor: AppColors.primaryMint,
                          onChanged: _toggleNotifications,
                        ),
                      ],
                    ),
                    if (_notificationsEnabled) ...[
                      const Divider(height: 20),
                      GestureDetector(
                        onTap: _pickTime, // Клик открывает НОВЫЙ барабан
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Время напоминания", style: TextStyle(color: AppColors.textGrey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primaryMint),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(_notificationTime),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 15),

              _buildSectionTitle("Безопасность"),
              if (_canCheckBiometrics) ...[
                NeumorphicCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, color: AppColors.primaryMint, size: 28),
                      const SizedBox(width: 20),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Вход по биометрии", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            Text("FaceID / Отпечаток", style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _useBiometrics,
                        activeColor: AppColors.primaryMint,
                        onChanged: _toggleBiometrics,
                      ),
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
              ),

              const SizedBox(height: 15),
              _buildSectionTitle("О приложении"),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: "Версия",
                subtitle: "1.0.0 (Diploma Release)",
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 10),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textGrey)),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: NeumorphicCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        borderRadius: 20,
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.secondarySalmon : AppColors.primaryMint, size: 28),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDestructive ? AppColors.secondarySalmon : AppColors.textDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}