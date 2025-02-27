import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(settings);

    tz.initializeTimeZones();
  }

  // ✅ Android & iOS 통합된 알람 예약 함수
  static Future<void> setAlarmForDevice(int deviceId, DateTime endTime) async {
    final alarmTime = endTime.subtract(const Duration(minutes: 5));
    debugPrint(
        "🔔 [알람 예약] 기기 ID: $deviceId | 종료시간: $endTime | 알람 시간: $alarmTime");

    if (alarmTime.isAfter(DateTime.now())) {
      await _notificationsPlugin.zonedSchedule(
        deviceId,
        '세탁이 곧 완료됩니다!',
        '기기 ID: $deviceId - 5분 후 종료됩니다.',
        tz.TZDateTime.from(alarmTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'washtime_alarm_channel',
            '기기 종료 알람',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true, // ✅ 백그라운드에서 알람 뜨도록 설정
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            categoryIdentifier: 'WASHTIME_ALERT', // ✅ iOS 백그라운드 알람 트리거
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // ✅ Android 절전 모드에서도 실행
      );
      debugPrint("✅ 알람 설정 완료: 기기 ID $deviceId");
    } else {
      debugPrint("⚠️ 알람 시간이 현재보다 이전이라 예약되지 않음!");
    }
  }

  // ✅ 모든 알람 취소
  static Future<void> clearAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }

  // ✅ 앱이 재시작될 때 기존 알람 복구
  static Future<void> restartAlarmOnReboot() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      debugPrint("🔄 재등록된 알람: ${notification.id}");
    }
  }
}
