import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/audio/audio_service.dart';
import '../core/notifications/notification_service.dart';
import '../core/storage/app_storage.dart';
import '../core/storage/demo_seed.dart';
import '../features/timer/application/pomodoro_notifier.dart';
import '../features/timer/application/settings_notifier.dart';
import '../features/timer/domain/pomodoro_settings.dart';
import 'app.dart';
import 'router.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Offline-first: DM Sans + Fraunces ship in assets/google_fonts, so the
  // first launch never depends on fonts.gstatic.com.
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final family in ['DMSans', 'Fraunces']) {
      final text = await rootBundle.loadString('assets/google_fonts/OFL-$family.txt');
      yield LicenseEntryWithLineBreaks(['google_fonts', family], text);
    }
  });
  await initializeDateFormatting('tr');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Edge-to-edge (Android 15+ / modern M3)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final storage = AppStorage(prefs);
  const seedDemo = bool.fromEnvironment('SEED_DEMO', defaultValue: false);
  if (seedDemo) {
    await seedDemoIfEmpty(storage);
  }
  const styleOverride = String.fromEnvironment('SURFACE_STYLE', defaultValue: '');
  if (styleOverride.isNotEmpty) {
    final match = UiSurfaceStyle.values.where((e) => e.name == styleOverride);
    if (match.isNotEmpty) {
      final cur = storage.loadSettings();
      await storage.saveSettings(cur.copyWith(uiStyle: match.first));
    }
  }
  final notifications = NotificationService();
  await notifications.init();
  final audio = AudioService();
  await audio.init();

  final router = createRouter();

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
        audioServiceProvider.overrideWithValue(audio),
      ],
      child: EasyPomodoroApp(router: router),
    ),
  );
}
