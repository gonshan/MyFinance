import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../core/providers/discount_card_provider.dart';
import '../../core/theme.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String? scannedFormat;
  bool isManualMode = false; // Флаг для переключения режима
  Color selectedColor = AppColors.primaryMint;

  void _saveCard() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();

    if (name.isNotEmpty && code.isNotEmpty) {
      context.read<DiscountCardProvider>().addCard(
        name,
        code,
        scannedFormat ??
            (code.length > 10
                ? 'CODE_128'
                : 'QR_CODE'), // Простая логика определения формата
        selectedColor,
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните название и код карты')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Добавление карты"),
        actions: [
          // Кнопка переключения режимов
          IconButton(
            icon: Icon(isManualMode ? Icons.camera_alt : Icons.edit_note),
            onPressed: () => setState(() => isManualMode = !isManualMode),
            tooltip: isManualMode ? "Включить камеру" : "Ввести вручную",
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Чтобы клавиатура не закрывала поля
        child: Column(
          children: [
            if (!isManualMode)
              SizedBox(
                height: 250,
                child: MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      setState(() {
                        _codeController.text = barcodes.first.rawValue ?? "";
                        scannedFormat = barcodes.first.format.name;
                        isManualMode =
                            true; // После сканирования переходим к заполнению имени
                      });
                    }
                  },
                ),
              )
            else
              Container(
                height: 100,
                color: AppColors.primaryMint.withValues(alpha: 0.05),
                child: const Center(
                  child: Icon(
                    Icons.keyboard_outlined,
                    size: 50,
                    color: AppColors.primaryMint,
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Данные карты",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Название магазина",
                      prefixIcon: const Icon(Icons.storefront),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: "Номер карты / Код",
                      prefixIcon: const Icon(Icons.qr_code),
                      helperText: isManualMode
                          ? "Введите цифры под штрихкодом"
                          : "Код появится здесь после сканирования",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Выбор цвета (простой вариант для диплома)
                  const Text("Цвет карточки"),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _colorOption(AppColors.primaryMint),
                      _colorOption(Colors.blueAccent),
                      _colorOption(Colors.orangeAccent),
                      _colorOption(Colors.deepPurpleAccent),
                      _colorOption(Colors.redAccent),
                    ],
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMint,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Сохранить в кошелек",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
