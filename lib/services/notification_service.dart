import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    try {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Request the standard notification permission first
        final bool? standardPermission =
            await androidImplementation.requestNotificationsPermission();

        // Then, request the exact alarm permission
        final bool? exactAlarmPermission =
            await androidImplementation.requestExactAlarmsPermission();

        return (standardPermission ?? false) && (exactAlarmPermission ?? false);
      }

      // For iOS, just return true as permissions are handled differently
      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> scheduleRepeatingNotification({
    required int intervalMinutes,
    required String title,
    required String body,
  }) async {
    try {
      await _notifications.cancelAll();

      const androidDetails = AndroidNotificationDetails(
        'hydration_reminders',
        'Hydration Reminders',
        channelDescription: 'Reminders to drink water',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule multiple notifications for the next 24 hours
      final now = tz.TZDateTime.now(tz.local);
      final maxNotifications = (24 * 60 ~/ intervalMinutes)
          .clamp(1, 64); // Limit to 64 notifications

      for (int i = 1; i <= maxNotifications; i++) {
        final scheduledTime = now.add(Duration(minutes: intervalMinutes * i));

        // Only schedule if the time is in the future
        if (scheduledTime.isAfter(now)) {
          await _notifications.zonedSchedule(
            i,
            title,
            body,
            scheduledTime,
            details,
            payload: 'hydration_reminder',
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }
}
