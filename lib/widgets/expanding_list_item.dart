// lib/widgets/inventory/expanding_list_item.dart

import 'package:flutter/material.dart';

class ExpandingListItem extends StatefulWidget {
  final String name;
  final String sku;
  final int quantity;
  final String location;
  final String status;

  const ExpandingListItem({
    Key? key,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.location,
    required this.status,
  }) : super(key: key);

  @override
  ExpandingListItemState createState() => ExpandingListItemState();
}

class ExpandingListItemState extends State<ExpandingListItem> {
  bool _isExpanded = false;

  void expand() => setState(() => _isExpanded = true);
  void collapse() => setState(() => _isExpanded = false);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('SKU: ${widget.sku}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${widget.quantity} cái',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.location,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              height: _isExpanded ? null : 0,
              padding: _isExpanded
                  ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
                  : EdgeInsets.zero,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text('Trạng thái: ${widget.status}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(onPressed: () {}, child: const Text('Xuất')),
                      const SizedBox(width: 8),
                      OutlinedButton(onPressed: () {}, child: const Text('Nhập')),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}