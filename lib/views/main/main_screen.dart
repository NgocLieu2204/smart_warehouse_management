import 'package:flutter/material.dart';
import '../../widgets/main/custom_bottom_nav_bar.dart';
import '../dashboard/dashboard_screen.dart';
import '../inventory/inventory_screen.dart';
import '../tasks/tasks_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/floating_chatbox.dart'; // Import widget chatbox

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _isChatboxLoading = ValueNotifier<bool>(false);

  // Danh sách các màn hình
  static final List<Widget> _widgetOptions = <Widget>[
    DashboardView(),
    InventoryView(),
    TasksView(),
    SettingsView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  

  @override
  void dispose() {
    _isChatboxLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          // Bỏ 'extendBody' để nội dung không bị thanh điều hướng che
          body: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
         
          // Bỏ 'floatingActionButtonLocation' để nút tự động về góc phải dưới
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),
        // Nút chatbox vẫn giữ nguyên
        FloatingChatbox(isLoading: _isChatboxLoading),
      ],
    );
  }
}