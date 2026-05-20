import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'customer_model.dart';
import 'order_model.dart';

class CustomerReportPdf {

  static Future<void> printOrders(
      List<OrderModel> orders,
      String title,
      ) async {

    final regularFontData =
    await rootBundle.load('assets/fonts/Farhang2-Regular.ttf');

    final boldFontData =
    await rootBundle.load('assets/fonts/FarhangDot1-DemiBold.ttf');

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 20,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'تعداد موارد: ${orders.length}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  ...orders.map(
                        (order) =>
                        _orderCard(order, regularFont, boldFont),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  static pw.Widget _orderCard(
      OrderModel order,
      pw.Font regularFont,
      pw.Font boldFont,
      ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'سفارش شماره ${order.id ?? "-"}',
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
          pw.SizedBox(height: 10),

          _infoRow('نام مشتری', order.customerName, regularFont, boldFont),
          _infoRow('شماره تماس', order.phone, regularFont, boldFont),
          _infoRow('نوع چاپ', order.printType, regularFont, boldFont),
          _infoRow('وضعیت', order.status, regularFont, boldFont),
          _infoRow('تعداد', order.quantity.toString(), regularFont, boldFont),
          _infoRow('قیمت', order.price.toString(), regularFont, boldFont),
          _infoRow('تاریخ تحویل', order.deliveryDate, regularFont, boldFont),
          _infoRow(
            'توضیحات',
            order.notes.isEmpty ? '-' : order.notes,
            regularFont,
            boldFont,
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(
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
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: boldFont, fontSize: 10),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '-' : value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: regularFont, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}