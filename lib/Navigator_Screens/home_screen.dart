import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../order_model.dart';
import '../add_order_screen.dart';
import '../order_details_screen.dart';

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

// ================= MODEL =================
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

// ================= STATE =================
class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {

  Future<HomeData>? futureData;

  // 🚀 init
  @override
  void initState() {
    super.initState();

    // 👇 برای تشخیص برگشت به اپ
    WidgetsBinding.instance.addObserver(this);

    _load();
  }

  // 🔁 وقتی اپ دوباره فعال شد (مثلاً برگشتی از صفحه دیگر)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(); // 🔥 auto refresh واقعی
    }
  }

  // 🔁 وقتی از بیرون refreshNumber تغییر کرد
  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshNumber != widget.refreshNumber) {
      _load();
    }
  }

  // ================= LOAD =================
  void _load() {
    setState(() {
      futureData = loadData();
    });
  }

  Future<HomeData> loadData() async {
    final db = DatabaseHelper.instance;
    final allOrders = await db.getOrders();

    return HomeData(
      all: await db.countAllOrders(),
      doing: await db.countOrdersByStatus('در حال انجام'),
      printed: await db.countOrdersByStatus('چاپ شده'),
      delivered: await db.countOrdersByStatus('تحویل داده شده'),
      orders: allOrders.take(5).toList(),
    );
  }

  // ================= REFRESH =================
  Future<void> refresh() async {
    _load();
  }

  // ================= DETAILS =================
  Future<void> openDetails(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(orderId: id),
      ),
    );

    if (result == true) {
      _load();
    }
  }

  // ================= UI BOX =================
  Widget statBox(String title, int value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: futureData,
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("هیچ سفارشی ثبت نشده است"));
        }

        final data = snapshot.data!;

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ================= STATS =================
              Row(
                children: [
                  statBox("همه", data.all),
                  statBox("در حال انجام", data.doing),
                ],
              ),
              Row(
                children: [
                  statBox("چاپ شده", data.printed),
                  statBox("تحویل", data.delivered),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "آخرین سفارش‌ها",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // ================= LIST =================
              if (data.orders.isEmpty)
                const Center(child: Text("هیچ سفارشی وجود ندارد"))
              else
                ...data.orders.map((order) {
                  return Card(
                    child: ListTile(
                      onTap: () => openDetails(order.id!),
                      title: Text(order.printType),
                      subtitle: Text(order.customerName),
                      trailing: Text(order.status),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}