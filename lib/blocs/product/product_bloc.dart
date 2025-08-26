
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/product_repository.dart';
import 'package:smart_warehouse_manager/models/product_model.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent,ProductState> {
  final ProductRepository _productRepository;

  ProductBloc(this._productRepository) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }
  
  
  Future<void> _onLoadProducts(LoadProducts event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      
      final products = await _productRepository.getAllProducts();
      emit(ProductLoaded(products));

    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onAddProduct(AddProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await _productRepository.addProduct(Product(
        id: event.product['id'],
        name: event.product['name'],
        description: event.product['description'],
        quantity: event.product['quantity'],
        unit: event.product['unit'],
        barcode: event.product['barcode'],
        exp: event.product['exp'], // 🔥 String nhập trực tiếp
        location: event.product['location'],
        imageUrl: event.product['imageUrl'] ?? '',
      ));

      add(LoadProducts()); // Reload products after adding
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(UpdateProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
        await _productRepository.updateProduct(Product(
          id: event.productId,
          name: event.updatedData['name'],
          description: event.updatedData['description'],
          quantity: event.updatedData['quantity'],
          unit: event.updatedData['unit'],
          barcode: event.updatedData['barcode'],
          exp: event.updatedData['exp'], // 🔥 String
          location: event.updatedData['location'],
          imageUrl: event.updatedData['imageUrl'] ?? '',
        ));
      add(LoadProducts()); 
    } catch (e) {
      emit(ProductError(e.toString())); 
    }
  }

  Future<void> _onDeleteProduct(DeleteProduct event, Emitter<ProductState> emit) async {
    emit(ProductLoading());
    try {
      await _productRepository.deleteProduct(event.productId);
      add(LoadProducts()); // Reload products after deletion
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  } 
}