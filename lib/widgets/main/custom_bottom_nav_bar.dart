import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng BottomNavigationBar tiêu chuẩn để có góc vuông
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      // Các thuộc tính để đảm bảo giao diện đẹp và hoạt động đúng
      type: BottomNavigationBarType.fixed, // Luôn hiển thị label
      backgroundColor: Colors.white,
      selectedItemColor: Theme.of(context).primaryColor, // Màu cho mục đang chọn
      unselectedItemColor: Colors.grey, // Màu cho các mục khác
      elevation: 8.0, // Thêm đổ bóng cho thanh điều hướng
    );
  }
}