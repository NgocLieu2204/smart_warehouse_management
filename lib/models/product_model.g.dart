// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toInt(),
      unit: json['unit'] as String,
      barcode: json['barcode'] as String,
      exp: json['exp'] as String,
      location: json['location'] as String,
      imageUrl: json['imageUrl'] as String,
    );

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'barcode': instance.barcode,
      'exp': instance.exp,
      'location': instance.location,
      'imageUrl': instance.imageUrl,
    };
