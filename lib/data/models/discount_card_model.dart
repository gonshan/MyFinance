class DiscountCardFields {
  static const String table = 'discount_cards';
  static const String id = 'id';
  static const String storeName = 'storeName';
  static const String code = 'code';
  static const String format = 'format';
  static const String color = 'color';
}

class DiscountCardModel {
  final int? id;
  final String storeName;
  final String code;
  final String format;
  final int color;

  DiscountCardModel({
    this.id,
    required this.storeName,
    required this.code,
    required this.format,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      DiscountCardFields.id: id,
      DiscountCardFields.storeName: storeName,
      DiscountCardFields.code: code,
      DiscountCardFields.format: format,
      DiscountCardFields.color: color,
    };
  }

  factory DiscountCardModel.fromMap(Map<String, dynamic> map) {
    return DiscountCardModel(
      id: map[DiscountCardFields.id],
      storeName: map[DiscountCardFields.storeName],
      code: map[DiscountCardFields.code],
      format: map[DiscountCardFields.format],
      color: map[DiscountCardFields.color],
    );
  }
}