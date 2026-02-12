import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart'; // Импорт категорий

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionSheet({Key? key, this.transaction}) : super(key: key);

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _amount = '0';
  bool _isIncome = false;
  String _selectedCategory = ''; // Теперь пустая по умолчанию

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    // Если список категорий загружен, берем первую
    if (provider.categories.isNotEmpty) {
      _selectedCategory = provider.categories.first.name;
    }

    if (widget.transaction != null) {
      _isIncome = widget.transaction!.isIncome;
      _selectedCategory = widget.transaction!.category;
      String amountStr = widget.transaction!.amount.toString();
      if (amountStr.endsWith('.0')) {
        amountStr = amountStr.substring(0, amountStr.length - 2);
      }
      _amount = amountStr;
    }
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (value == '.') {
        if (!_amount.contains('.')) _amount += value;
      } else {
        if (_amount == '0') {
          _amount = value;
        } else {
          if (_amount.length < 9) _amount += value;
        }
      }
    });
  }

  void _saveTransaction() {
    final double? value = double.tryParse(_amount);
    if (value == null || value == 0) return;

    final provider = Provider.of<TransactionProvider>(context, listen: false);

    if (!_isIncome) {
       double available = provider.balance;
       if (widget.transaction != null && !widget.transaction!.isIncome) {
         available += widget.transaction!.amount;
       }
       if (available < value) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondarySalmon,
            content: const Text("Недостаточно средств! 💸", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
        return;
       }
    }

    if (widget.transaction == null) {
      final newTransaction = TransactionModel(
        amount: value,
        category: _selectedCategory,
        date: DateTime.now(),
        isIncome: _isIncome,
      );
      provider.addTransaction(newTransaction);
    } else {
      final updatedTransaction = TransactionModel(
        id: widget.transaction!.id,
        amount: value,
        category: _selectedCategory,
        date: widget.transaction!.date,
        isIncome: _isIncome,
      );
      provider.editTransaction(updatedTransaction);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Получаем категории из провайдера
    final categories = Provider.of<TransactionProvider>(context).categories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textGrey.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    widget.transaction == null ? "Новая операция" : "Редактирование",
                    style: const TextStyle(fontSize: 16, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTypeButton("Расход", false),
                      const SizedBox(width: 20),
                      _buildTypeButton("Доход", true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "$_amount BYN",
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _isIncome ? AppColors.primaryMint : AppColors.secondarySalmon),
                  ),
                  const SizedBox(height: 20),
                  
                  // Скролл категорий из базы
                  SizedBox(
                    height: 90, // Чуть увеличили высоту
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 15),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat.name;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat.name),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? (_isIncome ? AppColors.primaryMint : AppColors.secondarySalmon) 
                                      : AppColors.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected ? [
                                    BoxShadow(color: (_isIncome ? AppColors.primaryMint : AppColors.secondarySalmon).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                                  ] : [],
                                ),
                                // Восстанавливаем иконку из кода
                                child: Icon(
                                  IconData(cat.iconCode, fontFamily: 'MaterialIcons'), 
                                  color: isSelected ? Colors.white : AppColors.textGrey,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(cat.name, style: TextStyle(fontSize: 10, color: isSelected ? AppColors.textDark : AppColors.textGrey)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        _buildKeyRow(['1', '2', '3']),
                        _buildKeyRow(['4', '5', '6']),
                        _buildKeyRow(['7', '8', '9']),
                        _buildKeyRow(['.', '0', '⌫']),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveTransaction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isIncome ? AppColors.primaryMint : AppColors.secondarySalmon,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(widget.transaction == null ? "Сохранить" : "Обновить", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String title, bool isIncome) {
    final isSelected = _isIncome == isIncome;
    return GestureDetector(
      onTap: () => setState(() => _isIncome = isIncome),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? (isIncome ? AppColors.primaryMint : AppColors.secondarySalmon) : AppColors.surface, borderRadius: BorderRadius.circular(20)),
        child: Text(title, style: TextStyle(color: isSelected ? Colors.white : AppColors.textGrey, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: keys.map((key) => InkWell(
          onTap: () => _onKeyTap(key),
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(width: 70, height: 70, child: Center(child: Text(key, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textDark)))),
        )).toList(),
      ),
    );
  }
}