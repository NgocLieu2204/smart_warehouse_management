// lib/widgets/dashboard/flip_item_card.dart

import 'dart:math';
import 'package:flutter/material.dart';

class FlipItemCard extends StatefulWidget {
  final String title;
  final String sku;
  final int quantity;
  final List<String> details;
  final bool isExport;

  const FlipItemCard({
    Key? key,
    required this.title,
    required this.sku,
    required this.quantity,
    required this.details,
    required this.isExport,
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
      Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('Ảnh hàng (lazy)', style: TextStyle(color: Colors.grey)),
        ),
      ),
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