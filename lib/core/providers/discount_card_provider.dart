import 'package:flutter/material.dart';
import '../../data/models/discount_card_model.dart';
import '../../data/local/database_service.dart';

class DiscountCardProvider with ChangeNotifier {
  List<DiscountCardModel> _cards = [];
  bool _isLoading = false;

  List<DiscountCardModel> get cards => _cards;
  bool get isLoading => _isLoading;

  Future<void> loadCards() async {
    _isLoading = true;
    notifyListeners();
    
    // Исправлено: теперь метод называется точно так же, как в DatabaseService
    _cards = await DatabaseService.instance.getAllDiscountCards();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCard(DiscountCardModel card) async {
    await DatabaseService.instance.createDiscountCard(card);
    await loadCards();
  }

  Future<void> deleteCard(int id) async {
    await DatabaseService.instance.deleteDiscountCard(id);
    await loadCards();
  }

  Future<void> updateCard(DiscountCardModel card) async {
    if (card.id != null) {
      await DatabaseService.instance.updateDiscountCard(card);
      await loadCards();
    }
  }
}