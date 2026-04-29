import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../data/models/discount_card_model.dart';
import '../../core/theme.dart';

class CardDetailScreen extends StatelessWidget {
  final DiscountCardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final textGrey = AppColors.textGrey(brightness);
    final onSurface = colorScheme.onSurface;

    // Безопасный формат: если заданный не подходит – авто‑замена
    final safeFormat = _safeFormat(card.code, card.format);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        iconTheme: IconThemeData(color: onSurface),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(card.storeName, style: TextStyle(color: onSurface)),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Штрих‑код всегда на белом фоне
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: BarcodeWidget(
                    barcode: _mapFormat(safeFormat),
                    data: card.code,
                    width: double.infinity,
                    height: 160,
                    drawText: false,
                    style: const TextStyle(fontSize: 0),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  card.code,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                    color: onSurface,
                  ),
                ),
                if (safeFormat != card.format)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                  ),
                const SizedBox(height: 40),
                Text(
                  'Предъявите штрих‑код на кассе',
                  style: TextStyle(color: textGrey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Подбирает формат, который гарантирует успешный рендер
  String _safeFormat(String code, String desiredFormat) {
    // Если длина цифр 13 → EAN13
    if (code.length == 13 && RegExp(r'^\d{13}$').hasMatch(code)) {
      return 'ean13';
    }
    // Если длина цифр 8 → EAN8
    if (code.length == 8 && RegExp(r'^\d{8}$').hasMatch(code)) {
      return 'ean8';
    }
    // Во всех остальных случаях используем Code128 (он принимает любые символы)
    return 'code128';
  }

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