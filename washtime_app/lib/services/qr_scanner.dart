// qr_scanner.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washtime_app/screens/usage_setup_page.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  _QrScannerPageState createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  void _onQrCodeScanned(String qrCode) async {
    if (qrCode.isEmpty) return; // Invalid QR code

    try {
      final response = await supabase
          .from('devices')
          .select()
          .eq('id', qrCode)
          .maybeSingle();

      if (response == null) {
        _showMessage('없는 기기입니다');
        Navigator.pop(context);
      } else if (response['status'] == 'inUse') {
        _showMessage('사용중입니다');
        Navigator.pop(context);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UsageSetupPage(deviceId: qrCode),
          ),
        );
      }
    } catch (e) {
      _showMessage('QR 스캔 중 오류 발생: $e');
      Navigator.pop(context);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 스캔'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? rawValue = barcode.rawValue;
            if (rawValue != null) {
              _onQrCodeScanned(rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}
