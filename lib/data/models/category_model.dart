class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final bool isDefault;
  final double budgetLimit; // <--- НОВОЕ ПОЛЕ

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    this.isDefault = false,
    this.budgetLimit = 0.0, // <--- По умолчанию 0 (без лимита)
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'isDefault': isDefault ? 1 : 0,
      'budgetLimit': budgetLimit, // <--- Добавили
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      iconCode: map['iconCode'],
      isDefault: map['isDefault'] == 1,
      // Если в старой базе нет этого поля, берем 0.0
      budgetLimit: (map['budgetLimit'] as num?)?.toDouble() ?? 0.0, 
    );
  }
}