import 'package:flutter/material.dart';
import '../Themes/theme.dart';
import '../Models/customer_model.dart';
import '../Database/database_helper.dart';
import 'customer_report_pdf.dart';
import '../Models/order_model.dart';

class CustomersScreen extends StatefulWidget {
  final int refreshNumber;
  final VoidCallback onGlobalRefresh;

  const CustomersScreen({
    super.key,
    required this.refreshNumber,
    required this.onGlobalRefresh,
  });

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final searchController = TextEditingController();
  late Future<List<CustomerModel>> futureCustomers;

  @override
  void initState() {
    super.initState();
    futureCustomers = loadCustomers();
  }

  @override
  void didUpdateWidget(CustomersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // اگر تغییری در برنامه رخ داد، لیست مشتریان را رفرش کن
    if (oldWidget.refreshNumber != widget.refreshNumber) refresh();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // بارگذاری لیست مشتریان از دیتابیس (با در نظر گرفتن متن جستجو)
  Future<List<CustomerModel>> loadCustomers() {
    return DatabaseHelper.instance.getCustomers(
      search: searchController.text.trim(),
    );
  }

  // رفرش کردن لیست مشتریان در همین صفحه
  void refresh() {
    setState(() {
      futureCustomers = loadCustomers();
    });
  }

  // رفرش کردن کل برنامه
  void refreshAllPages() {
    refresh();
    widget.onGlobalRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CustomerModel>>(
      future: futureCustomers,
      builder: (context, snapshot) {
        final customers = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // فیلد جستجوی مشتری
            TextField(
              controller: searchController,
              onChanged: (_) => refresh(),
              decoration: InputDecoration(
                hintText: 'جستجوی نام یا شماره تماس...',
                prefixIcon: Icon(Icons.search, color: AppTheme.primary),
              ),
            ),

            const SizedBox(height: 18),

            // نمایش تعداد کل مشتریان پیدا شده
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightPrimary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: Text(
                'تعداد مشتریان: ${customers.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),

            const SizedBox(height: 20),

            // نمایش لیست مشتریان
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (customers.isEmpty)
              const Center(child: Text('مشتری پیدا نشد'))
            else
              ...customers.map((customer) => CustomerCard(
                customer: customer,
                onRefresh: refreshAllPages,
              )),
          ],
        );
      },
    );
  }
}

// ویجت نمایش کارت هر مشتری
class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onRefresh;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onRefresh,
  });

  // باز کردن دیالوگ برای ویرایش اطلاعات مشتری
  void editCustomer(BuildContext context) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ویرایش اطلاعات مشتری'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'نام مشتری', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'شماره تماس', prefixIcon: Icon(Icons.phone)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('لغو')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.updateCustomer(
                CustomerModel(
                  id: customer.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  createdAt: customer.createdAt,
                ),
              );
              Navigator.pop(context);
              onRefresh();
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  // تولید و چاپ فاکتور برای مشتری
  Future<void> printCustomerInvoice(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final orders = await db.getOrders();
    // فیلتر کردن سفارشات مربوط به همین مشتری
    final customerOrders = orders.where((o) => o.phone == customer.phone).toList();

    if (customerOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سفارشی برای این مشتری یافت نشد')),
      );
      return;
    }

    // فراخوانی کلاس چاپ PDF
    await CustomerReportPdf.printOrders(
      customerOrders,
      'فاکتور مشتری: ${customer.name}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(customer.name),
        subtitle: Text(customer.phone),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // دکمه چاپ فاکتور
            IconButton(
              icon: const Icon(Icons.print, color: Colors.blue),
              onPressed: () => printCustomerInvoice(context),
              tooltip: 'چاپ فاکتور',
            ),
            // دکمه ویرایش
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary),
              onPressed: () => editCustomer(context),
              tooltip: 'ویرایش',
            ),
          ],
        ),
      ),
    );
  }
}
