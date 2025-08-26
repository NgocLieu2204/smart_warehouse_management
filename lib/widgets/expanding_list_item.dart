import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandingListItem extends StatefulWidget {
  final String name;
  final String sku;
  final int quantity;
  final String uom;       // 🔥 thêm uom
  final String wh;        // 🔥 tên kho
  final String location;  // 🔥 vị trí chi tiết
  final String exp;
  final String? imageUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpandingListItem({
    Key? key,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.uom,       // required
    required this.wh,        // required
    required this.location,  // required
    required this.exp,
    this.imageUrl,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  ExpandingListItemState createState() => ExpandingListItemState();
}

class ExpandingListItemState extends State<ExpandingListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  bool _isExpanded = false;

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
                  Text(
                    widget.name,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "SKU: ${widget.sku}",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.grey[600]),
                  ),
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
    return SizeTransition(
      sizeFactor: _heightFactor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            const Divider(),
            _buildDetailRow("Số lượng:", "${widget.quantity} ${widget.uom}"), // 🔥 qty + uom
            _buildDetailRow("Kho:", widget.wh),          // 🔥 kho tổng
            _buildDetailRow("Vị trí:", widget.location), // 🔥 vị trí chi tiết
            _buildDetailRow("Hạn sử dụng:", widget.exp),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // TODO: logic Xuất
                  },
                  child: const Text('Xuất'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    // TODO: logic Nhập
                  },
                  child: const Text('Nhập'),
                ),
                const Spacer(),
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: widget.onEdit,
                    tooltip: 'Chỉnh sửa',
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: widget.onDelete,
                    tooltip: 'Xóa',
                  ),
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
