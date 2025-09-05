import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../widgets/expanding_list_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Hàm lấy token Firebase hiện tại
  Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  Future<void> fetchInventoryData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('$baseUrl/getInventory'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _inventoryList = data;
          _keys = List.generate(
              _inventoryList.length, (_) => GlobalKey<ExpandingListItemState>());
        });
      } else {
        setState(() {
          _error =
              'Failed to load inventory data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error connecting to server: ${e.toString()}";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showInventoryDialog({Map<String, dynamic>? item}) async {
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final skuCtrl = TextEditingController(text: item?['sku'] ?? '');
    final qtyCtrl = TextEditingController(text: '${item?['qty'] ?? ''}');
    final uomCtrl = TextEditingController(text: item?['uom'] ?? '');
    final whCtrl = TextEditingController(text: item?['wh'] ?? '');
    final locCtrl = TextEditingController(text: item?['location'] ?? '');
    final expCtrl = TextEditingController(text: item?['exp'] ?? '');
    final imageUrlCtrl =
        TextEditingController(text: item?['imageUrl'] ?? '');

    final isUpdate = item != null;
    final token = await getIdToken();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isUpdate ? "Cập nhật sản phẩm" : "Thêm sản phẩm mới"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Tên sản phẩm")),
              TextField(
                  controller: skuCtrl,
                  decoration: const InputDecoration(labelText: "SKU")),
              TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: "Số lượng"),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: uomCtrl,
                  decoration: const InputDecoration(labelText: "Đơn vị (uom)")),
              TextField(
                  controller: whCtrl,
                  decoration: const InputDecoration(labelText: "Kho")),
              TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: "Vị trí chi tiết")),
              TextField(
                  controller: expCtrl,
                  decoration: const InputDecoration(labelText: "Ngày sản xuất")),
              TextField(
                  controller: imageUrlCtrl,
                  decoration: const InputDecoration(labelText: "URL Hình ảnh")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            child: Text(isUpdate ? "Cập nhật" : "Thêm"),
            onPressed: () async {
              final body = {
                "name": nameCtrl.text,
                "sku": skuCtrl.text,
                "qty": int.tryParse(qtyCtrl.text) ?? 0,
                "uom": uomCtrl.text,
                "wh": whCtrl.text,
                "location": locCtrl.text,
                "exp": expCtrl.text,
                "imageUrl": imageUrlCtrl.text,
              };

              final uri = isUpdate
                  ? Uri.parse('$baseUrl/updateInventory/${item!['sku']}')
                  : Uri.parse('$baseUrl/createInventory');

              final resp = isUpdate
                  ? await http.put(uri,
                      headers: {"Content-Type": "application/json", "Authorization": "Bearer $token", },
                      body: json.encode(body))
                  : await http.post(uri,
                      headers: {"Content-Type": "application/json","Authorization": "Bearer $token", },
                      body: json.encode(body));

              if (mounted) {
                if (resp.statusCode == 200 || resp.statusCode == 201) {
                  Navigator.pop(context);
                  fetchInventoryData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Lỗi: ${resp.body}'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
          )
        ],
      ),
    );
  }
  Future<void> _deleteItem(String sku) async {
      final token = await getIdToken();
      final resp = await http.delete(
        Uri.parse('$baseUrl/deleteInventory/$sku'),
        headers: {"Authorization": "Bearer $token"}, 
      );
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
    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("Lỗi: $_error", textAlign: TextAlign.center),
      ));
    } else if (_inventoryList.isEmpty) {
      body = const Center(child: Text("Không có sản phẩm nào trong kho."));
    } else {
      body = RefreshIndicator(
        onRefresh: fetchInventoryData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _inventoryList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = _inventoryList[index];
            return ExpandingListItem(
              key: _keys[index],
              name: item['name'] ?? 'Không có tên',
              sku: item['sku'] ?? 'N/A',
              quantity: item['qty'] ?? 0,
              uom: item['uom'] ?? "EA",   
              wh: item['wh'] ?? 'N/A',    
              location: item['location'] ?? 'N/A',
              exp: item['exp'] ?? "N/A",  
              imageUrl: item['imageUrl'],
              onEdit: () => _showInventoryDialog(item: item),
              onDelete: () => _deleteItem(item['sku']),
              onRefresh: fetchInventoryData, //callback để refresh list
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Hàng tồn kho",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
              onPressed: _expandAll,
              icon: const Icon(Icons.unfold_more),
              tooltip: 'Mở rộng tất cả'),
          IconButton(
              onPressed: _collapseAll,
              icon: const Icon(Icons.unfold_less),
              tooltip: 'Thu gọn tất cả'),
          IconButton(
              onPressed: () => _showInventoryDialog(),
              icon: const Icon(Icons.add),
              tooltip: 'Thêm sản phẩm'),
        ],
      ),
      body: body,
    );
  }
}
