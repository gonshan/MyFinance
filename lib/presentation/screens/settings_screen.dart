import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../widgets/neumorphic_card.dart';
import 'categories_screen.dart'; // Экран категорий
import 'pin_screen.dart'; // Экран пин-кода

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _resetPin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin'); // Удаляем пин
    
    // Перекидываем на экран создания пина
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PinScreen()),
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

              // Блок 1: Основное
              _buildSectionTitle("Управление"),
              
              // Кнопка КАТЕГОРИИ
              _buildSettingsTile(
                icon: Icons.category_rounded,
                title: "Категории",
                subtitle: "Добавить или удалить",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                  );
                },
              ),
              
              const SizedBox(height: 15),

              // Блок 2: Безопасность
              _buildSectionTitle("Безопасность"),
              
              // Кнопка СБРОСИТЬ ПИН
              _buildSettingsTile(
                icon: Icons.lock_reset_rounded,
                title: "Сбросить PIN-код",
                subtitle: "Придумать новый код доступа",
                isDestructive: true, // Красный цвет
                onTap: () => _showResetDialog(context),
              ),

              const SizedBox(height: 15),
              
              // Блок 3: О приложении
              _buildSectionTitle("О приложении"),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: "Версия",
                subtitle: "1.0.0 (Diploma Release)",
                onTap: () {}, // Ничего не делает
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
}