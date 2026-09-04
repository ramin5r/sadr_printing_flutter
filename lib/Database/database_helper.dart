import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../Models/customer_model.dart';
import '../Models/order_model.dart';

class DatabaseHelper {
  // الگوی Singleton برای اطمینان از وجود تنها یک نمونه از کلاس دیتابیس
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  // دریافت دیتابیس (اگر ساخته نشده باشد، آن را می‌سازد)
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  // راه‌اندازی دیتابیس و تعیین مسیر ذخیره‌سازی
  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'sadr_printing.db');
    return openDatabase(
      path,
      version: 2, // نسخه دیتابیس
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE orders ADD COLUMN height REAL');
          await db.execute('ALTER TABLE orders ADD COLUMN width REAL');
          await db.execute('ALTER TABLE orders ADD COLUMN deposit INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE orders ADD COLUMN balance INTEGER DEFAULT 0');
        }
      },
    );
  }

  // ایجاد جداول مورد نیاز
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL UNIQUE,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        phone TEXT NOT NULL,
        printType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL,
        height REAL,
        width REAL,
        deposit INTEGER NOT NULL DEFAULT 0,
        balance INTEGER NOT NULL DEFAULT 0,
        deliveryDate TEXT NOT NULL,
        notes TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ثبت سفارش جدید و اضافه کردن مشتری
  Future<void> addOrderAndCustomer(OrderModel order) async {
    final db = await database;
    await db.insert(
      'customers',
      CustomerModel(
        name: order.customerName,
        phone: order.phone,
        createdAt: DateTime.now().toIso8601String(),
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    await db.insert('orders', order.toMap());
  }

  // دریافت لیست تمام سفارشات
  Future<List<OrderModel>> getOrders() async {
    final db = await database;
    final res = await db.query('orders', orderBy: 'id DESC');
    return res.map((e) => OrderModel.fromMap(e)).toList();
  }

  // دریافت اطلاعات یک سفارش خاص
  Future<OrderModel?> getOrderById(int id) async {
    final db = await database;
    final res = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return OrderModel.fromMap(res.first);
  }

  // بروزرسانی اطلاعات یک سفارش
  Future<int> updateOrder(OrderModel order) async {
    final db = await database;
    return db.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
  }

  // بروزرسانی فقط وضعیت یک سفارش (مثلاً از در حال انجام به چاپ شده)
  Future<int> updateOrderStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حذف یک سفارش
  Future<int> deleteOrder(int id) async {
    final db = await database;
    final order = await db.query('orders', where: 'id = ?', whereArgs: [id], limit: 1);
    if (order.isEmpty) return 0;

    final phone = order.first['phone'] as String;

    return db.transaction<int>((txn) async {
      final result = await txn.delete('orders', where: 'id = ?', whereArgs: [id]);
      final remainingOrders = await txn.query('orders', where: 'phone = ?', whereArgs: [phone]);
      if (remainingOrders.isEmpty) {
        await txn.delete('customers', where: 'phone = ?', whereArgs: [phone]);
      }
      return result;
    });
  }

  // دریافت لیست مشتریان با قابلیت جستجو
  Future<List<CustomerModel>> getCustomers({String search = ''}) async {
    final db = await database;
    final res = await db.query(
      'customers',
      where: search.isEmpty ? null : 'name LIKE ? OR phone LIKE ?',
      whereArgs: search.isEmpty ? null : ['%$search%', '%$search%'],
      orderBy: 'id DESC',
    );
    return res.map((e) => CustomerModel.fromMap(e)).toList();
  }

  // بروزرسانی اطلاعات مشتری
  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await database;
    final old = await db.query('customers', where: 'id = ?', whereArgs: [customer.id], limit: 1);
    if (old.isEmpty) return 0;

    final oldPhone = old.first['phone'] as String;

    return db.transaction<int>((txn) async {
      final result = await txn.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
      await txn.update(
        'orders',
        {'customerName': customer.name, 'phone': customer.phone},
        where: 'phone = ?',
        whereArgs: [oldPhone],
      );
      return result;
    });
  }

  // دریافت تمام جزئیات سفارشات مشتریان برای گزارش‌گیری
  Future<List<OrderModel>> getAllCustomerOrderDetails() async {
    final db = await database;
    final res = await db.query('orders', orderBy: 'id DESC');
    return res.map((e) => OrderModel.fromMap(e)).toList();
  }

  // دریافت سفارش‌های ثبت‌شده در ۲۴ ساعت گذشته
  Future<List<OrderModel>> getNewCustomerOrderDetailsLast24Hours() async {
    final db = await database;

    final since = DateTime.now()
        .subtract(const Duration(hours: 24))
        .toIso8601String();

    final res = await db.query(
      'orders',
      where: 'createdAt >= ?',
      whereArgs: [since],
      orderBy: 'id DESC',
    );

    return res.map((e) => OrderModel.fromMap(e)).toList();
  }

  // توابع شمارش برای آمار
  Future<int> countAllOrders() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) FROM orders');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> countOrdersByStatus(String status) async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) FROM orders WHERE status = ?', [status]);
    return Sqflite.firstIntValue(res) ?? 0;
  }
}
