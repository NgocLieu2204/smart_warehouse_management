import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import 'package:smart_warehouse_manager/views/products/product_list_screen.dart';
import 'package:smart_warehouse_manager/views/inventory/stock_transaction_screen.dart';
import 'package:smart_warehouse_manager/views/inventory/history_screen.dart';
import 'package:smart_warehouse_manager/views/reports/report_screen.dart';
import '../auth/login_screen.dart';

// Nội dung tab Dashboard tách riêng ra
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Sản phẩm',
                  value: '1,250', // TODO: Lấy dữ liệu thật
                  icon: Icons.inventory_2,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Sắp hết hàng',
                  value: '15', // TODO: Lấy dữ liệu thật
                  icon: Icons.warning_amber,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Chức năng',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildFeatureCard(
                context,
                title: 'Quản lý sản phẩm',
                icon: Icons.list_alt,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const ProductListScreen()));
                },
              ),
              _buildFeatureCard(
                context,
                title: 'Nhập / Xuất kho',
                icon: Icons.sync_alt,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const StockTransactionScreen()));
                },
              ),
              _buildFeatureCard(
                context,
                title: 'Lịch sử giao dịch',
                icon: Icons.history,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()));
                },
              ),
              _buildFeatureCard(
                context,
                title: 'Báo cáo & Thống kê',
                icon: Icons.bar_chart,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const ReportScreen()));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // số tab
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Smart Warehouse Manager'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              ),
          ],
        ),
        body: const TabBarView(
          children: [
            DashboardContent(),
            ProductListScreen(),
            StockTransactionScreen(),
            HistoryScreen(),
          ],
        ),
        bottomNavigationBar: const Material(
          color: Colors.white,
          child: TabBar(
            tabs: [
              Tab(text: 'Dashboard', icon: Icon(Icons.dashboard)),
              Tab(text: 'Products', icon: Icon(Icons.list_alt)),
              Tab(text: 'Stock', icon: Icon(Icons.sync_alt)),
              Tab(text: 'History', icon: Icon(Icons.history)),
            ],
            indicatorColor: Colors.white,
          ),
        ),
      ),
    );
  }
}