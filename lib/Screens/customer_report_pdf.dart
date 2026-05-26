import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../Models/order_model.dart';

class CustomerReportPdf {

  static Future<void> printOrders(
      List<OrderModel> orders,
      String title, {
        String? fileName,
      }) async {

    final regularFontData =
    await rootBundle.load('assets/fonts/Farhang2-Regular.ttf');
    final boldFontData =
    await rootBundle.load('assets/fonts/FarhangDot1-DemiBold.ttf');

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [

                  // 🟣 HEADER حرفه‌ای
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'چاپخانه صدر',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 26,
                            color: PdfColors.black,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          title,
                          style: pw.TextStyle(
                            font: regularFont,
                            fontSize: 16,
                            color: PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 15),

                  pw.Text(
                    'تعداد سفارشات: ${orders.length}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: regularFont),
                  ),

                  pw.SizedBox(height: 20),

                  ...orders.map((o) => _orderCard(o, regularFont, boldFont)),

                  pw.SizedBox(height: 20),

                  // 🟢 جمع کل (Teal)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal100,
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColors.teal),
                    ),
                    child: pw.Text(
                      'جمع کل: ${orders.fold<int>(0, (sum, o) => sum + o.price)} افغانی',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // 💾 ذخیره فایل
    if (fileName != null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName.pdf');
      await file.writeAsBytes(await pdf.save());
    }

    // 🖨 چاپ
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // 📦 کارت سفارش
  static pw.Widget _orderCard(
      OrderModel order,
      pw.Font regularFont,
      pw.Font boldFont,
      ) {
    final dateTime = DateTime.parse(order.createdAt);
    final jalali = Jalali.fromDateTime(dateTime);

    final dateText =
        '${jalali.year}/${jalali.month}/${jalali.day}';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'سفارش #${order.id ?? "-"}',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text(
                dateText,
                style: pw.TextStyle(font: regularFont, fontSize: 10),
              ),
            ],
          ),

          pw.Divider(),

          _row('نام', order.customerName, regularFont, boldFont),
          _row('تلفن', order.phone, regularFont, boldFont),
          _row('نوع چاپ', order.printType, regularFont, boldFont),
          _row('تعداد', order.quantity.toString(), regularFont, boldFont),
          _row('قیمت', '${order.price} افغانی', regularFont, boldFont),
          _row('بیعانه', '${order.deposit} افغانی', regularFont, boldFont),
          _row('باقی', '${order.balance} افغانی', regularFont, boldFont),
        ],
      ),
    );
  }

  static pw.Widget _row(
      String label,
      String value,
      pw.Font regularFont,
      pw.Font boldFont,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 90,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: regularFont, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}