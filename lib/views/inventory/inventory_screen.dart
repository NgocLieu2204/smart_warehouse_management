import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../widgets/expanding_list_item.dart';

class InventoryView extends StatefulWidget {
  const InventoryView({Key? key}) : super(key: key);

  @override
  _InventoryViewState createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  List<dynamic> _inventoryList = [];
  List<GlobalKey<ExpandingListItemState>> _keys = [];
  bool _loading = true;
  String? _error;

  final String baseUrl = "http://10.0.2.2:5000/api/inventory";

  @override
  void initState() {
    super.initState();
    fetchInventoryData();
  }

  Future<void> fetchInventoryData() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getInventory'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _inventoryList = data;
          _keys = List.generate(
              _inventoryList.length, (_) => GlobalKey<ExpandingListItemState>());
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load inventory data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showInventoryDialog({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final skuCtrl = TextEditingController(text: item?['sku'] ?? '');
    final qtyCtrl = TextEditingController(text: '${item?['qty'] ?? ''}');
    final whCtrl = TextEditingController(text: item?['wh'] ?? '');
    final isUpdate = item != null;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isUpdate ? "Cập nhật" : "Thêm mới"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Tên")),
            TextField(controller: skuCtrl, decoration: const InputDecoration(labelText: "SKU")),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: "Số lượng"), keyboardType: TextInputType.number),
            TextField(controller: whCtrl, decoration: const InputDecoration(labelText: "Vị trí")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            child: Text(isUpdate ? "Cập nhật" : "Thêm"),
            onPressed: () async {
              final body = {
                "name": nameCtrl.text,
                "sku": skuCtrl.text,
                "qty": int.tryParse(qtyCtrl.text) ?? 0,
                "wh": whCtrl.text,
              };

              final uri = isUpdate
                  ? Uri.parse('$baseUrl/updateInventory/${item!['sku']}')
                  : Uri.parse('$baseUrl/createInventory');

              final resp = isUpdate
                  ? await http.put(uri, headers: {"Content-Type": "application/json"}, body: json.encode(body))
                  : await http.post(uri, headers: {"Content-Type": "application/json"}, body: json.encode(body));

              if (resp.statusCode == 200 || resp.statusCode == 201) {
                Navigator.pop(context);
                fetchInventoryData();
              }
            },
          )
        ],
      ),
    );
  }

  Future<void> _deleteItem(String sku) async {
    final resp = await http.delete(Uri.parse('$baseUrl/deleteInventory/$sku'));
    if (resp.statusCode == 200) {
      fetchInventoryData();
    }
  }

  void _expandAll() {
    for (var key in _keys) {
      key.currentState?.expand();
    }
  }

  void _collapseAll() {
    for (var key in _keys) {
      key.currentState?.collapse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(body: Center(child: Text("Lỗi: $_error")));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Hàng tồn kho",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _expandAll, icon: const Icon(Icons.unfold_more)),
          IconButton(onPressed: _collapseAll, icon: const Icon(Icons.unfold_less)),
          IconButton(onPressed: () => _showInventoryDialog(), icon: const Icon(Icons.add)),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _inventoryList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _inventoryList[index];
          return ExpandingListItem(
            key: _keys[index],
            name: item['name'],
            sku: item['sku'],
            quantity: item['qty'],
            location: item['wh'],
            status: item['status'] ?? "Còn hàng",
            onEdit: () => _showInventoryDialog(item: item),
            onDelete: () => _deleteItem(item['sku']),
          );
        },
      ),
    );
  }
}
