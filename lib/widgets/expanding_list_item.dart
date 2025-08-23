import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpandingListItem extends StatefulWidget {
  final String name;
  final String sku;
  final int quantity;
  final String location;
  final String status;
  final String? imageUrl;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpandingListItem({
    Key? key,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.location,
    required this.status,
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
    if (!_isExpanded) {
      _toggleExpand();
    }
  }

  void collapse() {
    if (_isExpanded) {
      _toggleExpand();
    }
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
            // Widget hiển thị hình ảnh
            if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  widget.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
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
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
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

  // **** PHẦN NỘI DUNG MỞ RỘNG ĐÃ ĐƯỢC KHÔI PHỤC LẠI ĐẦY ĐỦ ****
  Widget _buildExpandableContent() {
    return SizeTransition(
      sizeFactor: _heightFactor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            const Divider(),
            _buildDetailRow("Số lượng:", "${widget.quantity}"),
            _buildDetailRow("Vị trí:", widget.location),
            _buildDetailRow("Trạng thái:", widget.status),
            const SizedBox(height: 12),
            // ** CÁC NÚT NHẬP/XUẤT ĐÃ ĐƯỢC THÊM LẠI VÀO ĐÂY **
            Row(
              children: [
                ElevatedButton(onPressed: () {
                  // TODO: Thêm logic xử lý cho nút Xuất
                }, child: const Text('Xuất')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () {
                  // TODO: Thêm logic xử lý cho nút Nhập
                }, child: const Text('Nhập')),
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
          Text(value, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }
}