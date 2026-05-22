class CustomerModel {
  final int? id;
  final String name;
  final String phone;
  final String createdAt;

  CustomerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'createdAt': createdAt,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      createdAt: map['createdAt'] as String,
    );
  }
}
