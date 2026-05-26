class OrderModel {
  final int? id;
  final String customerName;
  final String phone;
  final String printType;
  final int quantity;
  final int price;
  final double? height;
  final double? width;
  final int deposit;
  final int balance;
  final String deliveryDate;
  final String notes;
  final String status;
  final String createdAt;

  OrderModel({
    this.id,
    required this.customerName,
    required this.phone,
    required this.printType,
    required this.quantity,
    required this.price,
    this.height,
    this.width,
    required this.deposit,
    required this.balance,
    required this.deliveryDate,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'phone': phone,
      'printType': printType,
      'quantity': quantity,
      'price': price,
      'height': height,
      'width': width,
      'deposit': deposit,
      'balance': balance,
      'deliveryDate': deliveryDate,
      'notes': notes,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as int?,
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      printType: map['printType'] ?? '',
      quantity: (map['quantity'] is int)
          ? map['quantity']
          : int.tryParse(map['quantity'].toString()) ?? 0,
      price: (map['price'] is int)
          ? map['price']
          : int.tryParse(map['price'].toString()) ?? 0,
      height: map['height'] != null ? double.tryParse(map['height'].toString()) : null,
      width: map['width'] != null ? double.tryParse(map['width'].toString()) : null,
      deposit: (map['deposit'] is int)
          ? map['deposit']
          : int.tryParse(map['deposit']?.toString() ?? '0') ?? 0,
      balance: (map['balance'] is int)
          ? map['balance']
          : int.tryParse(map['balance']?.toString() ?? '0') ?? 0,
      deliveryDate: map['deliveryDate'] ?? '',
      notes: map['notes'] ?? '',
      status: map['status'] ?? '',
      createdAt: map['createdAt'] ?? '',
    );
  }
}
