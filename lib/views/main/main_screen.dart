import 'package:flutter/material.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/inventory/inventory_screen.dart';
import '../../views/tasks/tasks_screen.dart';
import '../../views/settings/settings_screen.dart';
import '../../widgets/floating_chatbox.dart';
import '../../widgets/main/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  final ValueNotifier<bool> _isChatboxLoading = ValueNotifier<bool>(false);

  // Danh sách các màn hình
  // Lưu ý: Tên class đã được sửa lại cho đúng (DashboardScreen thay vì DashboardView)
  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardView(),
    const InventoryView(),
    const TasksView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

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
          body: IndexedStack(
            index: _selectedIndex,
            children: _widgetOptions,
          ),
          bottomNavigationBar: CustomBottomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),
        // Nút chatbox
        FloatingChatbox(isLoading: _isChatboxLoading),
      ],
    );
  }
}