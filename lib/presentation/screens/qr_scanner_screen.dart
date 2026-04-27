import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../core/theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); 
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _isScanned = false;
        controller.start();
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
          Positioned.fill(
            child: CustomPaint(
              painter: _ScannerOverlayPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
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

  Future<void> _processCode(String rawData) async {
    setState(() => _isScanned = true);
    Map<String, dynamic> result = {};
    bool recognized = false;

    // 1. Пробуем JSON (некоторые кассы передают JSON напрямую)
    if (rawData.startsWith('{')) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('sum')) {
            result['amount'] = decoded['sum'].toString();
            recognized = true;
          } else if (decoded.containsKey('s')) {
            result['amount'] = decoded['s'].toString();
            recognized = true;
          }
          if (decoded.containsKey('cat')) {
            result['category'] = decoded['cat'].toString();
          } else if (decoded.containsKey('c')) {
            result['category'] = decoded['c'].toString();
          }
          if (decoded.containsKey('date')) {
            result['date'] = decoded['date'].toString();
          } else if (decoded.containsKey('d')) {
            result['date'] = decoded['d'].toString();
          }
        }
      } catch (_) {}
    }

    // 2. Если это ссылка skko.by – запрашиваем HTML и парсим
    if (!recognized && rawData.startsWith('http') && rawData.contains('skko.by')) {
      try {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Загружаем данные чека из СККО...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        final response = await http.get(Uri.parse(rawData));
        if (response.statusCode == 200) {
          var document = parser.parse(response.body);
          
          // Ищем сумму – класс .total-sum или .sum
          var sumElement = document.querySelector('.total-sum') ?? document.querySelector('.sum');
          if (sumElement != null) {
            String sumText = sumElement.text.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
            if (sumText.isNotEmpty) {
              result['amount'] = sumText;
              recognized = true;
            }
          }

          // Ищем дату – обычно .receipt-date или .date
          var dateElement = document.querySelector('.receipt-date') ?? document.querySelector('.date');
          if (dateElement != null) {
            String dateText = dateElement.text.trim();
            DateTime? parsedDate = DateTime.tryParse(dateText);
            if (parsedDate != null) {
              result['date'] = parsedDate.toIso8601String();
            }
          }

          // Ищем название магазина
          var shopElement = document.querySelector('.shop-name') ?? document.querySelector('.organization');
          if (shopElement != null) {
            String shop = shopElement.text.trim();
            result['category'] = _guessCategory(shop);
          }
        }
      } catch (e) {
        debugPrint('Ошибка загрузки СККО: $e');
      }
    }

    // 3. Анализ сырой строки регулярками
    if (!recognized) {
      // Сумма: s=123.45, sum=123.45, total=123.45, amount=123.45, просто число
      final amountPatterns = [
        RegExp(r'(?:s|sum|total|amount)=(\d+(?:[.,]\d{1,2})?)', caseSensitive: false),
        RegExp(r'(?:^|\s)(\d+(?:[.,]\d{1,2}))(?:\s|$)'), // число в начале или в конце
      ];
      for (var pattern in amountPatterns) {
        var match = pattern.firstMatch(rawData);
        if (match != null) {
          result['amount'] = match.group(1)!.replaceAll(',', '.');
          recognized = true;
          break;
        }
      }

      // Дата: t=202410201430 (формат YYYYMMDD) или date=2024-10-20
      final datePatterns = [
        RegExp(r't=(\d{8}T?\d{0,6})'),
        RegExp(r'date=([\d\-]+)'),
      ];
      for (var pattern in datePatterns) {
        var match = pattern.firstMatch(rawData);
        if (match != null) {
          String dateStr = match.group(1)!;
          if (dateStr.length == 8) {
            int y = int.parse(dateStr.substring(0,4));
            int m = int.parse(dateStr.substring(4,6));
            int d = int.parse(dateStr.substring(6,8));
            result['date'] = DateTime(y,m,d).toIso8601String();
            break;
          } else {
            DateTime? parsed = DateTime.tryParse(dateStr);
            if (parsed != null) {
              result['date'] = parsed.toIso8601String();
              break;
            }
          }
        }
      }

      // Категория по ключевым словам магазинов
      final lowerData = rawData.toLowerCase();
      result['category'] = _guessCategory(lowerData);
    }

    // Если сумма не найдена, но есть что-то похожее на число – пробуем найти отдельно
    if (!recognized) {
      final number = RegExp(r'(\d+(?:[.,]\d{2})?)').firstMatch(rawData);
      if (number != null) {
        result['amount'] = number.group(1)!.replaceAll(',', '.');
        recognized = true;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(recognized ? 'Данные чека распознаны' : 'Не удалось извлечь сумму, заполните вручную'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, result);
    }
  }

  /// Угадывает категорию по названию магазина
  String _guessCategory(String text) {
    final t = text.toLowerCase();
    if (t.contains('евроопт') || t.contains('euroopt') ||
        t.contains('соседи') || t.contains('sosedi') ||
        t.contains('гиппо') || t.contains('gippo') ||
        t.contains('green') || t.contains('март') ||
        t.contains('продукты') || t.contains('пятёрочка') ||
        t.contains('лена') || t.contains('виталюр')) {
      return 'Еда';
    }
    if (t.contains('яндекс') || t.contains('yandex') ||
        t.contains('uber') || t.contains('такси') ||
        t.contains('транспорт') || t.contains('автобус')) {
      return 'Транспорт';
    }
    if (t.contains('аптека') || t.contains('pharma') || t.contains('здоровье') ||
        t.contains('apteka')) {
      return 'Здоровье';
    }
    if (t.contains('одежда') || t.contains('zara') || t.contains('марк') ||
        t.contains('clothes') || t.contains('fashion')) {
      return 'Одежда';
    }
    // Если не нашли, возвращаем 'Покупки' по умолчанию
    return 'Покупки';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); 
    controller.dispose();
    super.dispose();
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

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

    final path = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}