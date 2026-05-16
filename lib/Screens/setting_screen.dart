import 'package:flutter/material.dart';

import '../database_helper.dart';
import '../customer_report_pdf.dart';

class SettingScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;

  final bool isEnglish;
  final void Function(bool) onLanguageChanged;

  final VoidCallback onGlobalRefresh;
  final int refreshNumber;

  const SettingScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.isEnglish,
    required this.onLanguageChanged,
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

    final customers = await DatabaseHelper.instance.getAllCustomers();

    if (!mounted) return;

    setState(() => isExportingAllCustomers = false);

    if (customers.isEmpty) {
      showMessage('هنوز هیچ مشتری ثبت نشده است.');
      return;
    }

    await CustomerReportPdf.printCustomers(
      customers,
      'All Customers',
    );
  }

  Future<void> exportLast24HoursCustomers() async {
    if (isExportingLast24HoursCustomers) return;

    setState(() => isExportingLast24HoursCustomers = true);

    final customers =
        await DatabaseHelper.instance.getCustomersLast24Hours();

    if (!mounted) return;

    setState(() => isExportingLast24HoursCustomers = false);

    if (customers.isEmpty) {
      showMessage('در ۲۴ ساعت گذشته مشتری جدیدی ثبت نشده است.');
      return;
    }

    await CustomerReportPdf.printCustomers(
      customers,
      'New Customers Last 24 Hours',
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
            title: const Text('خروجی PDF همه مشتری‌ها'),
            subtitle: const Text(
              'گزارش کامل تمام مشتری‌های ثبت‌شده را دریافت کنید.',
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
            title: const Text('خروجی PDF مشتری‌های ۲۴ ساعت گذشته'),
            subtitle: const Text(
              'گزارش مشتری‌هایی را بگیرید که در ۲۴ ساعت گذشته ثبت شده‌اند.',
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
