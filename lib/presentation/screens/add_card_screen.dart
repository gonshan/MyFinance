import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../data/models/discount_card_model.dart';
import '../../core/providers/discount_card_provider.dart';
import '../../core/utils/brand_helper.dart';
import '../../core/theme.dart';

class AddCardScreen extends StatefulWidget {
  final DiscountCardModel? card;

  const AddCardScreen({super.key, this.card});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedFormat = 'ean13';
  Color _selectedColor = Colors.blue;

  static const List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.black,
    Colors.teal,
    Colors.brown,
    Colors.indigo,
    Colors.pink,
    Colors.deepOrange,
    Colors.lime,
    Colors.cyan,
    Colors.amber,
    Colors.deepPurple,
  ];

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.card!.storeName;
      _codeController.text = widget.card!.code;
      _selectedFormat = widget.card!.format;
      _selectedColor = Color(widget.card!.color);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScannerScreen()),
    );

    if (result == null || !mounted) return;

    final code = result['code'] as String;
    final format = result['format'] as String;

    setState(() {
      _codeController.text = code;
      _selectedFormat = format;

      final brand = BrandHelper.identifyBrand(code);
      if (brand != null) {
        _nameController.text = brand['name'] as String;
        _selectedColor = Color(brand['color'] as int);
      }
    });
  }

  void _saveCard() {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) return;

    final card = DiscountCardModel(
      id: widget.card?.id,
      storeName: _nameController.text,
      code: _codeController.text,
      format: _selectedFormat,
      color: _selectedColor.value,
    );

    final provider = context.read<DiscountCardProvider>();
    if (_isEditing) {
      provider.updateCard(card);
    } else {
      provider.addCard(card);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final textGrey = AppColors.textGrey(brightness);
    final inputFillColor = brightness == Brightness.light
        ? Colors.white
        : Colors.grey[850]!;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );

    // Тема для DropdownButtonFormField, чтобы текст был контрастным
    final dropdownTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.copyWith(
        titleMedium: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Редактировать карту' : 'Добавить карту',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Название магазина',
                labelStyle: TextStyle(color: textGrey),
                prefixIcon: Icon(Icons.store, color: colorScheme.primary),
                filled: true,
                fillColor: inputFillColor,
                border: inputBorder,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    style: TextStyle(color: colorScheme.onSurface),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Номер карты / штрих-код',
                      labelStyle: TextStyle(color: textGrey),
                      prefixIcon: Icon(
                        Icons.barcode_reader,
                        color: colorScheme.primary,
                      ),
                      filled: true,
                      fillColor: inputFillColor,
                      border: inputBorder,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: IconButton.filled(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'Сканировать штрих-код',
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Theme(
              data: dropdownTheme,
              child: DropdownButtonFormField<String>(
                value: _selectedFormat,
                dropdownColor: colorScheme.surface,
                isExpanded: true,
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: textGrey),
                  prefixIcon: Icon(Icons.qr_code, color: colorScheme.primary),
                  filled: true,
                  fillColor: inputFillColor,
                  border: inputBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: ['ean13', 'ean8', 'code128', 'qr']
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f.toUpperCase(),
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedFormat = val!),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Цвет карты',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = _colors[i]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: _selectedColor == _colors[i]
                          ? Border.all(width: 3, color: Colors.white)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _saveCard,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(
                _isEditing ? 'Сохранить изменения' : 'Добавить карту',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Внутренний экран сканера штрих-кода
class _BarcodeScannerScreen extends StatefulWidget {
  const _BarcodeScannerScreen();

  @override
  State<_BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<_BarcodeScannerScreen>
    with WidgetsBindingObserver {
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
      case AppLifecycleState.resumed:
        _isScanned = false;
        controller.start();
        break;
      case AppLifecycleState.inactive:
        controller.stop();
        break;
      default:
        break;
    }
  }

  String _mapFormat(BarcodeFormat? format) {
    switch (format) {
      case BarcodeFormat.ean13:
        return 'ean13';
      case BarcodeFormat.ean8:
        return 'ean8';
      case BarcodeFormat.code128:
        return 'code128';
      case BarcodeFormat.qrCode:
        return 'qr';
      default:
        return 'code128';
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _isScanned = true);

    final format = _mapFormat(barcode.format);

    Navigator.pop(context, {'code': rawValue, 'format': format});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Сканировать штрих-код'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          Center(
            child: Container(
              width: 280,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Наведите камеру на штрих-код',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }
}
