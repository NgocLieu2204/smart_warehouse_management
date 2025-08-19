// lib/widgets/qr_scanner_dialog.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QrScannerDialog extends StatefulWidget {
  const QrScannerDialog({Key? key}) : super(key: key);

  @override
  _QrScannerDialogState createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  bool _isScanning = false;
  String? _scanResult;

  void _startScan() {
    setState(() {
      _isScanning = true;
      _scanResult = null;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          final code = 1000 + Random().nextInt(8999);
          _scanResult = 'SW-QR-$code';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Quét mã (Demo)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Camera preview (minh họa)')),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bản demo sẽ trả về mã giả lập sau vài giây.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (_scanResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Chip(
                backgroundColor: Colors.green.shade100,
                label: Text('Kết quả: $_scanResult',
                    style: TextStyle(color: Colors.green.shade900)),
              ),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Đóng'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Colors.black,
          ),
          onPressed: _isScanning ? null : _startScan,
          child: Text(_isScanning ? 'Đang quét…' : 'Bắt đầu quét'),
        ),
      ],
    );
  }
}