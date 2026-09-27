import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  static const _id = 1001;

  Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _ready = true;
  }

  Future<void> schedulePhaseEnd({
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready) await init();
    await cancelPhaseEnd();
    if (when.isBefore(DateTime.now())) return;

    final tzWhen = tz.TZDateTime.from(when, tz.local);
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_phase',
      'Pomodoro Fazları',
      channelDescription: 'Faz bitiş bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _id,
      title,
      body,
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelPhaseEnd() async {
    if (!_ready) await init();
    await _plugin.cancel(_id);
  }
}