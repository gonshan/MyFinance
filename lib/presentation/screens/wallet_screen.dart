import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/providers/discount_card_provider.dart';
import 'add_card_screen.dart';
import 'card_detail_screen.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DiscountCardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои карты', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryMint),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCardScreen())),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.cards.isEmpty
              ? const Center(child: Text('Кошелек пуст. Добавьте первую карту!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.cards.length,
                  itemBuilder: (context, index) {
                    final card = provider.cards[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: card))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        height: 100,
                        decoration: BoxDecoration(
                          color: Color(card.color),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.shadowDark.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5))
                          ]
                        ),
                        child: Center(
                          child: Text(
                            card.storeName,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}