import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

import '../../widgets/metric_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/flip_item_card.dart';
import '../../widgets/qr_scanner_dialog.dart';
import '../inventory/low_stock_screen.dart'; // Import màn hình mới

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

// Thêm "with WidgetsBindingObserver" để lắng nghe các thay đổi vòng đời của ứng dụng
class _DashboardViewState extends State<DashboardView> with WidgetsBindingObserver {
  // --- Các biến trạng thái ---
  List<dynamic> _inventoryList = [];
  List<dynamic> _lowStockProducts = [];
  int _totalQuantity = 0;
  bool _loading = true;
  String? _error;
  bool _isAlertShown = false; // Đảm bảo dialog chỉ hiện 1 lần mỗi khi tải lại
  Timer? _refreshTimer;

  final String baseUrl = "http://10.0.2.2:5000/api/inventory";

  @override
  void initState() {
    super.initState();
    // Thêm observer để lắng nghe sự kiện quay lại màn hình
    WidgetsBinding.instance.addObserver(this);

    // Tải dữ liệu lần đầu
    fetchInventoryData();

    // Thiết lập tự động làm mới dữ liệu mỗi 3 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        // Không hiện loading khi tự động làm mới
        fetchInventoryData(showAlert: false);
      }
    });
  }

  @override
  void dispose() {
    // Hủy timer và observer khi widget bị xóa
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Phương thức này được gọi khi trạng thái vòng đời của ứng dụng thay đổi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Nếu ứng dụng được "resumed" (người dùng quay lại), tải lại dữ liệu
    if (state == AppLifecycleState.resumed) {
      fetchInventoryData(showAlert: false);
    }
  }

  // --- Hàm tải và xử lý dữ liệu ---
  Future<void> fetchInventoryData({bool showAlert = true}) async {
    if (!mounted) return;

    // Chỉ hiển thị loading indicator trong lần tải đầu tiên
    if (showAlert && _inventoryList.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // Thêm một tham số timestamp để ngăn server trả về dữ liệu cache cũ
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(Uri.parse('$baseUrl/getInventory?t=$timestamp'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> fetchedList = data is List ? data : [];

        int totalQty = 0;
        List<dynamic> lowStock = [];
        for (var item in fetchedList) {
          final qty = item['qty'] ?? 0;
          totalQty += qty is int ? qty : (qty as num).toInt();
          if ((qty is int ? qty : (qty as num).toInt()) > 0 && (qty is int ? qty : (qty as num).toInt()) < 10) {
            lowStock.add(item);
          }
        }
        
        // Chỉ cập nhật UI nếu dữ liệu thực sự thay đổi để tránh build lại không cần thiết
        if (_inventoryList.toString() != fetchedList.toString()) {
           setState(() {
            _inventoryList = fetchedList;
            _totalQuantity = totalQty;
            _lowStockProducts = lowStock;
           });
        }

        if (showAlert && !_isAlertShown && _lowStockProducts.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLowStockAlertDialog();
             if (mounted) {
              setState(() {
                _isAlertShown = true;
              });
            }
          });
        }
      } else {
         if (mounted) {
          setState(() {
            _error = 'Lỗi tải dữ liệu. Mã lỗi: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Không thể kết nối đến máy chủ: ${e.toString()}";
      });
    } finally {
      if (mounted && _loading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // --- Các phương thức UI ---
  void _showLowStockAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 5),
              Text(
                'Cảnh báo tồn kho',
                style: TextStyle(fontSize: 20), 
              ),
            ],
           ),
          content: SingleChildScrollView(
            child: ListBody(
              children: _lowStockProducts.map((product) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Sản phẩm "${product['name']}" chỉ còn ${product['qty']} EA.',
                  ),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Xem chi tiết'),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToLowStockScreen();
              },
            ),
            TextButton(
              child: const Text('Đã hiểu'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToLowStockScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LowStockScreen(lowStockProducts: _lowStockProducts),
      ),
    ).then((_) {
      // Tải lại dữ liệu khi quay lại từ màn hình chi tiết
      fetchInventoryData();
    });
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
      body: _loading && _inventoryList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ))
              : RefreshIndicator(
                  onRefresh: () {
                    _isAlertShown = false; // Cho phép hiển thị lại cảnh báo khi làm mới thủ công
                    return fetchInventoryData(showAlert: true);
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(0),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF121212),
                                    const Color(0xFF0A2342)
                                  ]
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
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dữ liệu được làm mới mỗi 3 giây',
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
                                  child: MetricCard(
                                    title: 'Tồn kho',
                                    value: formatter.format(_totalQuantity),
                                    change: '+2.1% hôm nay', // Dữ liệu giả
                                    isLive: true,
                                    liveColor: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _navigateToLowStockScreen,
                                    child: MetricCard(
                                      title: 'Cảnh báo',
                                      value:
                                          _lowStockProducts.length.toString(),
                                      change: _lowStockProducts.isNotEmpty
                                          ? 'Sản phẩm dưới 10 EA'
                                          : 'Ổn định',
                                      isLive: false,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF8A2BE2),
                                          Color(0xFFFF69B4)
                                        ],
                                      ),
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
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children:
                              List.generate(_inventoryList.take(2).length, (index) {
                            final item = _inventoryList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: FlipItemCard(
                                title: item['name'] ?? 'Không có tên',
                                sku: item['sku'] ?? 'N/A',
                                quantity: item['qty'] ?? 0,
                                imageUrl: item['imageUrl'],
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
                ),
    );
  }
}