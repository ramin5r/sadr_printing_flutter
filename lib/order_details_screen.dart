import 'package:flutter/material.dart';

import '../theme.dart';
import '/database_helper.dart';
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

  void _load() {
    futureOrder = DatabaseHelper.instance.getOrderById(widget.orderId);
  }

  void _refresh() {
    setState(() {
      _load();
    });
  }

  Future<void> changeStatus(String status) async {
    await DatabaseHelper.instance.updateOrderStatus(
      widget.orderId,
      status,
    );

    _refresh();

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

                Row(
                  children: [
                    Expanded(
                      child: statusBox(
                        'در حال انجام',
                        Icons.pending,
                        order.status,
                        changeStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: statusBox(
                        'چاپ شده',
                        Icons.print,
                        order.status,
                        changeStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: statusBox(
                        'تحویل داده شده',
                        Icons.local_shipping,
                        order.status,
                        changeStatus,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _info(
                  Icons.person,
                  'مشتری',
                  '${order.customerName}\n${order.phone}',
                ),

                _info(
                  Icons.print,
                  'چاپ',
                  'نوع: ${order.printType}\nتعداد: ${order.quantity}',
                ),

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

  Widget statusBox(
    String title,
    IconData icon,
    String currentStatus,
    Function(String) onTap,
  ) {
    final isSelected = title == currentStatus;

    return GestureDetector(
      onTap: () => onTap(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.lightPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.primary.withOpacity(0.15),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String title, String text) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.primary,
        ),
        title: Text(title),
        subtitle: Text(text),
      ),
    );
  }
}
