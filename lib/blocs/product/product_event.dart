import 'package:equatable/equatable.dart';

class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {}

class AddProduct extends ProductEvent {
  final Map<String, dynamic> product;

  const AddProduct(this.product);

  @override
  List<Object?> get props => [product];
}

class UpdateProduct extends ProductEvent {
  final String productId;
  final Map<String, dynamic> updatedData;

  const UpdateProduct(this.productId, this.updatedData);

  @override
  List<Object?> get props => [productId, updatedData];
}

class DeleteProduct extends ProductEvent {
  final String productId;

  const DeleteProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

class LoadTotalProducts extends ProductEvent {} 