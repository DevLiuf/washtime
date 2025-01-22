import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import '../services/qr_scanner.dart';

class MainPage extends StatelessWidget {
  final qrScanner = QRScanner(); // QR 스캐너 인스턴스 생성

  MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('세탁기 관리 앱')),
        body: const DashboardPage(), // 대시보드만 렌더링
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await qrScanner.scanQRCode(context); // QR 스캔 실행
          },
          backgroundColor: Colors.yellow,
          child: const Icon(Icons.qr_code_scanner, color: Colors.black),
        ),
      ),
    );
  }
}
