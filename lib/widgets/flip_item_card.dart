// lib/widgets/dashboard/flip_item_card.dart

import 'dart:math';
import 'package:flutter/material.dart';

class FlipItemCard extends StatefulWidget {
  final String title;
  final String sku;
  final int quantity;
  final List<String> details;
  final bool isExport;
  final String? imageUrl;

  const FlipItemCard({
    Key? key,
    required this.title,
    required this.sku,
    required this.quantity,
    required this.details,
    required this.isExport,
    this.imageUrl,
  }) : super(key: key);

  @override
  _FlipItemCardState createState() => _FlipItemCardState();
}

class _FlipItemCardState extends State<FlipItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  void _toggleCard() {
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    _isFlipped = !_isFlipped;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: _animation.value <= 0.5
              ? _buildCardSide(isFront: true)
              : Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _buildCardSide(isFront: false),
                ),
        );
      },
    );
  }

  Widget _buildCardSide({required bool isFront}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isFront
        ? Theme.of(context).cardTheme.color
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF9FAFB));

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: isFront ? _buildFront() : _buildBack(),
        ),
      ),
    );
  }

  List<Widget> _buildFront() {
    // START: Image Widget Logic
    Widget imageWidget;
    if (widget.imageUrl != null && widget.imageUrl!.trim().isNotEmpty) {
      imageWidget = Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          // **** THAY ĐỔI Ở ĐÂY: Chuyển màu nền thành trắng ****
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.network(
            widget.imageUrl!,
            height: 120,
            width: double.infinity,
            fit: BoxFit.contain, // Giữ nguyên để thấy toàn bộ ảnh
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else {
      imageWidget = Container(
        height: 120,
        decoration: BoxDecoration(
          // **** THAY ĐỔI Ở ĐÂY: Chuyển màu nền thành trắng ****
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Thêm một đường viền nhẹ để khung không "biến mất" hoàn toàn
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 40),
        ),
      );
    }
    // END: Image Widget Logic

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(widget.title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 30,
            child: OutlinedButton(onPressed: _toggleCard, child: const Text('Xem')),
          ),
        ],
      ),
      const SizedBox(height: 12),
      imageWidget,
      const SizedBox(height: 8),
      Text('SKU: ${widget.sku} • SL: ${widget.quantity}',
          style: TextStyle(color: Colors.grey.shade500)),
    ];
  }

  List<Widget> _buildBack() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Chi tiết',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(
            height: 30,
            child: ElevatedButton(
              onPressed: _toggleCard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Đóng'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ...widget.details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('• $detail'),
          )),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {},
          child: Text(widget.isExport ? 'Tạo lệnh xuất' : 'Tạo lệnh nhập'),
        ),
      ),
    ];
  }
}