import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../data/models/discount_card_model.dart';

class CardDetailScreen extends StatelessWidget {
  final DiscountCardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          card.storeName, 
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      // Исправлено на withValues
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      // ИСХАВЛЕНО: используем card.format вместо barcodeFormat
                      barcode: _mapFormat(card.format),
                      data: card.code,
                      width: double.infinity,
                      height: 160,
                      drawText: false,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      card.code,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Предъявите штрих-код на кассе',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Маппинг строк из базы в типы штрих-кодов библиотеки
  Barcode _mapFormat(String format) {
    switch (format.toLowerCase()) {
      case 'ean13':
        return Barcode.ean13();
      case 'ean8':
        return Barcode.ean8();
      case 'code128':
        return Barcode.code128();
      case 'qr':
        return Barcode.qrCode();
      default:
        return Barcode.code128();
    }
  }
}