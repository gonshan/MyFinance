import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/transaction_provider.dart';
import '../../data/models/transaction_model.dart';
import '../screens/categories_screen.dart'; // <--- Вернули импорт!
// Экран сканера здесь больше не нужен, мы убрали кнопку

class AddTransactionSheet extends StatefulWidget {
  final TransactionModel? transaction; 
  final double? scannedAmount;
  final DateTime? scannedDate;
  final String? scannedCategory;

  const AddTransactionSheet({
    super.key, // Используем super.key для краткости
    this.transaction, 
    this.scannedAmount,
    this.scannedDate,
    this.scannedCategory,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _amount = '0';
  bool _isIncome = false;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    // 1. Категория по умолчанию
    if (provider.categories.isNotEmpty) {
      _selectedCategory = provider.categories.first.name;
    }

    // 2. Заполнение данными
    if (widget.transaction != null) {
      _isIncome = widget.transaction!.isIncome;
      _selectedCategory = widget.transaction!.category;
      _selectedDate = widget.transaction!.date;
      _amount = _formatAmount(widget.transaction!.amount);
    
    } else if (widget.scannedAmount != null) {
      _isIncome = false;
      _amount = _formatAmount(widget.scannedAmount!);
      if (widget.scannedDate != null) _selectedDate = widget.scannedDate!;
      if (widget.scannedCategory != null) {
         bool exists = provider.categories.any((c) => c.name == widget.scannedCategory);
         if (exists) _selectedCategory = widget.scannedCategory!;
      }
    }
  }

  String _formatAmount(double value) {
    String str = value.toString();
    if (str.endsWith('.0')) return str.substring(0, str.length - 2);
    return str;
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

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryMint),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

    final transaction = TransactionModel(
      id: widget.transaction?.id,
      amount: value,
      category: _selectedCategory,
      date: _selectedDate,
      isIncome: _isIncome,
    );

    if (widget.transaction == null) {
      provider.addTransaction(transaction);
    } else {
      provider.editTransaction(transaction);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Используем watch, чтобы список обновился, если мы добавим категорию и вернемся
    final categories = context.watch<TransactionProvider>().categories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textGrey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    widget.transaction != null ? "Редактирование" : (widget.scannedAmount != null ? "Сканированный чек" : "Новая операция"),
                    style: const TextStyle(fontSize: 16, color: AppColors.textGrey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  
                  // Переключатель
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTypeButton("Расход", false),
                      const SizedBox(width: 20),
                      _buildTypeButton("Доход", true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // СУММА (Кнопку QR убрали)
                  Text(
                    "$_amount BYN",
                    style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold, 
                      color: _isIncome ? AppColors.primaryMint : AppColors.secondarySalmon
                    ),
                  ),

                  // ДАТА
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.textGrey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('d MMMM yyyy', 'ru').format(_selectedDate),
                            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // СКРОЛЛ КАТЕГОРИЙ + КНОПКА НАСТРОЙКИ (В КОНЦЕ)
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      // +1 элемент для кнопки настроек
                      itemCount: categories.length + 1,
                      separatorBuilder: (c, i) => const SizedBox(width: 15),
                      itemBuilder: (context, index) {
                        
                        // Если это последний элемент — рисуем кнопку Настройки
                        if (index == categories.length) {
                          return GestureDetector(
                            onTap: () {
                              // Переход к управлению категориями
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.textGrey.withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.settings_rounded, color: AppColors.textGrey),
                                ),
                                const SizedBox(height: 5),
                                const Text("Меню", style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                              ],
                            ),
                          );
                        }

                        // Иначе рисуем обычную категорию
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
                                    BoxShadow(color: (_isIncome ? AppColors.primaryMint : AppColors.secondarySalmon).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 5))
                                  ] : [],
                                ),
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
                  
                  // КЛАВИАТУРА
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