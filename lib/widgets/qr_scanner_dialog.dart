// lib/widgets/qr_scanner_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({Key? key}) : super(key: key);

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  String? _scanResult;
  bool _isScanning = true;
  late MobileScannerController _cameraController;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _scanResult = code;
          _isScanning = false;
        });
        _cameraController.stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Quét mã sản phẩm',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 350,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: _cameraController,
                  onDetect: _onDetect,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_scanResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Chip(
                  backgroundColor: Colors.green.shade100,
                  label: Text('Kết quả: $_scanResult',
                      style: TextStyle(color: Colors.green.shade900)),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  'Đưa mã QR/barcode vào vùng quét',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Đóng'),
          onPressed: () {
            Navigator.of(context).pop(_scanResult);
          },
        ),
        if (!_isScanning && _scanResult != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(_scanResult);
            },
            child: const Text('Xác nhận'),
          ),
      ],
    );
  }
}
