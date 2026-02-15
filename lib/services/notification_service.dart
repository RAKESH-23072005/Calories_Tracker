import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Clean notification service for scheduling daily meal reminders.
/// Follows clean architecture — all notification logic is encapsulated here.
class NotificationService {
  // Singleton
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'meal_reminder_channel';
  static const String _channelName = 'Meal Reminders';
  static const String _channelDescription =
      'Daily meal and snack reminder notifications';

  // Notification IDs — fixed so we can check if already scheduled
  static const int _breakfastId = 0;
  static const int _morningSnackId = 1;
  static const int _lunchId = 2;
  static const int _eveningSnackId = 3;
  static const int _dinnerId = 4;
  static const int _calorieDeficitId = 100;

  // All 5 meal reminder definitions
  static const List<_MealReminder> _mealReminders = [
    _MealReminder(
      id: _breakfastId,
      hour: 8,
      minute: 0,
      title: 'Breakfast Time 🍳',
      body: 'Start your day healthy. Log your breakfast now!',
    ),
    _MealReminder(
      id: _morningSnackId,
      hour: 10,
      minute: 30,
      title: 'Snack Time 🍎',
      body: 'Have a healthy snack and log it now!',
    ),
    _MealReminder(
      id: _lunchId,
      hour: 13,
      minute: 0,
      title: 'Lunch Reminder 🥗',
      body: "Don't forget to log your lunch intake.",
    ),
    _MealReminder(
      id: _eveningSnackId,
      hour: 17,
      minute: 0,
      title: 'Evening Snack 🍌',
      body: 'Time for a light snack. Stay on track!',
    ),
    _MealReminder(
      id: _dinnerId,
      hour: 20,
      minute: 0,
      title: 'Dinner Time 🍽',
      body: 'Track your dinner and stay on target!',
    ),
  ];

  /// Initialize the notification plugin. Call once in main().
  static Future<void> init() async {
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

    await _instance._plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel
    final androidPlugin =
        _instance._plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );

      // Request notification permission on Android 13+
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Can be extended to deep-link into specific meal logging screens
  }

  /// Schedule all 5 daily meal reminder notifications.
  /// Uses deduplication — skips if notifications are already pending.
  static Future<void> scheduleDailyNotifications() async {
    final pendingNotifications =
        await _instance._plugin.pendingNotificationRequests();

    final scheduledIds =
        pendingNotifications.map((n) => n.id).toSet();

    for (final reminder in _mealReminders) {
      // Skip if this notification is already scheduled
      if (scheduledIds.contains(reminder.id)) continue;

      await _instance._plugin.zonedSchedule(
        reminder.id,
        reminder.title,
        reminder.body,
        _nextInstanceOfTime(reminder.hour, reminder.minute),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Schedule a one-time 9 PM calorie deficit reminder if consumed < target.
  /// Call this from the dashboard or a background check.
  static Future<void> scheduleCalorieDeficitReminder({
    required int consumedCalories,
    required int targetCalories,
  }) async {
    // Cancel any existing deficit reminder first
    await _instance._plugin.cancel(_calorieDeficitId);

    // Only schedule if there's a deficit
    if (consumedCalories >= targetCalories) return;

    final deficit = targetCalories - consumedCalories;

    await _instance._plugin.zonedSchedule(
      _calorieDeficitId,
      'Calorie Check 📊',
      "You're $deficit kcal short of your goal. Log your meals!",
      _nextInstanceOfTime(21, 0), // 9:00 PM
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // No matchDateTimeComponents — fires only once
    );
  }

  /// Cancel all scheduled notifications.
  static Future<void> cancelAll() async {
    await _instance._plugin.cancelAll();
  }

  /// Compute the next occurrence of [hour]:[minute] in the local timezone.
  /// If that time has already passed today, it returns tomorrow's occurrence.
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// Internal data class for meal reminder definitions.
class _MealReminder {
  final int id;
  final int hour;
  final int minute;
  final String title;
  final String body;

  const _MealReminder({
    required this.id,
    required this.hour,
    required this.minute,
    required this.title,
    required this.body,
  });
}
