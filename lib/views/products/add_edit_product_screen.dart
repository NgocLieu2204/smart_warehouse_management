import 'package:flutter/material.dart';
import 'package:smart_warehouse_manager/models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  _AddEditProductScreenState createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _expController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _barcodeController.text = widget.product!.barcode;
      _expController.text = widget.product!.exp; // 🔥 exp là String
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _expController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: widget.product?.description ?? '',
        quantity: widget.product?.quantity ?? 0,
        unit: widget.product?.unit ?? '',
        barcode: _barcodeController.text,
        exp: _expController.text, // 🔥 nhập string
        location: widget.product?.location ?? '',
        imageUrl: widget.product?.imageUrl ?? '',
      );

      // TODO: dispatch event Bloc hoặc gọi repository để lưu product
      Navigator.pop(context, product);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a barcode' : null,
              ),
              TextFormField(
                controller: _expController,
                decoration: const InputDecoration(labelText: 'Expiry (exp)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter expiry' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
