import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'order_model.dart';

class CustomerReportPdf {
  // تابع اصلی برای تولید و نمایش فایل PDF فاکتور
  static Future<void> printOrders(
      List<OrderModel> orders,
      String title,
      ) async {

    // بارگذاری فونت‌های فارسی از پوشه assets
    final regularFontData = await rootBundle.load('assets/fonts/Farhang2-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/FarhangDot1-DemiBold.ttf');

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final pdf = pw.Document();

    // اضافه کردن صفحه به فایل PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            // تنظیم جهت متن به صورت راست‌به‌چپ برای فارسی
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // عنوان فاکتور
                  pw.Text(
                    title,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: boldFont, fontSize: 20),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'تعداد سفارشات: ${orders.length}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: regularFont, fontSize: 11),
                  ),
                  pw.SizedBox(height: 20),

                  // لیست کردن سفارشات در فاکتور
                  ...orders.map((order) => _orderCard(order, regularFont, boldFont)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // نمایش پیش‌نمایش چاپ به کاربر
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // طراحی کارت هر سفارش در فایل PDF
  static pw.Widget _orderCard(OrderModel order, pw.Font regularFont, pw.Font boldFont) {
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
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('سفارش شماره ${order.id ?? "-"}', style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.Text('تاریخ ثبت: ${order.createdAt.split('T')[0]}', style: pw.TextStyle(font: regularFont, fontSize: 10)),
            ],
          ),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),

          _infoRow('نام مشتری', order.customerName, regularFont, boldFont),
          _infoRow('شماره تماس', order.phone, regularFont, boldFont),
          _infoRow('نوع چاپ', order.printType, regularFont, boldFont),
          
          // نمایش ابعاد فقط اگر موجود باشند
          if (order.height != null || order.width != null)
            _infoRow('ابعاد (قد × بر)', '${order.height ?? 0} × ${order.width ?? 0}', regularFont, boldFont),

          _infoRow('وضعیت', order.status, regularFont, boldFont),
          _infoRow('تعداد', order.quantity.toString(), regularFont, boldFont),
          _infoRow('قیمت کل', '${order.price} افغانی', regularFont, boldFont),
          _infoRow('بیعانه', '${order.deposit} افغانی', regularFont, boldFont),
          _infoRow('الباقی', '${order.balance} افغانی', regularFont, boldFont),
          _infoRow('تاریخ تحویل', order.deliveryDate, regularFont, boldFont),
          _infoRow('توضیحات', order.notes.isEmpty ? '-' : order.notes, regularFont, boldFont),
        ],
      ),
    );
  }

  // تابع کمکی برای ساخت ردیف‌های اطلاعات در PDF
  static pw.Widget _infoRow(String label, String value, pw.Font regularFont, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 100,
            child: pw.Text('$label:', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: boldFont, fontSize: 10)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(value.isEmpty ? '-' : value, textAlign: pw.TextAlign.right, style: pw.TextStyle(font: regularFont, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
