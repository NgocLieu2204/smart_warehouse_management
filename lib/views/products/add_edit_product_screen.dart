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
  final _uomController = TextEditingController();
  final _expController = TextEditingController();
  final _warehouseController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _uomController.text = widget.product!.uom;
      _expController.text = widget.product!.exp;
      _warehouseController.text = widget.product!.warehouse;
      _locationController.text = widget.product!.location;
      _priceController.text = widget.product!.unitPrice.toString();
      _imageUrlController.text = widget.product!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uomController.dispose();
    _expController.dispose();
    _warehouseController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        description: widget.product?.description ?? '',
        quantity: widget.product?.quantity ?? 0,
        uom: _uomController.text,
        warehouse: _warehouseController.text,
        location: _locationController.text,
        exp: _expController.text,
        imageUrl: _imageUrlController.text,
        unitPrice: int.tryParse(_priceController.text) ?? 0,
      );

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
                controller: _uomController,
                decoration: const InputDecoration(labelText: 'Unit (UOM)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter unit' : null,
              ),
              TextFormField(
                controller: _expController,
                decoration: const InputDecoration(labelText: 'Expiry (exp)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter expiry' : null,
              ),
              TextFormField(
                controller: _warehouseController,
                decoration: const InputDecoration(labelText: 'Warehouse'),
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Unit Price'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
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
