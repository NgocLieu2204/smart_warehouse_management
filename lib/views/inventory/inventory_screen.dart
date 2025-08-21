import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../widgets//expanding_list_item.dart';

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

  @override
  void initState() {
    super.initState();
    fetchInventoryData();
  }

  Future<void> fetchInventoryData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/inventory/getInventory'), // Android Emulator
      );

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Lỗi: $_error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hàng tồn kho',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _expandAll, icon: const Icon(Icons.unfold_more)),
          IconButton(onPressed: _collapseAll, icon: const Icon(Icons.unfold_less)),
          const SizedBox(width: 8)
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
            status: item['status'] ?? 'Còn hàng',
          );
        },
      ),
    );
  }
}
