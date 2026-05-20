import 'dart:async';
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

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  final GlobalKey _scaffoldKey = GlobalKey();
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
    returnImage: false,
  );

  bool _isProcessing = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScanWindow());
  }

  void _updateScanWindow() {
    final RenderBox? renderBox =
        _scaffoldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final Size screenSize = renderBox.size;
    const double windowSize = 280;
    final Rect scanWindow = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height / 2),
      width: windowSize,
      height: windowSize,
    );
    controller.updateScanWindow(scanWindow);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isProcessing = false;
        _updateScanWindow();
        controller.start();
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          Positioned.fill(
            child: CustomPaint(painter: _ScannerOverlayPainter()),
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
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          final isTorchOn = state.torchState == TorchState.on;
                          return IconButton(
                            icon: Icon(
                              isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
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
                    fontWeight: FontWeight.bold,
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
    if (_isProcessing) return;
    _isProcessing = true;

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      Map<String, dynamic> result = {};
      bool recognized = false;

      // 1. JSON
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

      // 2. skko.by
      if (!recognized &&
          rawData.startsWith('http') &&
          rawData.contains('skko.by')) {
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
            var sumElement =
                document.querySelector('.total-sum') ??
                document.querySelector('.sum');
            if (sumElement != null) {
              String sumText = sumElement.text
                  .replaceAll(RegExp(r'[^0-9.,]'), '')
                  .replaceAll(',', '.');
              if (sumText.isNotEmpty) {
                result['amount'] = sumText;
                recognized = true;
              }
            }
            var dateElement =
                document.querySelector('.receipt-date') ??
                document.querySelector('.date');
            if (dateElement != null) {
              String dateText = dateElement.text.trim();
              DateTime? parsedDate = DateTime.tryParse(dateText);
              if (parsedDate != null) {
                result['date'] = parsedDate.toIso8601String();
              }
            }
            var shopElement =
                document.querySelector('.shop-name') ??
                document.querySelector('.organization');
            if (shopElement != null) {
              result['category'] = _guessCategory(shopElement.text.trim());
            }
          }
        } catch (e) {
          debugPrint('Ошибка СККО: $e');
        }
      }

      // 3. Текстовый QR – ищем числа с двумя десятичными знаками (копейки)
      if (!recognized) {
        final decimalMatches = RegExp(r'(\d+[.,]\d{2})').allMatches(rawData);
        List<double> candidates = [];
        for (final m in decimalMatches) {
          double val = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0.0;
          if (val > 0 && val < 100000) {
            candidates.add(val);
          }
        }
        if (candidates.isNotEmpty) {
          candidates.sort();
          result['amount'] = candidates.last.toStringAsFixed(2);
          recognized = true;
        }
      }

      // 4. Дата
      if (!recognized) {
        final dateMatch = RegExp(r'(\d{2}\.\d{2}\.\d{4})').firstMatch(rawData);
        if (dateMatch != null) {
          final parts = dateMatch.group(1)!.split('.');
          final date = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
          result['date'] = date.toIso8601String();
        }
      }

      // 5. Категория
      result['category'] = _guessCategory(rawData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              recognized
                  ? 'Данные чека распознаны'
                  : 'Не удалось извлечь сумму, заполните вручную',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, result);
      }

      _isProcessing = false;
    });
  }

  String _guessCategory(String text) {
    final t = text.toLowerCase();
    if (t.contains('евроопт') ||
        t.contains('euroopt') ||
        t.contains('соседи') ||
        t.contains('sosedi') ||
        t.contains('гиппо') ||
        t.contains('gippo') ||
        t.contains('green') ||
        t.contains('март') ||
        t.contains('продукты') ||
        t.contains('пятёрочка') ||
        t.contains('лена') ||
        t.contains('виталюр')) {
      return 'Еда';
    }
    if (t.contains('яндекс') ||
        t.contains('yandex') ||
        t.contains('uber') ||
        t.contains('такси') ||
        t.contains('транспорт') ||
        t.contains('автобус')) {
      return 'Транспорт';
    }
    if (t.contains('аптека') ||
        t.contains('pharma') ||
        t.contains('здоровье') ||
        t.contains('apteka')) {
      return 'Здоровье';
    }
    if (t.contains('одежда') ||
        t.contains('zara') ||
        t.contains('марк') ||
        t.contains('clothes') ||
        t.contains('fashion')) {
      return 'Одежда';
    }
    return 'Покупки';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutout = Path()
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
    canvas.drawPath(
      Path.combine(PathOperation.difference, path, cutout),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
