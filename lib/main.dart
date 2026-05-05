import 'package:flutter/material.dart';

import 'add_order_screen.dart';
import 'customers_screen.dart';
import 'Navigator_Screens/home_screen.dart';
import 'Navigator_Screens/orders_screen.dart'; // 👈 اضافه شد

void main() {
  runApp(const SadrPrintingApp());
}
class SadrPrintingApp extends StatelessWidget {
  const SadrPrintingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'چاپخانه صدر',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056D2),
        ),
        fontFamily: 'sans',
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  int refreshNumber = 0;

  void refreshAll() {
    setState(() => refreshNumber++);
  }

  Future<void> openAddOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddOrderScreen(),
      ),
    );

    if (result == true) {
      refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('چاپخانه صدر'),
      ),

      body: IndexedStack(
        index: selectedIndex,
        children: [
          // 🏠 HOME (5 سفارش آخر)
          HomeScreen(
            refreshNumber: refreshNumber,
            onAddOrder: openAddOrder,
          ),

          // 📦 ORDERS (همه سفارشات)
          OrdersScreen(),

          // 👥 Customers
          CustomersScreen(
            refreshNumber: refreshNumber,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddOrder,
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'سفارشات',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'مشتریان',
          ),
        ],
      ),
    );
  }
}