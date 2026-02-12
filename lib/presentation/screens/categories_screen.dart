import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../widgets/neumorphic_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Список доступных иконок для выбора
  final List<IconData> availableIcons = [
    Icons.fastfood_rounded, Icons.directions_bus_rounded, Icons.home_rounded,
    Icons.movie_rounded, Icons.favorite_rounded, Icons.attach_money_rounded,
    Icons.card_giftcard_rounded, Icons.shopping_cart_rounded, Icons.flight_rounded,
    Icons.pets_rounded, Icons.school_rounded, Icons.sports_esports_rounded,
    Icons.fitness_center_rounded, Icons.local_cafe_rounded, Icons.build_rounded,
  ];

  void _showAddDialog() {
    String name = '';
    IconData selectedIcon = availableIcons[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text("Новая категория", style: TextStyle(color: AppColors.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Название",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 20),
              const Text("Выберите иконку:", style: TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                width: double.maxFinite,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = availableIcons[index];
                    final isSelected = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryMint : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : AppColors.textGrey, size: 20),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMint),
              onPressed: () {
                if (name.isNotEmpty) {
                  Provider.of<TransactionProvider>(context, listen: false)
                      .addCategory(name, selectedIcon.codePoint);
                  Navigator.pop(context);
                }
              },
              child: const Text("Создать"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Категории", style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        leading: const BackButton(color: AppColors.textDark),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryMint,
        onPressed: _showAddDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: provider.categories.length,
        itemBuilder: (context, index) {
          final cat = provider.categories[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Dismissible(
              key: ValueKey(cat.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: AppColors.secondarySalmon, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (cat.isDefault) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Базовые категории нельзя удалить!")));
                  return false;
                }
                return true;
              },
              onDismissed: (_) => provider.deleteCategory(cat.id!),
              child: NeumorphicCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                borderRadius: 15,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                      child: Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), color: AppColors.textDark),
                    ),
                    const SizedBox(width: 15),
                    Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    if (cat.isDefault) 
                      const Spacer(),
                    if (cat.isDefault)
                      const Icon(Icons.lock, size: 16, color: AppColors.textGrey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}