import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/discount_card_model.dart';
import '../../core/providers/discount_card_provider.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  String _selectedFormat = 'ean13';
  Color _selectedColor = Colors.blue;

  final List<Color> _colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.black];

  void _saveCard() {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) return;

    final newCard = DiscountCardModel(
      storeName: _nameController.text,
      code: _codeController.text,
      format: _selectedFormat,
      color: _selectedColor.value,
    );

    context.read<DiscountCardProvider>().addCard(newCard);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Добавить карту')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Название магазина')),
            TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Номер карты')),
            DropdownButton<String>(
              value: _selectedFormat,
              items: ['ean13', 'ean8', 'code128', 'qr'].map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase()))).toList(),
              onChanged: (val) => setState(() => _selectedFormat = val!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => setState(() => _selectedColor = _colors[i]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      shape: BoxShape.circle,
                      border: _selectedColor == _colors[i] ? Border.all(width: 3, color: Colors.white) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(onPressed: _saveCard, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}