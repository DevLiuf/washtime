import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washtime_app/screens/main_page.dart';
import 'package:washtime_app/screens/login_page.dart';
import 'package:washtime_app/services/qr_scanner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mrbpenlhhfclyskhbmgx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yYnBlbmxoaGZjbHlza2hibWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MTAyMTQsImV4cCI6MjA1MzA4NjIxNH0.ypM1AroBYRs84mEbHKNiuUAqTMVLd2F8BH1UJ3l7Mps',
  );

  await _requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final String? uuid = prefs.getString('user_uuid');
  final bool isLoggedIn = uuid != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.notification,
  ].request();
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // 기준 해상도 설정 (기기마다 자동 조정)
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Washtime App',
          theme: ThemeData(primarySwatch: Colors.blue),
          initialRoute: isLoggedIn ? '/main' : '/login',
          routes: {
            '/main': (context) => const MainPage(),
            '/login': (context) => const LoginPage(),
            '/qrScanner': (context) => const QrScannerPage(),
          },
        );
      },
    );
  }
}
