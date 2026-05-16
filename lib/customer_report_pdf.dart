import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'customer_model.dart';

class CustomerReportPdf {

  static Future<void> printCustomers(
      List<CustomerModel> customers,
      String title,
      ) async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,

        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,

            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Table.fromTextArray(
                headers: ['ID', 'Name', 'Phone', 'Date'],

                data: customers.map((c) {
                  return [
                    c.id?.toString() ?? '',
                    c.name,
                    c.phone,
                    c.createdAt.isEmpty ? '-' : c.createdAt,
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}