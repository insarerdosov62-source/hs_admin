import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndSharePdf(Map<String, dynamic> record) async {
    final pdf = pw.Document();
    
    // Переменные для шрифтов
    pw.Font? regularFont;
    pw.Font? boldFont;

    try {
      // Пытаемся загрузить нормальные шрифты
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      regularFont = pw.Font.ttf(fontData);
      
      final boldData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
      boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      // Если не вышло — берем стандартные, чтобы не висло
      print("Ошибка загрузки шрифтов: $e");
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "HONDA SERVICE",
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "Дата: ${record['date']} • ${record['time']}",
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
                pw.Text(
                  "Автомобиль: ${record['carModel']} (${record['licensePlate']})",
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 20),
                pw.Text(
                  "ВЫПОЛНЕННЫЕ РАБОТЫ:",
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  record['type'] ?? "",
                  style: pw.TextStyle(font: regularFont, fontSize: 12),
                ),
                pw.Spacer(),
                if (record['totalPrice'] != null && record['totalPrice'] > 0)
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      "Итого к оплате: ${record['totalPrice']} ₸",
                      style: pw.TextStyle(font: boldFont, fontSize: 18),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    // Этот метод вызывает системное окно печати/PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'honda_service_${record['licensePlate']}.pdf',
    );
  }
}
