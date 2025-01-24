// main_page.dart
import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const DashboardPage(), // DashboardPage를 메인 페이지의 body에 포함
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/qrScanner');
        },
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.qr_code_scanner, color: Colors.black),
      ),
    );
  }
}
