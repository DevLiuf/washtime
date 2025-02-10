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
  bool _isScanned = false; // 중복 호출 방지 플래그

  void _onQrCodeScanned(String qrCode) async {
    if (_isScanned) return; // 중복 방지

    setState(() {
      _isScanned = true; // 스캔 플래그 설정
    });

    try {
      final int deviceId = int.tryParse(qrCode) ?? -1;
      if (deviceId == -1) {
        _showMessage('잘못된 QR 코드입니다.');
        return _returnToMain();
      }

      // 🔹 기기 정보 확인
      final deviceResponse = await supabase
          .from('devices')
          .select()
          .eq('id', deviceId)
          .maybeSingle();

      if (!mounted) return;

      if (deviceResponse == null) {
        _showMessage('없는 기기입니다');
        return _returnToMain();
      }

      // 🔹 작동 중인지 확인
      final activeLog = await supabase
          .from('operation_logs')
          .select()
          .eq('washerid', deviceId)
          .gte('endtime', DateTime.now().toIso8601String())
          .maybeSingle();

      if (activeLog != null) {
        _showMessage('사용중인 기기입니다');
        return _returnToMain();
      }

      // 사용 가능한 기기 -> UsageSetupPage로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UsageSetupPage(deviceId: deviceId.toString()),
        ),
      ).then((_) => _resetScanFlag());
    } catch (e) {
      _showMessage('QR 스캔 중 오류 발생: $e');
      _returnToMain();
    }
  }

  void _returnToMain() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context); // 스캔 화면 종료
    });
  }

  void _resetScanFlag() {
    if (mounted) {
      setState(() {
        _isScanned = false; // 플래그 초기화
      });
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 스캔'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (!_isScanned) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? rawValue = barcode.rawValue;
              if (rawValue != null) {
                _onQrCodeScanned(rawValue);
                break; // 한 번만 처리
              }
            }
          }
        },
      ),
    );
  }
}
