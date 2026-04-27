import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../core/providers/transaction_provider.dart';
import '../../data/models/category_model.dart';
import '../widgets/neumorphic_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  void _showCategoryDialog({CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (ctx) => _CategoryDialog(
        category: category,
        availableIcons: AppConstants.availableCategoryIcons,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final textGrey = AppColors.textGrey(brightness);
    final onSurfaceColor = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Управление категориями",
          style: TextStyle(
            color: onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: BackButton(color: onSurfaceColor),
        iconTheme: IconThemeData(color: onSurfaceColor),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        onPressed: () => _showCategoryDialog(),
        child: Icon(Icons.add, color: colorScheme.onPrimary),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                borderRadius: 15,
                onTap: () => _showCategoryDialog(category: cat),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurfaceColor,
                            ),
                          ),
                          if (cat.budgetLimit > 0)
                            Text(
                              "Лимит: ${cat.budgetLimit.toStringAsFixed(0)} BYN",
                              style: TextStyle(
                                fontSize: 12,
                                color: textGrey,
                              ),
                            )
                          else
                            Text(
                              "Без лимита",
                              style: TextStyle(
                                fontSize: 12,
                                color: textGrey.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (cat.isDefault)
                      Icon(Icons.lock, size: 16, color: textGrey)
                    else
                      Icon(Icons.edit_rounded, size: 16, color: colorScheme.primary),
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

class _CategoryDialog extends StatefulWidget {
  final CategoryModel? category;
  final List<IconData> availableIcons;

  const _CategoryDialog({this.category, required this.availableIcons});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _limitController;
  late IconData _selectedIcon;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;

    _nameController = TextEditingController(text: cat?.name ?? '');

    final limit = cat?.budgetLimit ?? 0.0;
    _limitController = TextEditingController(
      text: limit > 0 ? limit.toStringAsFixed(0) : '',
    );

    _selectedIcon = cat != null
        ? IconData(cat.iconCode, fontFamily: 'MaterialIcons')
        : widget.availableIcons[0];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    final limitText = _limitController.text.trim();
    double limit = 0.0;

    if (limitText.isNotEmpty) {
      limit = double.tryParse(limitText) ?? 0.0;
    }

    if (name.isNotEmpty) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);

      if (_isEditing) {
        final updatedCat = CategoryModel(
          id: widget.category!.id,
          name: name,
          iconCode: _selectedIcon.codePoint,
          isDefault: widget.category!.isDefault,
          budgetLimit: limit,
        );
        provider.updateCategory(updatedCat);
      } else {
        provider.addCategory(name, _selectedIcon.codePoint, limit);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final textGrey = AppColors.textGrey(brightness);
    final inputFillColor = brightness == Brightness.light ? Colors.white : Colors.grey[850]!;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _isEditing ? "Редактировать" : "Новая категория",
        style: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Название",
              style: TextStyle(
                fontSize: 12,
                color: textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: "Например: Еда",
                hintStyle: TextStyle(color: textGrey.withValues(alpha: 0.5)),
                filled: true,
                fillColor: inputFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Месячный бюджет (BYN)",
              style: TextStyle(
                fontSize: 12,
                color: textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _limitController,
              style: TextStyle(color: colorScheme.onSurface),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "0 - без лимита",
                hintStyle: TextStyle(color: textGrey.withValues(alpha: 0.5)),
                filled: true,
                fillColor: inputFillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(
                  Icons.attach_money,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Выберите иконку:",
              style: TextStyle(
                color: textGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: widget.availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = widget.availableIcons[index];
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryMint : inputFillColor,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryMint.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? Colors.white : textGrey,
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
          child: Text(
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
          onPressed: _saveCategory,
          child: Text(
            _isEditing ? "Сохранить" : "Создать",
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}