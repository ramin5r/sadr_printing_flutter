import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'customer_model.dart';
import 'order_model.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'sadr_printing.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

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
        deliveryDate TEXT NOT NULL,
        notes TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // ================= INSERT =================
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

  // ================= ORDERS =================
  Future<List<OrderModel>> getOrders() async {
    final db = await database;

    final res = await db.query('orders', orderBy: 'id DESC');

    return res.map((e) => OrderModel.fromMap(e)).toList();
  }

  Future<OrderModel?> getOrderById(int id) async {
    final db = await database;

    final res = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (res.isEmpty) return null;
    return OrderModel.fromMap(res.first);
  }

  Future<int> updateOrder(OrderModel order) async {
    final db = await database;

    return db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> updateOrderStatus(int id, String status) async {
    final db = await database;

    return db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= DELETE ORDER =================
  Future<int> deleteOrder(int id) async {
    final db = await database;

    final order = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (order.isEmpty) return 0;

    final phone = order.first['phone'] as String;

    return db.transaction<int>((txn) async {

      final result = await txn.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
      );

      final remainingOrders = await txn.query(
        'orders',
        where: 'phone = ?',
        whereArgs: [phone],
      );

      if (remainingOrders.isEmpty) {
        await txn.delete(
          'customers',
          where: 'phone = ?',
          whereArgs: [phone],
        );
      }

      return result;
    });
  }

  // ================= DELETE CUSTOMER =================
  Future<int> deleteCustomer(int id) async {
    final db = await database;

    return db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= UPDATE CUSTOMER =================
  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await database;

    final old = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customer.id],
      limit: 1,
    );

    if (old.isEmpty) return 0;

    final oldPhone = old.first['phone'] as String;

    return db.transaction<int>((txn) async {

      final result = await txn.update(
        'customers',
        customer.toMap(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );

      await txn.update(
        'orders',
        {
          'customerName': customer.name,
          'phone': customer.phone,
        },
        where: 'phone = ?',
        whereArgs: [oldPhone],
      );

      return result;
    });
  }

  // ================= CUSTOMERS =================
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


  Future<List<CustomerModel>> getAllCustomers() async {
    final db = await database;

    final res = await db.query(
      'customers',
      orderBy: 'id DESC',
    );

    return res.map((e) => CustomerModel.fromMap(e)).toList();
  }

  Future<List<CustomerModel>> getCustomersLast24Hours() async {
    final db = await database;

    final since = DateTime.now()
        .subtract(const Duration(hours: 24))
        .toIso8601String();

    final res = await db.query(
      'customers',
      where: 'createdAt >= ?',
      whereArgs: [since],
      orderBy: 'id DESC',
    );

    return res.map((e) => CustomerModel.fromMap(e)).toList();
  }

  // ================= COUNTERS =================
  Future<int> countAllOrders() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) FROM orders');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<int> countOrdersByStatus(String status) async {
    final db = await database;
    final res = await db.rawQuery(
      'SELECT COUNT(*) FROM orders WHERE status = ?',
      [status],
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }
}