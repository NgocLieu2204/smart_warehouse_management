import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/product_repository.dart';
import 'package:smart_warehouse_manager/models/product_model.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;

  ProductBloc(this._productRepository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<LoadTotalProducts>(_onLoadTotalProducts);
  }

  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      final products = await _productRepository.getAllProducts();
      emit(ProductLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onAddProduct(
      AddProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await _productRepository.addProduct(Product(
        id: event.product['id'],
        name: event.product['name'],
        description: event.product['description'] ?? '',
        quantity: event.product['quantity'],
        uom: event.product['unit'], // API trả về unit → map sang uom
        warehouse: event.product['warehouse'],
        location: event.product['location'],
        exp: event.product['exp'],
        imageUrl: event.product['imageUrl'] ?? '',
        unitPrice: event.product['price'], // API trả về price → unitPrice
      ));

      add(LoadProducts());
      add(LoadTotalProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await _productRepository.updateProduct(Product(
        id: event.productId,
        name: event.updatedData['name'],
        description: event.updatedData['description'] ?? '',
        quantity: event.updatedData['quantity'],
        uom: event.updatedData['unit'], // map lại unit → uom
        warehouse: event.updatedData['warehouse'],
        location: event.updatedData['location'],
        exp: event.updatedData['exp'],
        imageUrl: event.updatedData['imageUrl'] ?? '',
        unitPrice: event.updatedData['price'],
      ));

      add(LoadProducts());
      add(LoadTotalProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await _productRepository.deleteProduct(event.productId);
      add(LoadProducts());
      add(LoadTotalProducts());
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onLoadTotalProducts(
      LoadTotalProducts event, Emitter<ProductState> emit) async {
    try {
      final total = await _productRepository.getTotalQuantity();
      emit(TotalProductsLoaded(total));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }
}
