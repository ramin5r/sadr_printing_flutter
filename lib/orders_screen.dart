import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_model.dart';
import 'add_order_screen.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {

  Future<List<OrderModel>> loadOrders() {
    return DatabaseHelper.instance.getOrders();
  }

  Future<void> refresh() async {
    setState(() {});
  }

  Future<void> deleteOrder(int id) async {
    await DatabaseHelper.instance.deleteOrder(id);
    refresh();
  }

  Future<void> openDetails(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailsScreen(orderId: id),
      ),
    );

    if (result == true) {
      refresh();
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
      refresh();
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
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("همه سفارشات"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: addOrder,
        child: const Icon(Icons.add),
      ),

      body: FutureBuilder<List<OrderModel>>(
        future: loadOrders(), // ✔ مهم‌ترین اصلاح
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

                  title: Text(order.printType),
                  subtitle: Text(order.customerName),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(order.status),
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
    );
  }
}