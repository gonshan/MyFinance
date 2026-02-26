import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';

class PdfService {
  Future<void> generateAndPrintPdf({
    required List<TransactionModel> transactions,
    required DateTime date,
  }) async {
    final doc = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in transactions) {
      if (t.isIncome) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    final totalBalance = totalIncome - totalExpense;
    final monthName = DateFormat('LLLL yyyy', 'ru').format(date).toUpperCase();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: ttf,
          ),
          margin: const pw.EdgeInsets.all(40),
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Финансовый отчет', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(monthName, style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem("Доход", totalIncome, PdfColors.green700),
                  _buildSummaryItem("Расход", totalExpense, PdfColors.red700),
                  _buildSummaryItem("Итог", totalBalance, totalBalance >= 0 ? PdfColors.black : PdfColors.red700),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            pw.Text("Детализация операций", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            
            pw.TableHelper.fromTextArray(
              context: context,
              border: null, 
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
              headers: ['Дата', 'Категория', 'Сумма'],
              data: transactions.map((t) {
                final dateStr = DateFormat('dd.MM.yyyy').format(t.date);
                final amountPrefix = t.isIncome ? '+' : '-';
                final amountStr = "$amountPrefix${t.amount.toStringAsFixed(2)} BYN";
                return [dateStr, t.category, amountStr];
              }).toList(),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20), 
              child: pw.Text("Сгенерировано приложением MyFinance", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500))
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Report_$monthName', 
    );
  }

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
        pw.Text(
          "${amount.toStringAsFixed(2)} BYN",
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color),
        ),
      ],
    );
  }
}