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
                  "Наведите камеру на QR-код чека",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Поддерживаются: СККО и Е-Плюс (РБ)",
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
      final Map<String, dynamic> result = {};
      bool recognized = false;

      try {
        debugPrint('📱 Raw QR: $rawData');
        String decodedText = rawData;

        // 1. Попытка декодировать hex
        if (RegExp(r'^[0-9a-fA-F]{16,}$').hasMatch(rawData)) {
          try {
            final bytes = <int>[];
            for (int i = 0; i < rawData.length; i += 2) {
              bytes.add(int.parse(rawData.substring(i, i + 2), radix: 16));
            }
            decodedText = String.fromCharCodes(bytes);
            debugPrint('🔄 Hex decoded: $decodedText');
          } catch (_) {
            debugPrint('⚠️ Hex decoding failed');
          }
        }

        // 2. Проверка на JSON
        if (decodedText.startsWith('{')) {
          try {
            final decoded = jsonDecode(decodedText);
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
          } catch (_) {
            debugPrint('⚠️ JSON parsing failed');
          }
        }

        // 3. Обработка Е-Плюс
        if (!recognized && decodedText.contains('eplus.by')) {
          debugPrint('🔍 Обнаружен чек Е-Плюс');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📡 Загружаем чек из Е-Плюс...'),
                backgroundColor: AppColors.primaryMint,
                duration: Duration(seconds: 2),
              ),
            );
          }

          try {
            final response = await http
                .get(
                  Uri.parse(decodedText.trim()),
                  headers: {
                    'User-Agent':
                        'Mozilla/5.0 (Linux; Android 10) MyFinance/1.0',
                    'Accept': 'text/html,application/xhtml+xml',
                  },
                )
                .timeout(const Duration(seconds: 10));

            if (response.statusCode == 200) {
              debugPrint('✅ HTML получен: ${response.body.length} символов');

              final document = parser.parse(response.body);

              // Поиск суммы
              final sumPatterns = [
                RegExp(
                  r'(?:Итого|Сумма|Total|Всего)[^0-9]*?([0-9]+[.,][0-9]{2})',
                  caseSensitive: false,
                ),
                RegExp(r'([0-9]+[.,][0-9]{2})\s*BYN'),
                RegExp(r'([0-9]+[.,][0-9]{2})\s*руб'),
              ];

              for (final pattern in sumPatterns) {
                final match = pattern.firstMatch(document.body?.text ?? '');
                if (match != null) {
                  String sumStr = match.group(1)!.replaceAll(',', '.');
                  double? amount = double.tryParse(sumStr);
                  if (amount != null && amount > 0) {
                    // Обработка копеек (1698 → 16.98)
                    if (amount > 1000) amount /= 100;
                    result['amount'] = amount.toStringAsFixed(2);
                    recognized = true;
                    debugPrint('💰 Сумма: ${result['amount']} BYN');
                    break;
                  }
                }
              }

              // Поиск даты
              final datePattern = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})');
              final dateMatch = datePattern.firstMatch(
                document.body?.text ?? '',
              );
              if (dateMatch != null) {
                try {
                  final date = DateTime(
                    int.parse(dateMatch.group(3)!),
                    int.parse(dateMatch.group(2)!),
                    int.parse(dateMatch.group(1)!),
                  );
                  result['date'] = date.toIso8601String();
                  debugPrint('📅 Дата: ${date.toLocal()}');
                } catch (_) {}
              }

              // Поиск магазина
              final shopPatterns = [
                RegExp(
                  r'(Евроопт|Соседи|Гиппо|Виталюр|Март|Green|Санта|Корона)',
                  caseSensitive: false,
                ),
              ];
              for (final pattern in shopPatterns) {
                final match = pattern.firstMatch(document.body?.text ?? '');
                if (match != null) {
                  result['category'] = _guessCategory(match.group(0)!);
                  break;
                }
              }
            } else {
              debugPrint('❌ HTTP ${response.statusCode}');
            }
          } catch (e) {
            debugPrint('❌ Ошибка HTTP: $e');
          }
        }

        // 4. Обработка СККО
        if (!recognized) {
          final uri = Uri.tryParse(decodedText.trim());
          if (uri != null && uri.host.contains('skko.by') && uri.hasQuery) {
            debugPrint('🔍 Обнаружен чек СККО');

            final query = uri.queryParameters;
            debugPrint('📋 Параметры: $query');

            // Сумма
            String? sumStr = query['s'] ?? query['sum'];
            if (sumStr != null) {
              double? amount = double.tryParse(sumStr.replaceAll(',', '.'));
              if (amount != null && amount > 0) {
                // Обработка копеек (1698 → 16.98)
                if (amount > 1000) amount /= 100;
                result['amount'] = amount.toStringAsFixed(2);
                recognized = true;
                debugPrint('💰 Сумма: ${result['amount']} BYN');
              }
            }

            // Дата
            String? dateStr = query['t'];
            if (dateStr != null) {
              final match = RegExp(
                r'(\d{4})(\d{2})(\d{2})T?(\d{2})?(\d{2})?',
              ).firstMatch(dateStr);
              if (match != null) {
                try {
                  final date = DateTime(
                    int.parse(match.group(1)!),
                    int.parse(match.group(2)!),
                    int.parse(match.group(3)!),
                    match.group(4) != null ? int.parse(match.group(4)!) : 0,
                    match.group(5) != null ? int.parse(match.group(5)!) : 0,
                  );
                  result['date'] = date.toIso8601String();
                  debugPrint('📅 Дата: ${date.toLocal()}');
                } catch (_) {}
              }
            }
          }
        }

        // 5. Fallback: поиск чисел в тексте
        if (!recognized) {
          final decimalMatches = RegExp(
            r'(\d+[.,]\d{2})',
          ).allMatches(decodedText);
          final candidates = <double>[];
          for (final m in decimalMatches) {
            final val = double.tryParse(m.group(1)!.replaceAll(',', '.'));
            if (val != null && val > 0.01 && val < 50000) {
              candidates.add(val);
            }
          }
          if (candidates.isNotEmpty) {
            candidates.sort();
            double amount = candidates.last;
            if (amount > 1000) amount /= 100;
            result['amount'] = amount.toStringAsFixed(2);
            recognized = true;
            debugPrint('💰 Сумма из текста: ${result['amount']} BYN');
          }
        }

        // 6. Категория по умолчанию
        if (result['category'] == null) {
          result['category'] = _guessCategory(decodedText);
        }
      } catch (e, stack) {
        debugPrint('❌ Ошибка: $e\n$stack');
      }

      // Возвращаем результат
      if (mounted) {
        if (recognized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Чек распознан: ${result['amount']} BYN'),
              backgroundColor: AppColors.primaryMint,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, result);
        } else {
          // Показываем диалог с ручным вводом
          _showManualInputDialog(result);
        }
      }

      _isProcessing = false;
    });
  }

  void _showManualInputDialog(Map<String, dynamic> partialData) {
    final amountController = TextEditingController(
      text: partialData['amount'] ?? '',
    );
    final category = partialData['category'] ?? 'Покупки';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(Theme.of(context).brightness),
        title: const Text('QR-код распознан'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Не удалось автоматически извлечь сумму'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Сумма (BYN)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, {});
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = amountController.text.trim();
              if (amount.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.pop(context, {
                  'amount': amount,
                  'category': category,
                  'date': DateTime.now().toIso8601String(),
                });
              }
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }

  String _guessCategory(String text) {
    final t = text.toLowerCase();
    if (t.containsAny([
      'евроопт',
      'соседи',
      'гиппо',
      'виталюр',
      'март',
      'green',
      'продукты',
      'еда',
    ]))
      return 'Еда';
    if (t.containsAny(['такси', 'транспорт', 'заправка', 'автобус']))
      return 'Транспорт';
    if (t.containsAny(['аптека', 'здоровье', 'лекар'])) return 'Здоровье';
    if (t.containsAny([
      'одежда',
      'zara',
      'марк',
      'clothes',
      'fashion',
      'обувь',
    ]))
      return 'Одежда';
    if (t.containsAny([
      'дом',
      'ремонт',
      'строй',
      'мебель',
      'электрик',
      'сантех',
      'хозяй',
      'быт',
      '220',
      'omni',
    ]))
      return 'Дом';
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

extension StringContainsAny on String {
  bool containsAny(List<String> substrings) =>
      substrings.any((sub) => contains(sub));
}
