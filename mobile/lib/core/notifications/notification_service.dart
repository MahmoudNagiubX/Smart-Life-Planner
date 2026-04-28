import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'notification_actions.dart';

class NotificationService {
  static const _channelId = 'smart_life_planner_channel';
  static const _channelName = 'Smart Life Planner';
  static const _channelDescription = 'Reminders and alerts';

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  void Function(NotificationResponse response)? _responseHandler;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    _responseHandler?.call(response);
  }

  void setResponseHandler(
    void Function(NotificationResponse response) handler,
  ) {
    _responseHandler = handler;
  }

  Future<void> requestPermissions() async {
    await Permission.notification.request();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  // Schedule a notification at an exact time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    String? payload,
    List<AndroidNotificationAction> actions = const [],
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          actions: actions,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  // Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static const taskReminderActions = <AndroidNotificationAction>[
    AndroidNotificationAction(
      NotificationActions.markTaskDone,
      'Mark done',
      showsUserInterface: true,
    ),
    AndroidNotificationAction(NotificationActions.snooze10, 'Snooze 10m'),
    AndroidNotificationAction(NotificationActions.snooze60, 'Snooze 1h'),
    AndroidNotificationAction(
      NotificationActions.reschedule,
      'Reschedule',
      showsUserInterface: true,
    ),
    AndroidNotificationAction(NotificationActions.dismiss, 'Dismiss'),
    AndroidNotificationAction(
      NotificationActions.openTask,
      'Open task',
      showsUserInterface: true,
    ),
  ];
}
