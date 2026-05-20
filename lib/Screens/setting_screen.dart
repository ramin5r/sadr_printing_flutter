import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../customer_report_pdf.dart';

class SettingScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;
  final VoidCallback onGlobalRefresh;
  final int refreshNumber;

  const SettingScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onGlobalRefresh,
    required this.refreshNumber,
  });

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isExportingAllCustomers = false;
  bool isExportingLast24HoursCustomers = false;

  Future<void> exportAllCustomers() async {
    if (isExportingAllCustomers) return;

    setState(() => isExportingAllCustomers = true);

    final orders = await DatabaseHelper.instance.getAllCustomerOrderDetails();

    if (!mounted) return;
    setState(() => isExportingAllCustomers = false);

    if (orders.isEmpty) {
      showMessage('هنوز هیچ مشتری یا سفارشی ثبت نشده است.');
      return;
    }

    await CustomerReportPdf.printOrders(
      orders,
      'گزارش کامل مشتری‌ها و سفارش‌ها',
    );
  }

  Future<void> exportLast24HoursCustomers() async {
    if (isExportingLast24HoursCustomers) return;

    setState(() => isExportingLast24HoursCustomers = true);

    final orders =
    await DatabaseHelper.instance.getNewCustomerOrderDetailsLast24Hours();

    if (!mounted) return;

    setState(() => isExportingLast24HoursCustomers = false);

    if (orders.isEmpty) {
      showMessage('در ۲۴ ساعت گذشته مشتری جدیدی ثبت نشده است.');
      return;
    }

    await CustomerReportPdf.printOrders(
      orders,
      'گزارش کامل مشتری‌های ۲۴ ساعت گذشته',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Switch(
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
            ),
            title: const Text('حالت تاریک'),
            subtitle: const Text('تغییر ظاهر برنامه به حالت روشن یا تاریک'),
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: isExportingAllCustomers
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.picture_as_pdf),
            title: const Text('خروجی PDF کامل همه مشتری‌ها'),
            subtitle: const Text(
              'شامل نام، شماره، نوع چاپ، تعداد، قیمت، تاریخ تحویل، وضعیت و توضیحات',
            ),
            onTap: isExportingAllCustomers ? null : exportAllCustomers,
          ),
        ),

        const SizedBox(height: 8),

        Card(
          child: ListTile(
            leading: isExportingLast24HoursCustomers
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.new_releases),
            title: const Text('خروجی PDF کامل مشتری‌های ۲۴ ساعت گذشته'),
            subtitle: const Text(
              'گزارش کامل مشتری‌هایی که در ۲۴ ساعت گذشته ثبت شده‌اند',
            ),
            onTap: isExportingLast24HoursCustomers
                ? null
                : exportLast24HoursCustomers,
          ),
        ),
      ],
    );
  }
}
