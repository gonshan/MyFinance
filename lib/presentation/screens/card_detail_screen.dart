import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../data/models/discount_card_model.dart';

class CardDetailScreen extends StatelessWidget {
  final DiscountCardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    // В реальном приложении здесь стоит добавить маппинг стрингового формата в Barcode.type
    final barcodeType = Barcode.code128(); 

    return Scaffold(
      backgroundColor: Colors.white, // Белый фон важен для сканеров на кассе
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(card.storeName, style: const TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BarcodeWidget(
                barcode: barcodeType,
                data: card.code,
                width: double.infinity,
                height: 150,
                drawText: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              const Text('Покажите этот код на кассе', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}