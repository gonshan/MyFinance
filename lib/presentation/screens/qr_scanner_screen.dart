import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // Контроллер камеры
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. САМА КАМЕРА
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // 2. ЗАТЕМНЕНИЕ С ВЫРЕЗОМ (Надежный вариант через CustomPainter)
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),

          // 3. ИНТЕРФЕЙС (Текст и кнопки)
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Кнопка Назад
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Кнопка Фонарика
                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          final isTorchOn = state.torchState == TorchState.on;
                          return IconButton(
                            icon: Icon(
                              isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white
                            ),
                            onPressed: () => controller.toggleTorch(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  "Наведите камеру на QR-код",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Поиск чека...",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),

          // 4. МЯТНАЯ РАМКА ПРИЦЕЛА
          Center(
            child: Container(
              height: 280,
              width: 280,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryMint, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- УМНЫЙ ПАРСЕР ЧЕКОВ ---
  void _processCode(String rawData) {
    setState(() => _isScanned = true);
    Map<String, dynamic> result = {};

    try {
      // 1. Попытка прочитать обычный JSON чека
      final decoded = jsonDecode(rawData);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('s')) result['amount'] = decoded['s'];
        if (decoded.containsKey('sum')) result['amount'] = decoded['sum'];
        if (decoded.containsKey('c')) result['category'] = decoded['c'];
        if (decoded.containsKey('cat')) result['category'] = decoded['cat'];
        if (decoded.containsKey('d')) result['date'] = decoded['d'];
        if (decoded.containsKey('date')) result['date'] = decoded['date'];
      }
    } catch (e) {
      // 2. Умный парсинг официальных фискальных чеков (с параметрами t= и s=)
      
      // Ищем сумму (например, s=120.50 или sum=45)
      final sumMatch = RegExp(r'(?:s|sum)=([0-9]+(?:\.[0-9]{1,2})?)').firstMatch(rawData);
      if (sumMatch != null) {
        result['amount'] = sumMatch.group(1);
      }
      
      // Ищем дату (например, t=20230225T1503)
      final dateMatch = RegExp(r't=([0-9]{8}T[0-9]{4,6})').firstMatch(rawData);
      if (dateMatch != null) {
        try {
          String dateStr = dateMatch.group(1)!; 
          int year = int.parse(dateStr.substring(0, 4));
          int month = int.parse(dateStr.substring(4, 6));
          int day = int.parse(dateStr.substring(6, 8));
          result['date'] = DateTime(year, month, day).toIso8601String();
        } catch (_) {}
      }
      
      // Авто-угадывание категории по тексту ссылки
      final lowerData = rawData.toLowerCase();
      if (lowerData.contains("euroopt") || lowerData.contains("sosedi") || lowerData.contains("green") || lowerData.contains("gippo")) {
         result['category'] = "Еда";
      } else if (lowerData.contains("yandex") || lowerData.contains("taxi") || lowerData.contains("uber")) {
         result['category'] = "Транспорт";
      } else if (lowerData.contains("zara") || lowerData.contains("markformelle") || lowerData.contains("clothes")) {
         result['category'] = "Одежда";
      } else if (lowerData.contains("apteka") || lowerData.contains("pharma") || lowerData.contains("health")) {
         result['category'] = "Здоровье";
      }
    }

    Navigator.pop(context, result.isNotEmpty ? result : null);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

// Художник (CustomPainter) для идеального вырезания прозрачного квадрата
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Темный фон (альфа = 0.7)
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Внешний контур всего экрана
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Внутренний контур (наша "дырка")
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: 280,
            height: 280,
          ),
          const Radius.circular(20),
        ),
      );

    // Вычитаем дырку из фона и рисуем
    final path = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}