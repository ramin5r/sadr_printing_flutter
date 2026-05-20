import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'order_model.dart';
import 'theme.dart';

class AddOrderScreen extends StatefulWidget {
  final OrderModel? order; // اگر برای ویرایش باشد، اطلاعات سفارش اینجا می‌آید

  const AddOrderScreen({super.key, this.order});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final formKey = GlobalKey<FormState>();

  // کنترلرهای فیلدهای متنی برای دریافت ورودی کاربر
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final qtyController = TextEditingController();
  final priceController = TextEditingController();
  final heightController = TextEditingController();
  final widthController = TextEditingController();
  final depositController = TextEditingController();
  final balanceController = TextEditingController();
  final dateController = TextEditingController();
  final notesController = TextEditingController();

  String printType = 'چاپ دیجیتال'; // نوع چاپ پیش‌فرض
  String status = 'در حال انجام'; // وضعیت پیش‌فرض

  bool loading = false; // برای نمایش وضعیت در حال ذخیره

  // لیست انواع چاپ موجود در برنامه
  final List<String> types = [
    'نسخه',
    'چاپ افست',
    'کارت ویزیت',
    'فاکتور',
    'سربرگ',
    'بنر',
    'فلکس',
    'استیکر',
    'وان ویژن',
  ];

  // لیست وضعیت‌های سفارش
  final List<String> statuses = [
    'در حال انجام',
    'چاپ شده',
    'تحویل داده شده',
  ];

  @override
  void initState() {
    super.initState();

    // اگر در حالت ویرایش هستیم، فیلدها را با اطلاعات قبلی پر کن
    if (widget.order != null) {
      final o = widget.order!;
      nameController.text = o.customerName;
      phoneController.text = o.phone;
      qtyController.text = o.quantity.toString();
      priceController.text = o.price.toString();
      heightController.text = o.height?.toString() ?? '';
      widthController.text = o.width?.toString() ?? '';
      depositController.text = o.deposit.toString();
      balanceController.text = o.balance.toString();
      dateController.text = o.deliveryDate;
      notesController.text = o.notes;
      printType = o.printType;
      status = o.status;
    }

    // گوش دادن به تغییرات قیمت و بیعانه برای محاسبه خودکار الباقی
    priceController.addListener(calculateBalance);
    depositController.addListener(calculateBalance);
  }

  // محاسبه مبلغ باقیمانده (قیمت کل منهای بیعانه)
  void calculateBalance() {
    final price = int.tryParse(priceController.text) ?? 0;
    final deposit = int.tryParse(depositController.text) ?? 0;
    balanceController.text = (price - deposit).toString();
  }

  @override
  void dispose() {
    // آزاد کردن حافظه کنترلرها هنگام خروج از صفحه
    nameController.dispose();
    phoneController.dispose();
    qtyController.dispose();
    priceController.dispose();
    heightController.dispose();
    widthController.dispose();
    depositController.dispose();
    balanceController.dispose();
    dateController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // باز کردن تقویم برای انتخاب تاریخ تحویل
  Future<void> pickDeliveryDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate != null) {
      dateController.text = '${pickedDate.year}/${pickedDate.month}/${pickedDate.day}';
    }
  }

  // ذخیره اطلاعات در دیتابیس
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
      height: double.tryParse(heightController.text),
      width: double.tryParse(widthController.text),
      deposit: int.tryParse(depositController.text) ?? 0,
      balance: int.tryParse(balanceController.text) ?? 0,
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
    Navigator.pop(context, true); // بازگشت به صفحه قبل با موفقیت
  }

  // بررسی اینکه آیا باید فیلدهای قد و بر نمایش داده شوند یا خیر
  bool showSizeFields() {
    return printType == 'بنر' || printType == 'فلکس' || printType == 'استیکر' || printType=='وان ویژن';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.order != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'ویرایش سفارش' : 'ثبت سفارش جدید'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            buildField(nameController, 'نام مشتری', Icons.person),
            buildField(phoneController, 'شماره تماس', Icons.phone, type: TextInputType.number),

            const SizedBox(height: 12),

            // انتخاب نوع چاپ
            DropdownButtonFormField<String>(
              value: printType,
              items: types.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => printType = v!),
              decoration: inputDecoration('نوع چاپ', Icons.print),
            ),

            // نمایش شرطی فیلدهای قد و بر
            if (showSizeFields()) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: buildField(heightController, 'قد (ارتفاع)', Icons.height, type: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: buildField(widthController, 'بر (عرض)', Icons.width_full, type: TextInputType.number)),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // انتخاب وضعیت سفارش
            DropdownButtonFormField<String>(
              value: status,
              items: statuses.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => status = v!),
              decoration: inputDecoration('وضعیت سفارش', Icons.flag),
            ),

            const SizedBox(height: 12),

            buildField(qtyController, 'تعداد', Icons.numbers, type: TextInputType.number),
            buildField(priceController, 'قیمت کل (افغانی)', Icons.money, type: TextInputType.number),

            // فیلدهای بیعانه و الباقی در یک ردیف
            Row(
              children: [
                Expanded(child: buildField(depositController, 'بیعانه', Icons.payments, type: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: buildField(balanceController, 'الباقی', Icons.account_balance_wallet, type: TextInputType.number, readOnly: true)),
              ],
            ),

            buildField(dateController, 'تاریخ تحویل', Icons.date_range, readOnly: true, onTap: pickDeliveryDate),
            buildField(notesController, 'توضیحات اضافی', Icons.note, maxLines: 3, required: false),

            const SizedBox(height: 20),

            // دکمه ذخیره
            ElevatedButton.icon(
              onPressed: loading ? null : saveOrder,
              icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(isEdit ? 'ذخیره تغییرات' : 'ثبت سفارش'),
            ),
          ],
        ),
      ),
    );
  }

  // تابع کمکی برای ساخت فیلدهای متنی
  Widget buildField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1, bool required = true, bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: required ? (v) => v == null || v.isEmpty ? 'این فیلد ضروری است' : null : null,
        decoration: inputDecoration(label, icon),
      ),
    );
  }

  // استایل فیلدهای ورودی
  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primary),
    );
  }
}
