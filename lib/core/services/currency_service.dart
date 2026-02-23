import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrencyRate {
  final String name;
  final double rate;

  CurrencyRate({required this.name, required this.rate});
}

class CurrencyService {
  // Официальный бесплатный API Нацбанка РБ
  static const String _url = 'https://api.nbrb.by/exrates/rates?periodicity=0';

  static Future<List<CurrencyRate>> fetchRates() async {
    try {
      final response = await http.get(Uri.parse(_url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Ищем Доллар (USD) и Евро (EUR)
        final usdData = data.firstWhere((el) => el['Cur_Abbreviation'] == 'USD', orElse: () => null);
        final eurData = data.firstWhere((el) => el['Cur_Abbreviation'] == 'EUR', orElse: () => null);

        List<CurrencyRate> rates = [];
        
        if (usdData != null) {
          rates.add(CurrencyRate(name: 'USD', rate: usdData['Cur_OfficialRate']));
        }
        if (eurData != null) {
          rates.add(CurrencyRate(name: 'EUR', rate: eurData['Cur_OfficialRate']));
        }
        
        return rates;
      }
    } catch (e) {
      debugPrint("Ошибка загрузки курсов валют: $e");
    }
    
    return []; // Если нет интернета - просто вернем пустой список, чтобы не крашнуть приложение
  }
}