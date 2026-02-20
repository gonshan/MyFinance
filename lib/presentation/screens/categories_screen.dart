import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../../data/models/category_model.dart';
import '../widgets/neumorphic_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  // Список доступных иконок
  final List<IconData> availableIcons = [
    Icons.fastfood_rounded,
    Icons.directions_bus_rounded,
    Icons.home_rounded,
    Icons.movie_rounded,
    Icons.favorite_rounded,
    Icons.attach_money_rounded,
    Icons.card_giftcard_rounded,
    Icons.shopping_cart_rounded,
    Icons.flight_rounded,
    Icons.pets_rounded,
    Icons.school_rounded,
    Icons.sports_esports_rounded,
    Icons.fitness_center_rounded,
    Icons.local_cafe_rounded,
    Icons.build_rounded,
    Icons.local_gas_station_rounded,
    Icons.local_hospital_rounded,
    Icons.child_friendly_rounded,
  ];

  // Универсальный диалог для СОЗДАНИЯ и РЕДАКТИРОВАНИЯ
  void _showCategoryDialog({CategoryModel? category}) {
    final isEditing = category != null;
    String name = category?.name ?? '';
    double limit = category?.budgetLimit ?? 0.0;
    IconData selectedIcon = category != null
        ? IconData(category.iconCode, fontFamily: 'MaterialIcons')
        : availableIcons[0];

    // Контроллеры для полей
    final nameController = TextEditingController(text: name);
    final limitController = TextEditingController(
      text: limit > 0 ? limit.toStringAsFixed(0) : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isEditing ? "Редактировать" : "Новая категория",
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Имя (Заголовок отдельно)
                const Text(
                  "Название",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Например: Еда",
                    hintStyle: TextStyle(
                      color: AppColors.textGrey.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 20),

                // 2. Лимит бюджета (Заголовок отдельно)
                const Text(
                  "Месячный бюджет (BYN)",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "0 - без лимита",
                    hintStyle: TextStyle(
                      color: AppColors.textGrey.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(
                      Icons.attach_money,
                      color: AppColors.primaryMint,
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isEmpty) {
                      limit = 0.0;
                    } else {
                      limit = double.tryParse(val) ?? 0.0;
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 3. Выбор иконки
                const Text(
                  "Выберите иконку:",
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 150,
                  width: double.maxFinite,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: availableIcons.length,
                    itemBuilder: (context, index) {
                      final icon = availableIcons[index];
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryMint
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primaryMint.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textGrey,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Отмена",
                style: TextStyle(color: AppColors.secondarySalmon),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMint,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () {
                if (name.isNotEmpty) {
                  final provider = Provider.of<TransactionProvider>(
                    context,
                    listen: false,
                  );

                  if (isEditing) {
                    // Обновляем существующую
                    final updatedCat = CategoryModel(
                      id: category.id,
                      name: name,
                      iconCode: selectedIcon.codePoint,
                      isDefault: category.isDefault,
                      budgetLimit: limit,
                    );
                    provider.updateCategory(updatedCat);
                  } else {
                    // Создаем новую
                    provider.addCategory(
                      name,
                      selectedIcon.codePoint,
                      limit,
                    );
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(
                isEditing ? "Сохранить" : "Создать",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        title: const Text(
          "Управление категориями",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: const BackButton(color: AppColors.textDark),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryMint,
        onPressed: () => _showCategoryDialog(), // Вызов диалога для создания
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
                decoration: BoxDecoration(
                  color: AppColors.secondarySalmon,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (cat.isDefault) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Базовые категории нельзя удалить!"),
                    ),
                  );
                  return false;
                }
                return true;
              },
              onDismissed: (_) => provider.deleteCategory(cat.id!),
              child: NeumorphicCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                borderRadius: 15,
                onTap: () => _showCategoryDialog(
                  category: cat,
                ), // ТАП ДЛЯ РЕДАКТИРОВАНИЯ
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          // Показываем лимит, если он задан
                          if (cat.budgetLimit > 0)
                            Text(
                              "Лимит: ${cat.budgetLimit.toStringAsFixed(0)} BYN",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            )
                          else
                            Text(
                              "Без лимита",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (cat.isDefault)
                      const Icon(
                        Icons.lock,
                        size: 16,
                        color: AppColors.textGrey,
                      )
                    else
                      const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.primaryMint,
                      ),
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