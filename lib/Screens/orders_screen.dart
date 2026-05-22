import 'package:flutter/material.dart';

import '../Themes/theme.dart';
import '../Database/database_helper.dart';
import '../Models/order_model.dart';
import 'add_order_screen.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  final int refreshNumber;
  final VoidCallback onGlobalRefresh;

  const OrdersScreen({
    super.key,
    required this.refreshNumber,
    required this.onGlobalRefresh,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderModel>> futureOrders;

  @override
  void initState() {
    super.initState();
    futureOrders = loadOrders();
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshNumber != widget.refreshNumber) {
      refresh();
    }
  }

  Future<List<OrderModel>> loadOrders() {
    return DatabaseHelper.instance.getOrders();
  }

  void refresh() {
    setState(() {
      futureOrders = loadOrders();
    });
  }

  void refreshAllPages() {
    refresh();
    widget.onGlobalRefresh();
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseHelper.instance.deleteOrder(id);
    refreshAllPages();
  }

  Future<void> openDetails(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(orderId: id),
      ),
    );

    if (result == true) {
      refreshAllPages();
    }
  }

  Future<void> editOrder(OrderModel order) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddOrderScreen(order: order),
      ),
    );

    if (result == true) {
      refreshAllPages();
    }
  }

  Future<void> addOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddOrderScreen(),
      ),
    );

    if (result == true) {
      refreshAllPages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("همه سفارشات"),
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: addOrder,
          child: const Icon(Icons.add),
        ),

        body: FutureBuilder<List<OrderModel>>(
          future: futureOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("هیچ سفارشی وجود ندارد"));
            }

            final orders = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  child: ListTile(
                    onTap: () => openDetails(order.id!),
                    onLongPress: () => editOrder(order),
                    leading: const Icon(Icons.receipt_long),
                    title: Text(order.printType),
                    subtitle: Text(order.customerName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          order.status,
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteOrder(order.id!),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}