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

    try {
      if (rawData.startsWith('http') && rawData.contains('skko.by')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Загружаем данные чека из базы СККО...'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        final response = await http.get(Uri.parse(rawData));
        
        if (response.statusCode == 200) {
          var document = parser.parse(response.body);
          
          var sumElement = document.querySelector('.total-sum'); 
          if (sumElement != null) {
            String sumText = sumElement.text.replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
            result['amount'] = sumText;
          }

          var dateElement = document.querySelector('.receipt-date');
          if (dateElement != null) {
          }
          
          result['category'] = 'Покупки';
        }
      } 
      else if (rawData.startsWith('{')) {
        try {
          final decoded = jsonDecode(rawData);
          if (decoded is Map<String, dynamic>) {
            if (decoded.containsKey('s')) result['amount'] = decoded['s'].toString();
            if (decoded.containsKey('sum')) result['amount'] = decoded['sum'].toString();
            if (decoded.containsKey('c')) result['category'] = decoded['c'].toString();
            if (decoded.containsKey('cat')) result['category'] = decoded['cat'].toString();
            if (decoded.containsKey('d')) result['date'] = decoded['d'].toString();
            if (decoded.containsKey('date')) result['date'] = decoded['date'].toString();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Ошибка загрузки или парсинга СККО: $e');
    }

    if (!result.containsKey('amount')) {
      final sumMatch = RegExp(r'(?:s|sum)=([0-9]+(?:[\.,][0-9]{1,2})?)').firstMatch(rawData);
      if (sumMatch != null) {
        result['amount'] = sumMatch.group(1)!.replaceAll(',', '.');
      }

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

    if (mounted) {
      Navigator.pop(context, result);
    }
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