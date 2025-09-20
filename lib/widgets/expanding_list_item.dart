import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpandingListItem extends StatefulWidget {
  final String name;
  final String sku;
  final int quantity;
  final String uom;
  final String wh;
  final String location;
  final String exp;
  final String? imageUrl;
  final int? unitPrice;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRefresh; 

  const ExpandingListItem({
    Key? key,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.uom,
    required this.wh,
    required this.location,
    required this.exp,
    this.imageUrl,
    this.unitPrice,
    this.onEdit,
    this.onDelete,
    this.onRefresh,
  }) : super(key: key);

  @override
  ExpandingListItemState createState() => ExpandingListItemState();
}

class ExpandingListItemState extends State<ExpandingListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;

  final String baseUrl = "http://10.0.2.2:5000/api/transactions"; 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void expand() {
    if (!_isExpanded) _toggleExpand();
  }

  void collapse() {
    if (_isExpanded) _toggleExpand();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<String?> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  

  Future<void> _handleTransaction(String type, int qty, [String note = ""]) async {
  try {
    final uri = Uri.parse("$baseUrl/addTransaction");
    final token = await _getIdToken();
    final body = {
      "sku": widget.sku,
      "wh": widget.wh,
      "qty": qty,
      "type": type,
      "by": "admin", 
      "note": note
    };

    final resp = await http.post(uri,
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token",},
        body: json.encode(body));

    if (resp.statusCode == 201) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Thành công!"),
        backgroundColor: Colors.green,
      ));
      widget.onRefresh?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Lỗi: ${resp.body}"),
        backgroundColor: Colors.red,
      ));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Lỗi kết nối: $e"),
      backgroundColor: Colors.red,
    ));
  }
}


void _showExportDialog() {
  final qtyCtrl = TextEditingController(text: "1");
  final noteCtrl = TextEditingController();
  

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Xác nhận xuất kho"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: "Số lượng cần xuất"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: "Ghi chú (tùy chọn)"),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy")),
        ElevatedButton(
          onPressed: () {
            final qty = int.tryParse(qtyCtrl.text) ?? 0;
            final note = noteCtrl.text.trim();
            if (qty > 0) {
              _handleTransaction("outbound", qty, note);
            }
          },
          child: const Text("Xác nhận"),
        )
      ],
    ),
  );
}

void _showImportDialog() {
  final qtyCtrl = TextEditingController(text: "1");
  final noteCtrl = TextEditingController();
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Xác nhận nhập kho"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: "Số lượng cần nhập"),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: "Ghi chú (tùy chọn)"),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy")),
        ElevatedButton(
          onPressed: () {
            final qty = int.tryParse(qtyCtrl.text) ?? 0;
            final note = noteCtrl.text.trim();
            if (qty > 0) {
              _handleTransaction("inbound", qty, note);
            }
          },
          child: const Text("Xác nhận"),
        )
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          _buildExpandableContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpand,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.image_not_supported, color: Colors.grey),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("SKU: ${widget.sku}",
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent() {
    final formatter = NumberFormat("#,###", "vi_VN");
        return SizeTransition(
          sizeFactor: _heightFactor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                const Divider(),
                _buildDetailRow("Số lượng:", "${widget.quantity} ${widget.uom}"),
                _buildDetailRow("Kho:", widget.wh),
                _buildDetailRow("Vị trí:", widget.location),
                _buildDetailRow("Hạn sử dụng:", widget.exp),
                if (widget.unitPrice != null)
                  _buildDetailRow(
                    "Đơn giá:",
                    "${formatter.format(widget.unitPrice)} VNĐ"
  ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(onPressed: _showExportDialog, child: const Text("Xuất")),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _showImportDialog, child: const Text("Nhập")),
                    const Spacer(),
                    if (widget.onEdit != null)
                      IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blueAccent),
                          onPressed: widget.onEdit),
                    if (widget.onDelete != null)
                      IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: widget.onDelete),
                  ],
                )
              ],
            ),
          ),
        );
      }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Flexible(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }
}
