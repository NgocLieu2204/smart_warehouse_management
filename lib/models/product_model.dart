import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final String uom; // thay vì unit
  final String warehouse;
  final String location;
  final String exp;
  final String imageUrl;
  final int unitPrice;

  const Product({
    required this.id,
    required this.name,
    this.description = "",
    required this.quantity,
    required this.uom,
    required this.warehouse,
    required this.location,
    required this.exp,
    required this.imageUrl,
    required this.unitPrice,
  });

  /// Parse JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0) as int,
      uom: json['unit'] as String, // map unit -> uom
      warehouse: json['warehouse'] ?? '',
      location: json['location'] ?? '',
      exp: json['exp'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      unitPrice: (json['price'] ?? 0) as int, // map price -> unitPrice
    );
  }

  /// Convert về JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': uom,
      'warehouse': warehouse,
      'location': location,
      'exp': exp,
      'imageUrl': imageUrl,
      'price': unitPrice,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        quantity,
        uom,
        warehouse,
        location,
        exp,
        imageUrl,
        unitPrice,
      ];
}
