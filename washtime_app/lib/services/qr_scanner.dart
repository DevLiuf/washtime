import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'supabase_service.dart';
import '../models/device_model.dart';

class QRScanner {
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> scanQRCode(BuildContext context) async {
    final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
    QRViewController? controller;

    // QR 스캔 UI
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('QR 코드 스캔'),
          ),
          body: QRView(
            key: qrKey,
            onQRViewCreated: (QRViewController qrController) {
              controller = qrController;
              qrController.scannedDataStream.listen((scanData) async {
                final qrCode = scanData.code;
                if (qrCode != null) {
                  controller?.pauseCamera();
                  Navigator.of(context).pop(); // QR 스캔 화면 닫기
                  await _handleQRCode(context, qrCode);
                }
              });
            },
          ),
        );
      },
    );

    // Dispose the controller after scanning
    controller?.dispose();
  }

  Future<void> _handleQRCode(BuildContext context, String qrCode) async {
    try {
      final device = await _supabaseService.getDeviceById(qrCode);

      if (device == null) {
        _showMessage(context, "없는 기기입니다");
        return;
      }

      if (device.status != 'Available') {
        _showMessage(context, "사용중입니다");
        return;
      }

      // 조건 만족: usage_setup_page로 이동
      Navigator.pushNamed(
        context,
        '/usage_setup',
        arguments: device,
      );
    } catch (e) {
      _showMessage(context, "QR 코드 처리 중 오류가 발생했습니다.");
      print('Error: $e');
    }
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 팝업 닫기
              Navigator.of(context).pop(); // 메인 화면으로 돌아가기
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
