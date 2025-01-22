import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washtime_app/models/device_model.dart';
import 'package:washtime_app/screens/main_page.dart';
import 'package:washtime_app/screens/usage_setup_page.dart';
import 'package:washtime_app/services/device_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //supabase 초기화
  await Supabase.initialize(
    url: 'https://mrbpenlhhfclyskhbmgx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yYnBlbmxoaGZjbHlza2hibWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MTAyMTQsImV4cCI6MjA1MzA4NjIxNH0.ypM1AroBYRs84mEbHKNiuUAqTMVLd2F8BH1UJ3l7Mps',
  );

  final service = DeviceService();
  final devices = await service.getAllDevices();
  print(devices); // 기기 목록 출력

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '공유 기기 알람 앱',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // 초기 화면
      routes: {
        '/': (context) => MainPage(), // 메인 페이지
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/usage_setup') {
          final args = settings.arguments as DeviceModel; // 전달된 매개변수 받기
          return MaterialPageRoute(
            builder: (context) => UsageSetupPage(device: args), // 매개변수 전달
          );
        }
        return null; // 정의되지 않은 라우트는 null 반환
      },
    );
  }
}
