import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme.dart';
// Убрал лишний импорт neumorphic_card.dart

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key}); // Исправил на super.key

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  // Контроллер
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
          // 1. СКАНЕР
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

          // 2. ЗАТЕМНЕНИЕ (Оверлей)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              // Исправил withOpacity на withValues (новое требование Flutter)
              Colors.black.withValues(alpha: 0.7), 
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. ИНТЕРФЕЙС
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
                      
                      // Кнопка Фонарика (ИСПРАВЛЕННАЯ ЛОГИКА)
                      ValueListenableBuilder(
                        valueListenable: controller, // Слушаем сам контроллер
                        builder: (context, state, child) {
                          // Получаем состояние фонарика из state
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
          
          // 4. Рамка
          Center(
            child: Container(
              height: 280, width: 280,
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

  void _processCode(String rawData) {
    setState(() => _isScanned = true);
    Map<String, dynamic> result = {};

    try {
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
      if (rawData.contains("sum=") || rawData.contains("s=")) {
        final regex = RegExp(r'[0-9]+(\.[0-9]{1,2})?');
        final match = regex.firstMatch(rawData);
        if (match != null) {
          result['amount'] = match.group(0);
        }
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