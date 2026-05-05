import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_model.dart';

class AddOrderScreen extends StatefulWidget {
  final OrderModel? order;

  const AddOrderScreen({super.key, this.order});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final dateController = TextEditingController();
  final notesController = TextEditingController();

  String printType = 'چاپ دیجیتال';
  String status = 'در حال انجام'; // ⭐ مهم اضافه شد

  bool loading = false;

  final List<String> types = [
    'چاپ دیجیتال',
    'چاپ افست',
    'کارت ویزیت',
    'تراکت',
    'کاتالوگ',
  ];

  final List<String> statuses = [
    'در حال انجام',
    'چاپ شده',
    'تحویل داده شده',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.order != null) {
      final o = widget.order!;

      nameController.text = o.customerName;
      phoneController.text = o.phone;
      qtyController.text = o.quantity.toString();
      priceController.text = o.price.toString();
      dateController.text = o.deliveryDate;
      notesController.text = o.notes;

      printType = o.printType;
      status = o.status; // ⭐ مهم
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    qtyController.dispose();
    priceController.dispose();
    dateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> saveOrder() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final order = OrderModel(
      id: widget.order?.id,
      customerName: nameController.text.trim(),
      phone: phoneController.text.trim(),
      printType: printType,
      quantity: int.tryParse(qtyController.text) ?? 0,
      price: int.tryParse(priceController.text) ?? 0,
      deliveryDate: dateController.text.trim(),
      notes: notesController.text.trim(),
      status: status,
      createdAt: widget.order?.createdAt ?? DateTime.now().toIso8601String(),
    );

    if (widget.order == null) {
      await DatabaseHelper.instance.addOrderAndCustomer(order);
    } else {
      await DatabaseHelper.instance.updateOrder(order);
    }

    if (!mounted) return;

    setState(() => loading = false);

    // ⭐ مهم: برای refresh Home
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.order != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش سفارش' : 'ثبت سفارش'),
      ),

      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            buildField(nameController, 'نام مشتری', Icons.person),
            buildField(phoneController, 'شماره تماس', Icons.phone,
                type: TextInputType.phone),

            const SizedBox(height: 12),

            // ================= TYPE =================
            DropdownButtonFormField<String>(
              value: printType,
              items: types
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => printType = v!),
              decoration: inputDecoration('نوع چاپ', Icons.print),
            ),

            const SizedBox(height: 12),

            // ================= STATUS (مهم اضافه شد) =================
            DropdownButtonFormField<String>(
              value: status,
              items: statuses
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => status = v!),
              decoration: inputDecoration('وضعیت', Icons.flag),
            ),

            const SizedBox(height: 12),

            buildField(qtyController, 'تعداد', Icons.numbers,
                type: TextInputType.number),

            buildField(priceController, 'قیمت', Icons.money,
                type: TextInputType.number),

            buildField(dateController, 'تاریخ تحویل', Icons.date_range),

            buildField(notesController, 'توضیحات', Icons.note,
                maxLines: 3, required: false),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: loading ? null : saveOrder,
              icon: loading
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(isEdit ? 'ذخیره تغییرات' : 'ثبت سفارش'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType type = TextInputType.text,
        int maxLines = 1,
        bool required = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        validator: required
            ? (v) => v == null || v.isEmpty ? 'ضروری است' : null
            : null,
        decoration: inputDecoration(label, icon),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}