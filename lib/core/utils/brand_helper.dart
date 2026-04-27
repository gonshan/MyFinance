class BrandHelper {
  static final Map<String, Map<String, dynamic>> _brandDatabase = {
    // Убран дублирующийся ключ '200': оставлен только один
    '200': {'name': 'Лента', 'color': 0xFF003C96, 'logo': '🌻'},
    '460': {'name': 'Пятёрочка', 'color': 0xFFE32636, 'logo': '🍎'},
    '482': {'name': 'Соседи', 'color': 0xFF92C83E, 'logo': '🏠'},
    '481': {'name': 'Виталюр', 'color': 0xFFDA291C, 'logo': '🍏'},
    '487': {'name': 'Евроопт', 'color': 0xFFFFCC00, 'logo': '🛒'},
    '485': {'name': 'Гиппо', 'color': 0xFFE30613, 'logo': '🦛'},
    '246': {'name': 'Санта', 'color': 0xFFED1C24, 'logo': '🎅'},
    '590': {'name': 'Корона', 'color': 0xFF003399, 'logo': '👑'},
    '220': {'name': 'М.Видео', 'color': 0xFFE21A1A, 'logo': '📺'},
    '400': {'name': 'Adidas', 'color': 0xFF000000, 'logo': '👟'},
    '210': {'name': 'Спортмастер', 'color': 0xFF0066B3, 'logo': '⚽'},
    '280': {'name': 'OZ', 'color': 0xFF1C69D4, 'logo': '🛍️'},
    '490': {'name': 'Вкусвилл', 'color': 0xFF77BC1F, 'logo': '🌿'},
    '471': {'name': 'Макдоналдс', 'color': 0xFFFFC72C, 'logo': '🍟'},
  };

  static Map<String, dynamic>? identifyBrand(String barcode) {
    for (var prefix in _brandDatabase.keys) {
      if (barcode.startsWith(prefix)) {
        return _brandDatabase[prefix];
      }
    }
    return null;
  }
}