import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../widgets/metric_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/flip_item_card.dart';
import '../../widgets/qr_scanner_dialog.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<dynamic> _inventoryList = [];
  bool _loading = true;
  String? _error;

  final String baseUrl = "http://10.0.2.2:5000/api/inventory";

  @override
  void initState() {
    super.initState();
    fetchInventoryData();
  }

  Future<void> fetchInventoryData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(Uri.parse('$baseUrl/getInventory'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _inventoryList = data;
        });
      } else {
        setState(() {
          _error =
              'Failed to load inventory data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error connecting to server: ${e.toString()}";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  Future<int> fetchLowQuantityCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getLowQuanlityItems'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data; 
      } else {
        throw Exception(
            'Failed to load low quantity items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: ${e.toString()}');
    }
  }

  Future<int> fetchTotalQuantity() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/getAllQuantityInventory'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['totalQuantity'] ?? 0;
      } else {
        throw Exception(
            'Failed to load total quantity. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: ${e.toString()}');
    }
  }
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
            label: const Text('Admin'),
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
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Dữ liệu cập nhật giả lập mỗi 3 giây',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showQRScannerDialog(context),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text(
                        'Scan me',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                        minimumSize: const Size(30, 30),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<int>(
                        future: fetchTotalQuantity(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return MetricCard(
                              title: 'Tồn kho',
                              value: 'Lỗi',
                              change: snapshot.error.toString(),
                              isLive: false,
                              liveColor: Colors.red,
                            );
                          } else {
                            final total = snapshot.data ?? 0;
                            return MetricCard(
                              title: 'Tồn kho',
                              value: formatter.format(total),
                              change: '+2.1% hôm nay',
                              isLive: true,
                              liveColor: Theme.of(context).primaryColor,
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: FutureBuilder<int>(
                        future: fetchLowQuantityCount(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return MetricCard(
                              title: 'Cảnh báo',
                              value: 'Lỗi',
                              change: snapshot.error.toString(),
                              isLive: false,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8A2BE2), Color(0xFFFF69B4)],
                              ),
                            );
                          } else {
                            final lowStock = snapshot.data ?? 0;
                            return 
                            
                            MetricCard(
                              title: 'Cảnh báo',
                              value: lowStock.toString(),
                              change: lowStock > 0 ? 'Sản phẩm dưới 10 EA' : 'Ổn định',
                              isLive: false,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8A2BE2), Color(0xFFFF69B4)],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const ChartCard(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : Column(
                        children:
                            List.generate(_inventoryList.take(2).length, (index) {
                          final item = _inventoryList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom:16.0),
                            child: FlipItemCard(
                              title: item['name'] ?? 'Không có tên',
                              sku: item['sku'] ?? 'N/A',
                              quantity: item['qty'] ?? 0,
                              imageUrl: item['imageUrl'], // <-- THÊM DÒNG NÀY
                              details: [
                                'Vị trí: ${item['location'] ?? 'N/A'}',
                                'HSD: ${item['exp'] ?? 'N/A'}',
                                'Trạng thái: Tốt',
                              ],
                              isExport: index.isEven,
                            ),
                          );
                        }),
                      ),
          ),
        ],
      ),
    );
  }
}