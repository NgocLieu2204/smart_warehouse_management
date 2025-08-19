// lib/views/inventory/inventory_screen.dart (ĐÃ SỬA LỖI ĐƯỜNG DẪN IMPORT)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/expanding_list_item.dart';
class InventoryView extends StatefulWidget {
  const InventoryView({Key? key}) : super(key: key);

  @override
  _InventoryViewState createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final List<GlobalKey<ExpandingListItemState>> _keys = [
    GlobalKey<ExpandingListItemState>(),
    GlobalKey<ExpandingListItemState>(),
    GlobalKey<ExpandingListItemState>()
  ];

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Hàng tồn kho',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: _expandAll, icon: const Icon(Icons.unfold_more)),
          IconButton(
              onPressed: _collapseAll, icon: const Icon(Icons.unfold_less)),
          const SizedBox(
            width: 8,
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ExpandingListItem(
            key: _keys[0],
            name: 'Thùng C10',
            sku: 'SW-7710',
            quantity: 120,
            location: 'A-1-2',
            status: 'Ổn định',
          ),
          const SizedBox(height: 12),
          ExpandingListItem(
            key: _keys[1],
            name: 'Pallet D04',
            sku: 'SW-2210',
            quantity: 65,
            location: 'B-2-3',
            status: 'Cần kiểm tra',
          ),
          const SizedBox(height: 12),
          ExpandingListItem(
            key: _keys[2],
            name: 'Roll E99',
            sku: 'SW-8899',
            quantity: 12,
            location: 'C-5-1',
            status: 'Hàng dễ vỡ',
          ),
        ],
      ),
    );
  }
}