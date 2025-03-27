import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:washtime_app/screens/main_page.dart';
import 'package:washtime_app/screens/login_page.dart';
import 'package:washtime_app/services/alarm_service.dart';
import 'package:washtime_app/services/qr_scanner.dart';
import 'package:washtime_app/styles/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService.initialize();
  await requestNotificationPermission();
  await AlarmService.restartAlarmOnReboot();

  await Supabase.initialize(
    url: 'https://mrbpenlhhfclyskhbmgx.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1yYnBlbmxoaGZjbHlza2hibWd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc1MTAyMTQsImV4cCI6MjA1MzA4NjIxNH0.ypM1AroBYRs84mEbHKNiuUAqTMVLd2F8BH1UJ3l7Mps',
  );

  final prefs = await SharedPreferences.getInstance();
  final String? uuid = prefs.getString('user_uuid');
  final bool isLoggedIn = uuid != null;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    AlarmService.eventBus.on<AlarmEvent>().listen((event) {
      _showGlobalDialog(event.deviceId);
    });
  }

  void _showGlobalDialog(int deviceId) {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('세탁 알림'),
        content: Text('기기 ID: $deviceId 종료 5분 전입니다!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Washtime App',
          theme: appTheme,
          initialRoute: widget.isLoggedIn ? '/main' : '/login',
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
