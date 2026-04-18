import 'package:flutter/material.dart';
import '../../data/local/database_service.dart';
import '../../data/models/discount_card_model.dart';

class DiscountCardProvider extends ChangeNotifier {
  List<DiscountCardModel> _cards = [];
  bool _isLoading = false;

  List<DiscountCardModel> get cards => _cards;
  bool get isLoading => _isLoading;

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();
    _cards = await DatabaseService.instance.getAllDiscountCards();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCard(String name, String code, String format, Color color) async {
    final newCard = DiscountCardModel(
      storeName: name,
      code: code,
      format: format,
      color: color.value,
    );
    
    final id = await DatabaseService.instance.createDiscountCard(newCard);
    _cards.add(DiscountCardModel(
      id: id,
      storeName: name,
      code: code,
      format: format,
      color: color.value,
    ));
    notifyListeners();
  }

  Future<void> deleteCard(int id) async {
    await DatabaseService.instance.deleteDiscountCard(id);
    _cards.removeWhere((element) => element.id == id);
    notifyListeners();
  }
}