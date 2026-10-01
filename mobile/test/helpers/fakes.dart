import 'package:easy_pomodoro/core/audio/audio_service.dart';
import 'package:easy_pomodoro/core/notifications/notification_service.dart';

/// Platform-free stand-ins so widget tests can boot the whole app.
class FakeNotifications implements NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<void> schedulePhaseEnd({
    required DateTime when,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> cancelPhaseEnd() async {}
}

class FakeAudio implements AudioService {
  @override
  Future<void> init() async {}

  @override
  Future<void> playBeep({required bool enabled}) async {}

  @override
  Future<void> dispose() async {}
}
