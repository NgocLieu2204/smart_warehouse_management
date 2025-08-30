import 'package:dio/dio.dart';
import 'package:smart_warehouse_manager/models/product_model.dart';

class ProductRepository {
  final Dio _dio;

  ProductRepository(this._dio);

  // Base path cho product API
  final String _productPath = 'http://10.0.2.2:5000/api/inventory';


  Future<List<Product>> getAllProducts() async {
    try {
      // URL đầy đủ sẽ là: http://localhost:5000/api/product/getAllProduct
      final response = await _dio.get('$_productPath/getInventory');
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data;
        return data.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      throw Exception('Failed to fetch products');
    }
  }
  

  Future<Product?> fetchProductById(String id) async {
    try {
      final response = await _dio.get('$_productPath/getInventory/$id');
      return Product.fromJson(response.data);
    } catch (e) {
      print('Error fetching product by id: $e');
      return null;
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      // Endpoint để thêm sản phẩm mới
      await _dio.post('$_productPath/createInventory', data: product.toJson());
      return true;
    } catch (e) {
      print('Error adding product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      await _dio.put('$_productPath/updateInventory/${product.id}', data: product.toJson());
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _dio.delete('$_productPath/deleteInventory/$id');
      return true;
    } catch (e) {
      print('Error deleting product: $e');
      return false;
    }
  }
  Future<int> getTotalQuantity() async {
    try {
      final response = await _dio.get('$_productPath/getAllQuantityInventory');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['totalQuantity'] ?? 0;
      }
      return 0;
    } catch (e) {
      throw Exception("Failed to fetch products: $e");
    }
  }
}