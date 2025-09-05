import 'package:flutter/material.dart';
import '../main/main_screen.dart'; // Thay 'your_app_name' bằng tên ứng dụng của bạn

class LowStockScreen extends StatelessWidget {
  final List<dynamic> lowStockProducts;

  const LowStockScreen({Key? key, required this.lowStockProducts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sản phẩm sắp hết hàng (${lowStockProducts.length})'),
        backgroundColor: Colors.orange,
      ),
      body: lowStockProducts.isEmpty
          ? const Center(
              child: Text(
                'Không có sản phẩm nào cần cảnh báo.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: lowStockProducts.length,
              itemBuilder: (context, index) {
                final product = lowStockProducts[index];
                final imageUrl = product['imageUrl'] as String?;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 15),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                          ? NetworkImage(imageUrl)
                          : null,
                      child: (imageUrl == null || imageUrl.isEmpty)
                          ? const Icon(Icons.inventory_2_outlined,
                              color: Colors.orange)
                          : null,
                    ),
                    title: Text(
                      product['name'] ?? 'Không có tên',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                        'SKU: ${product['sku'] ?? 'N/A'} - Vị trí: ${product['location'] ?? 'N/A'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Còn: ${product['qty'] ?? 0} EA',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                          onPressed: () {
                            // Xóa tất cả màn hình cũ và mở MainScreen ở tab Inventory (index = 1)
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(initialIndex: 1),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}