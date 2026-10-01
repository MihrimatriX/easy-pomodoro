import 'package:easy_pomodoro/core/theme/app_palette.dart';
import 'package:easy_pomodoro/features/timer/domain/pomodoro_phase.dart';
import 'package:easy_pomodoro/features/timer/domain/pomodoro_settings.dart';
import 'package:easy_pomodoro/features/timer/domain/timer_session.dart';
import 'package:easy_pomodoro/features/timer/domain/timer_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PomodoroSettings', () {
    test('round-trips through JSON', () {
      const s = PomodoroSettings(
        focusMin: 50,
        shortBreakMin: 10,
        longBreakMin: 30,
        longBreakEvery: 3,
        autoStart: false,
        sound: false,
        notifications: false,
        themeMode: AppThemeMode.dark,
        wakelock: false,
        uiStyle: UiSurfaceStyle.glass,
        paletteId: ColorPaletteId.forest,
      );
      final back = PomodoroSettings.fromJson(s.toJson());
      expect(back.toJson(), s.toJson());
    });

    test('accepts legacy keys and falls back on unknown values', () {
      final legacy = PomodoroSettings.fromJson({
        'surfaceStyle': 'skeuo',
        'colorTheme': 'ocean',
        'themeMode': 'sepia',
      });
      expect(legacy.uiStyle, UiSurfaceStyle.skeuo);
      expect(legacy.paletteId, ColorPaletteId.ocean);
      expect(legacy.themeMode, AppThemeMode.system);
      expect(PomodoroSettings.fromJson(null).uiStyle, UiSurfaceStyle.neo);
    });
  });

  group('TimerSession', () {
    test('every Nth focus goes to a long break', () {
      var count = 0;
      var cycle = 0;
      final phases = <PomodoroPhase>[];
      for (var i = 0; i < 4; i++) {
        final next = TimerSession.nextPhase(
          current: PomodoroPhase.focus,
          pomodoroCount: count,
          focusCompletedInCycle: cycle,
          longBreakEvery: 4,
        );
        phases.add(next.phase);
        count = next.pomodoroCount;
        cycle = next.focusCompletedInCycle;
      }
      expect(phases, [
        PomodoroPhase.shortBreak,
        PomodoroPhase.shortBreak,
        PomodoroPhase.shortBreak,
        PomodoroPhase.longBreak,
      ]);
      expect(cycle, 0);
    });

    test('skipping focus does not count a tomato', () {
      final next = TimerSession.nextPhase(
        current: PomodoroPhase.focus,
        pomodoroCount: 2,
        focusCompletedInCycle: 2,
        longBreakEvery: 4,
        countFocus: false,
      );
      expect(next.phase, PomodoroPhase.shortBreak);
      expect(next.pomodoroCount, 2);
    });

    test('remaining time follows the wall clock and pauses', () {
      final start = DateTime(2026, 1, 1, 9);
      final running = TimerSession(
        status: TimerStatus.running,
        startedAt: start,
        duration: 1500,
      );
      expect(running.remainingAt(start.add(const Duration(seconds: 100))), 1400);
      expect(running.remainingAt(start.add(const Duration(hours: 1))), 0);
      final paused = running.copyWith(
        status: TimerStatus.paused,
        pausedRemaining: 600,
        clearStartedAt: true,
      );
      expect(paused.remainingAt(start.add(const Duration(hours: 5))), 600);
      expect(paused.progressAt(start), closeTo(0.6, 1e-9));
    });
  });
}
