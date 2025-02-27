import 'package:flutter/material.dart';
import 'package:washtime_app/screens/dashboard_page.dart';
import 'package:washtime_app/screens/my_page.dart';
import 'package:washtime_app/screens/my_device.dart';
import 'package:washtime_app/services/qr_scanner.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final int _selectedIndex = 1; // 기본값: QR 스캔 버튼 위치

  void _onItemTapped(int index) {
    if (index == 0) {
      // 마이페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyPage()),
      );
    } else if (index == 1) {
      // QR 스캔 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrScannerPage()),
      );
    } else if (index == 2) {
      // 내 기기 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MyDevicePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const DashboardPage(), // 기본적으로 대시보드 유지
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'QR 스캔'),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: '내 기기'),
        ],
        currentIndex: 1, // QR 스캔 버튼이 중앙 (하지만 눌러도 이동X)
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // 선택된 아이템 색상
      ),
    );
  }
}
