// lib/views/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/flip_item_card.dart';
import '../../widgets/qr_scanner_dialog.dart';


class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  void _showQRScannerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const QrScannerDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = NumberFormat("#,###", "en_US");

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFFF), Color(0xFF32CD32)],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Smart Warehouse',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person),
            label: const Text('User'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF121212), const Color(0xFF0A2342)]
                    : [
                        const Color(0xFF00BFFF).withOpacity(0.15),
                        const Color(0xFF32CD32).withOpacity(0.15)
                      ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bảng điều khiển',
                            style: GoogleFonts.poppins(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Dữ liệu cập nhật giả lập mỗi 3 giây',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showQRScannerDialog(context),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: MetricCard(
                        title: 'Tồn kho',
                        value: formatter.format(12450),
                        change: '+2.1% hôm nay',
                        isLive: true,
                        liveColor: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: MetricCard(
                        title: 'Cảnh báo',
                        value: '3',
                        change: 'Ưu tiên cao',
                        isLive: false,
                        gradient: LinearGradient(
                          colors: [Color(0xFF8A2BE2), Color(0xFFFF69B4)],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ChartCard(),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                FlipItemCard(
                  title: 'Pallet A12',
                  sku: 'SW-1029',
                  quantity: 320,
                  details: [
                    'Vị trí: Kệ B - Tầng 2',
                    'HSD: 12/2025',
                    'Trạng thái: Tốt',
                  ],
                  isExport: true,
                ),
                SizedBox(height: 16),
                FlipItemCard(
                  title: 'Crate Z55',
                  sku: 'SW-5540',
                  quantity: 58,
                  details: [
                    'Vị trí: Kệ D - Tầng 1',
                    'HSD: 05/2026',
                    'Trạng thái: Cần kiểm tra',
                  ],
                  isExport: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}