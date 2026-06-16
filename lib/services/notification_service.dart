import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _morningReminderId = 0; //Needed for zoneSchedule
  static const int _eveningReminderId = 1;


  Future<void> init() async {
    await _configureLocalTimeZone();

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(iOS: iosSettings,),
    );

    await _plugin //Request permission to send notification
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await scheduleDailyReminders();
  }


  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Falls back to UTC if the device timezone can't be determined.
    }
  }

  Future<void> scheduleDailyReminders() async {
    await _scheduleDaily(
      id: _morningReminderId,
      hour: 7,
      minute: 0,
      title: 'Good morning! ☀️',
      body: 'Start the day with a good breathing section and check how much you recovered during your sleep!'
    );

    await _scheduleDaily(
      id: _eveningReminderId, 
      hour: 21,
      minute: 0, 
      title: 'Evening check-in 💤',
      body: 'Wind down before going to sleep, let''s do some breathing'
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOf(hour, minute),
      notificationDetails: const NotificationDetails(iOS: DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, //Needs to stay because zonedSchedule needs this
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

}