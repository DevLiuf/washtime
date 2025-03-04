import 'package:flutter/material.dart';
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
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("🔔 [알람 클릭됨] Payload: ${response.payload}");
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    tz.initializeTimeZones();
  }

  @pragma('vm:entry-point')
  static void notificationTapBackground(NotificationResponse response) {
    debugPrint("🔔 [백그라운드 알람 클릭됨] Payload: ${response.payload}");
  }

  static Future<void> setAlarmForDevice(int deviceId, DateTime endTime) async {
    final alarmTime = endTime.subtract(const Duration(minutes: 5));
    debugPrint(
        "🔔 [알람 예약] 기기 ID: $deviceId | 종료시간: $endTime | 알람 시간: $alarmTime");

    if (alarmTime.isAfter(DateTime.now())) {
      final now = DateTime.now();
      final difference = alarmTime.difference(now);

      Future.delayed(difference, () async {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          debugPrint('✅ 포그라운드 상태: 알람 대신 UI 표시');
          // TODO: EventBus 또는 상태 관리로 알림 전달
        } else {
          debugPrint('✅ 백그라운드/종료 상태: 로컬 알람 울림');
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
                fullScreenIntent: true,
                playSound: true,
              ),
              iOS: DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
                categoryIdentifier: 'WASHTIME_ALERT',
                interruptionLevel: InterruptionLevel.timeSensitive,
              ),
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      });

      debugPrint("✅ 알람 설정 완료: 기기 ID $deviceId");
    } else {
      debugPrint("⚠️ 알람 시간이 현재보다 이전이라 예약되지 않음!");
    }
  }

  static Future<void> clearAllAlarms() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> restartAlarmOnReboot() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _notificationsPlugin.pendingNotificationRequests();

    for (var notification in pendingNotifications) {
      debugPrint("🔄 재등록된 알람: ${notification.id}");
    }
  }
}
