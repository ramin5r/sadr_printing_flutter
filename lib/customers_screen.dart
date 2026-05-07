import 'package:flutter/material.dart';

import 'theme.dart';
import 'customer_model.dart';
import 'database_helper.dart';

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
    if (oldWidget.refreshNumber != widget.refreshNumber) refresh();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<CustomerModel>> loadCustomers() {
    return DatabaseHelper.instance.getCustomers(
      search: searchController.text.trim(),
    );
  }

  void refresh() {
    setState(() {
      futureCustomers = loadCustomers();
    });
  }

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
            TextField(
              controller: searchController,
              onChanged: (_) => refresh(),
              decoration: InputDecoration(
                hintText: 'جستجوی نام یا شماره...',
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.lightPrimary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.15),
                ),
              ),
              child: Text(
                'تعداد مشتریان: ${customers.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (customers.isEmpty)
              const Center(child: Text('مشتری پیدا نشد'))
            else
              ...customers.map(
                    (customer) => CustomerCard(
                  customer: customer,
                  onRefresh: refreshAllPages,
                ),
              ),
          ],
        );
      },
    );
  }
}

class CustomerCard extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onRefresh;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onRefresh,
  });

  void editCustomer(BuildContext context) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ویرایش مشتری'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'نام مشتری',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'شماره تماس',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => editCustomer(context),
        leading: const Icon(Icons.person),
        title: Text(customer.name),
        subtitle: Text(customer.phone),

        // دکمه حذف پاک شد
        trailing: const Icon(
          Icons.edit,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}