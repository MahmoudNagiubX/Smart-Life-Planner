import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'notification_actions.dart';

class NotificationService {
  static const _channelId = 'smart_life_planner_channel';
  static const _channelName = 'Smart Life Planner';
  static const _channelDescription = 'Reminders and alerts';
  static const _silentChannelId = 'smart_life_planner_silent_channel';
  static const _silentChannelName = 'Smart Life Planner Silent';
  static const _athanChannelId = 'smart_life_planner_athan_channel';
  static const _athanChannelName = 'Smart Life Planner Athan';
  static const _athanSound = RawResourceAndroidNotificationSound('athan_soft');

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
    await _createAndroidChannels(android);

    _initialized = true;
  }

  Future<void> _createAndroidChannels(
    AndroidFlutterLocalNotificationsPlugin? android,
  ) async {
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _silentChannelId,
        _silentChannelName,
        description: 'Silent reminders and alerts',
        importance: Importance.high,
        playSound: false,
      ),
    );
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _athanChannelId,
        _athanChannelName,
        description: 'Prayer reminders with the bundled Athan sound',
        importance: Importance.high,
        playSound: true,
        sound: _athanSound,
      ),
    );
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
    String notificationSoundKey = 'default',
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      NotificationDetails(
        android: _androidDetails(
          notificationSoundKey: notificationSoundKey,
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
    String notificationSoundKey = 'default',
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: _androidDetails(notificationSoundKey: notificationSoundKey),
      ),
      payload: payload,
    );
  }

  Future<void> showPrayerSoundPreview({required String soundKey}) async {
    await showNotification(
      id: 91406,
      title: 'Prayer Sound Preview',
      body: soundKey == 'silent'
          ? 'This preview should appear without sound where supported.'
          : 'This preview uses your selected prayer reminder sound.',
      payload: 'prayer:sound-preview',
      notificationSoundKey: soundKey,
    );
  }

  AndroidNotificationDetails _androidDetails({
    String notificationSoundKey = 'default',
    List<AndroidNotificationAction> actions = const [],
  }) {
    final soundKey = _normalizedSoundKey(notificationSoundKey);
    final channelId = switch (soundKey) {
      'silent' => _silentChannelId,
      'athan' => _athanChannelId,
      _ => _channelId,
    };
    final channelName = switch (soundKey) {
      'silent' => _silentChannelName,
      'athan' => _athanChannelName,
      _ => _channelName,
    };

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: soundKey != 'silent',
      sound: soundKey == 'athan' ? _athanSound : null,
      actions: actions,
    );
  }

  String _normalizedSoundKey(String value) {
    return switch (value) {
      'silent' || 'athan' => value,
      _ => 'default',
    };
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
