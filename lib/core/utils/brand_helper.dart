class BrandHelper {
  // Имитация базы данных префиксов штрих-кодов.
  // В реальном мире эти данные можно получать с бэкенда.
  static final Map<String, Map<String, dynamic>> _brandDatabase = {
    '200': {'name': 'Лента', 'color': 0xFF003C96, 'logo': '🌻'},
    '460': {'name': 'Пятёрочка', 'color': 0xFFE32636, 'logo': '🍎'},
    '400': {'name': 'Adidas', 'color': 0xFF000000, 'logo': '👟'},
    '210': {'name': 'Спортмастер', 'color': 0xFF0066B3, 'logo': '⚽'},
    '220': {'name': 'М.Видео', 'color': 0xFFE21A1A, 'logo': '📺'},
    // Можно добавлять свои префиксы
  };

  /// Метод проверяет штрих-код и возвращает данные бренда, если нашел совпадение
  static Map<String, dynamic>? identifyBrand(String barcode) {
    for (var prefix in _brandDatabase.keys) {
      if (barcode.startsWith(prefix)) {
        return _brandDatabase[prefix];
      }
    }
    return null; // Если бренд неизвестен
  }
}