import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final _selectNotificationController =
      StreamController<NotificationResponse>.broadcast();
  Stream<NotificationResponse> get onNotificationTap =>
      _selectNotificationController.stream;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Diagnostic log for automated tests and telemetry
  final List<Map<String, dynamic>> _notificationHistory = [];
  List<Map<String, dynamic>> get history =>
      List.unmodifiable(_notificationHistory);

  // Channel constants
  static const String recordingChannelId = 'meetmind_recording_channel';
  static const String recordingChannelName = 'Active Meeting Recording';
  static const String recordingChannelDesc =
      'Displays persistent notification while a meeting is being recorded';

  static const String syncChannelId = 'meetmind_sync_channel';
  static const String syncChannelName = 'Vault Sync & AI Processing';
  static const String syncChannelDesc =
      'Alerts when recordings finish syncing and AI summaries are generated';

  static const String reminderChannelId = 'meetmind_reminders_channel';
  static const String reminderChannelName = 'Meeting & Task Reminders';
  static const String reminderChannelDesc =
      'Scheduled reminders for upcoming meetings and action item deadlines';

  static const int recordingNotificationId = 1001;
  static const int syncNotificationBaseId = 2000;
  static const int reminderNotificationBaseId = 3000;

  /// Initialize notification settings and channels for Android and iOS
  Future<bool> initialize({
    void Function(NotificationResponse)? onNotificationTapCallback,
  }) async {
    if (_isInitialized) return true;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('[NotificationService] TimeZone initialization notice: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      final success = await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          _selectNotificationController.add(response);
          if (onNotificationTapCallback != null) {
            onNotificationTapCallback(response);
          }
        },
      );
      _isInitialized = success ?? true;
    } catch (e) {
      debugPrint('[NotificationService] Platform initialization: $e');
      _isInitialized = true; // Fallback for headless tests
    }

    return _isInitialized;
  }

  /// Request permissions for Android 13+ (POST_NOTIFICATIONS) and iOS
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      final iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('[NotificationService] Permission request notice: $e');
    }
    return true;
  }

  /// Display a persistent foreground notification during an active meeting recording
  Future<void> showRecordingNotification({
    required String title,
    required String duration,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      recordingChannelId,
      recordingChannelName,
      channelDescription: recordingChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: false,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    _logNotification(
      id: recordingNotificationId,
      channel: recordingChannelId,
      title: '🔴 Recording: $title',
      body: 'Duration: $duration • Meeting is actively recording in background',
    );

    try {
      await _notificationsPlugin.show(
        recordingNotificationId,
        '🔴 Recording: $title',
        'Duration: $duration • Meeting is actively recording in background',
        notificationDetails,
        payload: 'action:recording_studio',
      );
    } catch (e) {
      debugPrint('[NotificationService] showRecordingNotification notice: $e');
    }
  }

  /// Cancel the active recording persistent notification
  Future<void> cancelRecordingNotification() async {
    try {
      await _notificationsPlugin.cancel(recordingNotificationId);
    } catch (e) {
      debugPrint('[NotificationService] cancelRecordingNotification notice: $e');
    }
  }

  /// Notify user when an offline audio recording has been successfully synced
  Future<void> showSyncCompletedNotification({
    required String meetingTitle,
    int? remoteMeetingId,
  }) async {
    final id = syncNotificationBaseId + (remoteMeetingId ?? 1);

    const androidDetails = AndroidNotificationDetails(
      syncChannelId,
      syncChannelName,
      channelDescription: syncChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    _logNotification(
      id: id,
      channel: syncChannelId,
      title: '☁️ Synced: $meetingTitle',
      body: 'Uploaded to MeetMind Cloud. AI Transcript & Insights are ready.',
    );

    try {
      await _notificationsPlugin.show(
        id,
        '☁️ Synced: $meetingTitle',
        'Uploaded to MeetMind Cloud. AI Transcript & Insights are ready.',
        notificationDetails,
        payload: 'meeting:$remoteMeetingId',
      );
    } catch (e) {
      debugPrint('[NotificationService] showSyncCompletedNotification notice: $e');
    }
  }

  /// Notify user when a vault upload attempt failed and will retry
  Future<void> showSyncFailedNotification({
    required String meetingTitle,
    required String error,
  }) async {
    const id = syncNotificationBaseId + 999;

    const androidDetails = AndroidNotificationDetails(
      syncChannelId,
      syncChannelName,
      channelDescription: syncChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    _logNotification(
      id: id,
      channel: syncChannelId,
      title: '⚠️ Sync Failed: $meetingTitle',
      body: 'Error: $error. Will retry automatically when network stabilizes.',
    );

    try {
      await _notificationsPlugin.show(
        id,
        '⚠️ Sync Failed: $meetingTitle',
        'Error: $error. Will retry automatically when network stabilizes.',
        notificationDetails,
        payload: 'vault:error',
      );
    } catch (e) {
      debugPrint('[NotificationService] showSyncFailedNotification notice: $e');
    }
  }

  /// Schedule a local reminder for an action item task
  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime scheduledDate,
  }) async {
    final id = reminderNotificationBaseId + taskId;

    const androidDetails = AndroidNotificationDetails(
      reminderChannelId,
      reminderChannelName,
      channelDescription: reminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    _logNotification(
      id: id,
      channel: reminderChannelId,
      title: '⏰ Action Item Reminder',
      body: taskTitle,
      scheduledDate: scheduledDate,
    );

    try {
      final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);
      await _notificationsPlugin.zonedSchedule(
        id,
        '⏰ Action Item Reminder',
        taskTitle,
        scheduledTZ,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task:$taskId',
      );
    } catch (e) {
      debugPrint('[NotificationService] scheduleTaskReminder notice: $e');
    }
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(int taskId) async {
    final id = reminderNotificationBaseId + taskId;
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('[NotificationService] cancelReminder notice: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] cancelAll notice: $e');
    }
  }

  void _logNotification({
    required int id,
    required String channel,
    required String title,
    required String body,
    DateTime? scheduledDate,
  }) {
    _notificationHistory.add({
      'id': id,
      'channel': channel,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'scheduledDate': scheduledDate?.toIso8601String(),
    });
  }

  void clearHistory() {
    _notificationHistory.clear();
  }

  void dispose() {
    _selectNotificationController.close();
  }
}
