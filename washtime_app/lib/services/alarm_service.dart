import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:event_bus/event_bus.dart';

class AlarmEvent {
  final int deviceId;
  AlarmEvent(this.deviceId);
}

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final EventBus eventBus = EventBus();

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
    final now = DateTime.now();

    if (alarmTime.isBefore(now)) {
      debugPrint("⚠️ [알람 예약 스킵] 이미 지난 시간: $alarmTime (현재 시간: $now)");
      return;
    }

    debugPrint(
        "🔔 [알람 예약] 기기 ID: $deviceId | 종료시간: $endTime | 알람 시간: $alarmTime");

    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      debugPrint("✅ [포그라운드] 즉시 알람 UI 표시");
      eventBus.fire(AlarmEvent(deviceId));
    }

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

    debugPrint("✅ [알람 예약 완료] 기기 ID $deviceId");
  }

  static Future<void> cancelAlarm(int deviceId) async {
    await _notificationsPlugin.cancel(deviceId);
    debugPrint("❌ 알람 취소 완료: 기기 ID $deviceId");
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
