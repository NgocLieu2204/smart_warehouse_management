// lib/views/main/main_screen.dart (ĐÃ CẬP NHẬT)

import 'package:flutter/material.dart';
// Sửa đường dẫn import cho đúng với cấu trúc dự án của bạn
import '../../widgets/main/custom_bottom_nav_bar.dart'; 
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../orders/orders_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardView(),
    const InventoryView(),
    const OrdersView(),
    const SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Thuộc tính này cho phép body hiển thị phía sau thanh điều hướng
      extendBody: true, 
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mở form nhập hàng mới (Demo).')),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: const Icon(Icons.add, color: Colors.black),
        elevation: 4.0,
      ),
      // Đặt vị trí FAB ở trung tâm và "dock" vào thanh điều hướng
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked, 
      // Sử dụng widget thanh điều hướng mới
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}