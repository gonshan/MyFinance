class CategoryFields {
  static const String table = 'categories';
  static const String id = 'id';
  static const String name = 'name';
  static const String iconCode = 'iconCode';
  static const String isDefault = 'isDefault';
  static const String budgetLimit = 'budgetLimit';
}

class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final bool isDefault;
  final double budgetLimit;

  CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    this.isDefault = false,
    this.budgetLimit = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      CategoryFields.id: id,
      CategoryFields.name: name,
      CategoryFields.iconCode: iconCode,
      CategoryFields.isDefault: isDefault ? 1 : 0,
      CategoryFields.budgetLimit: budgetLimit,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map[CategoryFields.id],
      name: map[CategoryFields.name],
      iconCode: map[CategoryFields.iconCode],
      isDefault: map[CategoryFields.isDefault] == 1,
      budgetLimit: (map[CategoryFields.budgetLimit] as num?)?.toDouble() ?? 0.0,
    );
  }
}