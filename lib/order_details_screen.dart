import 'package:flutter/material.dart';
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

  // ================= LOAD =================
  void _load() {
    futureOrder = DatabaseHelper.instance.getOrderById(widget.orderId);
  }

  void _refresh() {
    setState(() {
      _load();
    });
  }

  // ================= CHANGE STATUS =================
  Future<void> changeStatus(String status) async {
    await DatabaseHelper.instance.updateOrderStatus(
      widget.orderId,
      status,
    );

    // refresh UI
    _refresh();

    // مهم: خبر دادن به صفحه Home
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات سفارش'),
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

                // ================= HEADER =================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سفارش #${order.id}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0056D2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.printType,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= STATUS =================
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Text(
                          'تغییر وضعیت',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        Wrap(
                          spacing: 8,
                          children: statuses.map((status) {
                            final isSelected = status == order.status;

                            return ChoiceChip(
                              label: Text(status),
                              selected: isSelected,
                              onSelected: (_) => changeStatus(status),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ================= INFO =================
                _info(Icons.person, 'مشتری',
                    '${order.customerName}\n${order.phone}'),

                _info(Icons.print, 'چاپ',
                    'نوع: ${order.printType}\nتعداد: ${order.quantity}'),

                _info(Icons.payments, 'قیمت', '${order.price}'),

                _info(Icons.calendar_today, 'تاریخ', order.deliveryDate),

                if (order.notes.isNotEmpty)
                  _info(Icons.note, 'توضیحات', order.notes),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= INFO WIDGET =================
  Widget _info(IconData icon, String title, String text) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(text),
      ),
    );
  }
}