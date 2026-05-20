import 'package:flutter/material.dart';
import 'theme.dart';
import 'database_helper.dart';
import 'order_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<OrderModel?> futureOrder;

  // لیست وضعیت‌های ممکن برای سفارش
  final List<String> statuses = [
    'در حال انجام',
    'چاپ شده',
    'تحویل داده شده',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  // بارگذاری اطلاعات سفارش از دیتابیس
  void _load() {
    futureOrder = DatabaseHelper.instance.getOrderById(widget.orderId);
  }

  // رفرش کردن صفحه
  void _refresh() {
    setState(() {
      _load();
    });
  }

  // تغییر وضعیت سفارش (مثلاً از در حال انجام به چاپ شده)
  Future<void> changeStatus(String status) async {
    await DatabaseHelper.instance.updateOrderStatus(
      widget.orderId,
      status,
    );
    _refresh();
    if (mounted) {
      Navigator.pop(context, true); // بازگشت به صفحه قبل و اطلاع‌رسانی برای رفرش
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات کامل سفارش'),
      ),
      body: FutureBuilder<OrderModel?>(
        future: futureOrder,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('سفارش پیدا نشد'));
          }

          final order = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // نمایش نوع چاپ در بالای صفحه
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      order.printType,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // بخش تغییر وضعیت سفارش به صورت دکمه‌های تعاملی
                Row(
                  children: [
                    Expanded(child: statusBox('در حال انجام', Icons.pending, order.status, changeStatus)),
                    const SizedBox(width: 8),
                    Expanded(child: statusBox('چاپ شده', Icons.print, order.status, changeStatus)),
                    const SizedBox(width: 8),
                    Expanded(child: statusBox('تحویل داده شده', Icons.local_shipping, order.status, changeStatus)),
                  ],
                ),

                const SizedBox(height: 16),

                // اطلاعات مشتری
                _info(Icons.person, 'اطلاعات مشتری', 'نام: ${order.customerName}\nشماره تماس: ${order.phone}'),

                // اطلاعات چاپ و ابعاد (اگر موجود باشد)
                _info(
                  Icons.print,
                  'جزئیات چاپ',
                  'نوع: ${order.printType}\nتعداد: ${order.quantity}' +
                  ((order.height != null || order.width != null) 
                    ? '\nابعاد: ${order.height ?? 0} (قد) × ${order.width ?? 0} (بر)' 
                    : ''),
                ),

                // اطلاعات مالی (قیمت کل، بیعانه و الباقی)
                _info(
                  Icons.payments,
                  'اطلاعات مالی',
                  'قیمت کل: ${order.price} افغانی\n'
                  'بیعانه پرداختی: ${order.deposit} افغانی\n'
                  'باقیمانده (الباقی): ${order.balance} افغانی',
                ),

                // تاریخ تحویل
                _info(Icons.calendar_today, 'زمان تحویل', order.deliveryDate),

                // توضیحات اضافی (اگر وجود داشته باشد)
                if (order.notes.isNotEmpty)
                  _info(Icons.note, 'توضیحات اضافی', order.notes),
              ],
            ),
          );
        },
      ),
    );
  }

  // ویجت دکمه‌های وضعیت سفارش
  Widget statusBox(String title, IconData icon, String currentStatus, Function(String) onTap) {
    final isSelected = title == currentStatus;
    return GestureDetector(
      onTap: () => onTap(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.lightPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.white : AppTheme.primary),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppTheme.primary)),
          ],
        ),
      ),
    );
  }

  // ویجت نمایش هر ردیف اطلاعات
  Widget _info(IconData icon, String title, String text) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
