import 'dart:async';
import 'dart:convert';

import 'package:easy_pomodoro/app/app.dart';
import 'package:easy_pomodoro/app/router.dart';
import 'package:easy_pomodoro/core/storage/app_storage.dart';
import 'package:easy_pomodoro/core/theme/app_surface_style.dart';
import 'package:easy_pomodoro/features/timer/application/pomodoro_notifier.dart';
import 'package:easy_pomodoro/features/timer/application/settings_notifier.dart';
import 'package:easy_pomodoro/features/timer/domain/pomodoro_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'easy-pomodoro:settings': jsonEncode(
        PomodoroSettings.defaults
            .copyWith(themeMode: AppThemeMode.light)
            .toJson(),
      ),
    });
    final storage = AppStorage(await SharedPreferences.getInstance());
    final container = ProviderContainer(overrides: [
      appStorageProvider.overrideWithValue(storage),
      notificationServiceProvider.overrideWithValue(FakeNotifications()),
      audioServiceProvider.overrideWithValue(FakeAudio()),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: EasyPomodoroApp(router: createRouter()),
      ),
    );
    // Let bundled fonts finish loading outside the fake clock.
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  // The timer screen ticks every second, so pumpAndSettle would never settle.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> unmount(WidgetTester tester, ProviderContainer c) async {
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  }

  AppSurfaceStyle surfaceOf(WidgetTester tester) =>
      tester.element(find.text('Başlat')).surfaceStyle;

  for (final (from, to) in [
    (UiSurfaceStyle.neo, UiSurfaceStyle.glass),
    (UiSurfaceStyle.glass, UiSurfaceStyle.skeuo),
    (UiSurfaceStyle.skeuo, UiSurfaceStyle.neo),
  ]) {
    testWidgets('${from.name} → ${to.name} morphs without remounting',
        (tester) async {
      final c = await pumpApp(tester);
      await c.read(settingsProvider.notifier).setUiStyle(from);
      await settle(tester);
      expect(surfaceOf(tester).style, from);

      final shellState = tester.state(find.byType(Navigator).first);
      final screenElement = tester.element(find.text('Başlat'));

      await c.read(settingsProvider.notifier).setUiStyle(to);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Mid-animation: a genuine blend of both styles.
      final mid = surfaceOf(tester);
      expect(mid.isBlending, isTrue);
      expect(mid.weightOf(from), greaterThan(0));
      expect(mid.weightOf(to), greaterThan(0));

      await settle(tester);
      expect(surfaceOf(tester).style, to);
      expect(surfaceOf(tester).isBlending, isFalse);

      // The page tree is reused, not rebuilt from scratch.
      expect(tester.state(find.byType(Navigator).first), same(shellState));
      expect(tester.element(find.text('Başlat')), same(screenElement));

      // Scaffolds never paint their own (lerping) background.
      for (final s in tester.widgetList<Scaffold>(find.byType(Scaffold))) {
        expect(s.backgroundColor, isNull);
      }
      await unmount(tester, c);
    });
  }

  testWidgets('clock ticks only while the timer runs', (tester) async {
    final c = await pumpApp(tester);
    var ticks = 0;
    final sub = c.listen(timerTickProvider, (_, _) => ticks++);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(ticks, 0, reason: 'idle screen must not rebuild every second');

    // Not awaited: the wakelock platform call never answers under the fake
    // clock, but the running state is set synchronously.
    unawaited(c.read(pomodoroProvider.notifier).start());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(ticks, greaterThanOrEqualTo(2));

    unawaited(c.read(pomodoroProvider.notifier).pause());
    await tester.pump();
    sub.close();
    await unmount(tester, c);
  });

  testWidgets('nav + opens the new task sheet', (tester) async {
    final c = await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await settle(tester);
    expect(find.text('Yeni görev'), findsOneWidget);
    expect(find.text('Görevler'), findsOneWidget);

    Navigator.of(tester.element(find.text('Yeni görev'))).pop();
    await settle(tester);
    expect(find.text('Yeni görev'), findsNothing);
    await unmount(tester, c);
  });
}
