import 'package:flutter/material.dart';
import '../Themes/theme.dart';
import '../Database/database_helper.dart';
import '../Models/order_model.dart';
import 'order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final int refreshNumber;
  final VoidCallback onAddOrder;

  const HomeScreen({
    super.key,
    required this.refreshNumber,
    required this.onAddOrder,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class HomeData {
  final int all;
  final int doing;
  final int printed;
  final int delivered;
  final List<OrderModel> orders;

  HomeData({
    required this.all,
    required this.doing,
    required this.printed,
    required this.delivered,
    required this.orders,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // اگر از جای دیگری دستور رفرش صادر شد، صفحه را بروزرسانی کن
    if (oldWidget.refreshNumber != widget.refreshNumber) {
      setState(() {});
    }
  }

  // دریافت اطلاعات آمار و آخرین سفارش‌ها از دیتابیس
  Future<HomeData> loadData() async {
    final db = DatabaseHelper.instance;
    final allOrders = await db.getOrders();

    return HomeData(
      all: await db.countAllOrders(),
      doing: await db.countOrdersByStatus('در حال انجام'),
      printed: await db.countOrdersByStatus('چاپ شده'),
      delivered: await db.countOrdersByStatus('تحویل داده شده'),
      orders: allOrders.take(5).toList(), // فقط ۵ سفارش آخر را نمایش بده
    );
  }

  // باز کردن صفحه جزئیات سفارش
  Future<void> openDetails(int id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(orderId: id),
      ),
    );
    setState(() {}); // بعد از برگشت از صفحه جزئیات، آمار را بروزرسانی کن
  }

  // ویجت نمایش هر باکس آمار (تعداد سفارشات)
  Widget statBox(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("هیچ سفارشی ثبت نشده است"));
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // نمایش باکس‌های آمار در دو ردیف
              Row(
                children: [
                  statBox("همه سفارشات", data.all, Icons.receipt_long),
                  statBox("در حال انجام", data.doing, Icons.pending),
                ],
              ),
              Row(
                children: [
                  statBox("چاپ شده", data.printed, Icons.print),
                  statBox("تحویل داده شده", data.delivered, Icons.local_shipping),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "آخرین سفارش‌ها",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),

              const SizedBox(height: 10),

              // لیست آخرین سفارش‌ها
              if (data.orders.isEmpty)
                const Center(child: Text("هیچ سفارشی وجود ندارد"))
              else
                ...data.orders.map((order) {
                  return Card(
                    child: ListTile(
                      onTap: () => openDetails(order.id!),
                      leading: const Icon(Icons.receipt_long),
                      title: Text(order.printType),
                      subtitle: Text(order.customerName),
                      trailing: Text(
                        order.status,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
