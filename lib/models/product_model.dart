import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class Product extends Equatable {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final String unit;
  final String barcode;
  final String exp; // 🔥 đổi từ DateTime expiryDate -> String exp
  final String location;
  final String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.barcode,
    required this.exp, // 🔥
    required this.location,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJson() => _$ProductToJson(this);

  @override
  List<Object?> get props =>
      [id, name, description, quantity, unit, barcode, exp, location, imageUrl];
}
