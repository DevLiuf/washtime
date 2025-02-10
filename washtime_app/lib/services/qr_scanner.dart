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
      final response = await supabase
          .from('devices')
          .select()
          .eq('id', qrCode)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        _showMessage('없는 기기입니다');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context); // 스캔 화면 종료
        });
      } else if (response['status'] == 'inUse') {
        _showMessage('사용중인 기기입니다');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context); // 스캔 화면 종료
        });
      } else {
        // 사용 가능한 기기 -> UsageSetupPage로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UsageSetupPage(deviceId: qrCode),
          ),
        ).then((_) {
          // UsageSetupPage에서 돌아온 경우에만 스캔 플래그 해제
          if (mounted) {
            setState(() {
              _isScanned = false; // 플래그 초기화
            });
          }
        });
        return; // 화면 종료 로직 실행 안 함
      }
    } catch (e) {
      if (mounted) _showMessage('QR 스캔 중 오류 발생: $e');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context); // 스캔 화면 종료
      });
    } finally {
      if (mounted && !_isScanned) {
        setState(() {
          _isScanned = false; // 플래그 초기화
        });
      }
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
