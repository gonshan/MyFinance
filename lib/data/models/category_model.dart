class CategoryModel {
  final int? id;
  final String name;
  final int iconCode; // Храним код иконки (например, 58234)
  final bool isDefault; // Чтобы нельзя было удалить базовые (по желанию)

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      iconCode: map['iconCode'],
      isDefault: map['isDefault'] == 1,
    );
  }
}