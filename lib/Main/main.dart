import 'package:flutter/material.dart';
import '../Themes/theme.dart';
import '../Screens/add_order_screen.dart';
import '../Screens/customers_screen.dart';
import '../Screens/home_screen.dart';
import '../Screens/orders_screen.dart';
import '../Screens/setting_screen.dart';

void main() {
  // نقطه شروع برنامه
  runApp(const SadrPrintingApp());
}

class SadrPrintingApp extends StatefulWidget {
  const SadrPrintingApp({super.key});

  @override
  State<SadrPrintingApp> createState() => _SadrPrintingAppState();
}

class _SadrPrintingAppState extends State<SadrPrintingApp> {
  // متغیر برای مدیریت حالت شب و روز
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'چاپخانه صدر',
      
      // تنظیم جهت متن به صورت راست‌به‌چپ برای زبان فارسی
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // تنظیمات تم برنامه
      theme: AppTheme.lightTheme,
      darkTheme: ThemeData.dark(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // صفحه اصلی برنامه
      home: MainPage(
        isDarkMode: isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool) onThemeChanged;

  const MainPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // ایندکس صفحه انتخاب شده در نوار پایین
  int selectedIndex = 0;
  // متغیری برای رفرش کردن صفحات
  int refreshNumber = 0;

  // تابع برای رفرش کردن کل برنامه
  void refreshAll() {
    setState(() => refreshNumber++);
  }

  // تابع برای باز کردن صفحه ثبت سفارش جدید
  Future<void> openAddOrder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddOrderScreen(),
      ),
    );

    // اگر سفارش با موفقیت ثبت شد، صفحات را رفرش کن
    if (result == true) {
      refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('چاپخانه صدر'),
      ),

      // نمایش صفحات مختلف بر اساس انتخاب کاربر
      body: IndexedStack(
        index: selectedIndex,
        children: [
          HomeScreen(
            refreshNumber: refreshNumber,
            onAddOrder: openAddOrder,
          ),
          OrdersScreen(
            refreshNumber: refreshNumber,
            onGlobalRefresh: refreshAll,
          ),
          CustomersScreen(
            refreshNumber: refreshNumber,
            onGlobalRefresh: refreshAll,
          ),
          SettingScreen(
            refreshNumber: refreshNumber,
            onGlobalRefresh: refreshAll,
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
          ),
        ],
      ),

      // نوار ناوبری پایین برنامه
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
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'تنظیمات',
          ),
        ],
      ),
    );
  }
}
