import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/app_storage.dart';
import '../../habits/application/habits_notifier.dart';
import '../../habits/domain/habit.dart';
import '../../tasks/application/tasks_notifier.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/pomodoro_settings.dart';
import '../domain/timer_session.dart';
import '../domain/timer_status.dart';
import 'history_notifier.dart';
import 'settings_notifier.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden');
});

final audioServiceProvider = Provider<AudioService>((ref) {
  throw UnimplementedError('AudioService must be overridden');
});

/// UI clock tick — forces a rebuild every second, but only while the timer is
/// running. Idle / paused screens stay still instead of repainting (and
/// draining battery) once per second.
final timerTickProvider = StreamProvider<DateTime>((ref) {
  final running = ref.watch(pomodoroProvider.select((s) => s.isRunning));
  if (!running) return Stream.value(DateTime.now());
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Set true after a focus phase completes so Timer UI can offer habit check-in.
final pendingHabitPromptProvider =
    NotifierProvider<PendingHabitPromptNotifier, bool>(
  PendingHabitPromptNotifier.new,
);

class PendingHabitPromptNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void offer() => state = true;

  void clear() => state = false;
}

final pomodoroProvider =
    NotifierProvider<PomodoroNotifier, TimerSession>(PomodoroNotifier.new);

class PomodoroNotifier extends Notifier<TimerSession> {
  bool _completing = false;

  AppStorage get _storage => ref.read(appStorageProvider);
  PomodoroSettings get _settings => ref.read(settingsProvider);
  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);
  AudioService get _audio => ref.read(audioServiceProvider);

  @override
  TimerSession build() {
    final settings = ref.read(settingsProvider);
    final loaded = _storage.loadTimer(
      fallbackDuration: settings.durationSecFor(PomodoroPhase.focus),
    );
    ref.listen<PomodoroSettings>(settingsProvider, (prev, next) {
      // Durations only — theme/sound must not reload timer snapshot.
      if (prev?.focusMin != next.focusMin ||
          prev?.shortBreakMin != next.shortBreakMin ||
          prev?.longBreakMin != next.longBreakMin) {
        syncDurationFromSettings();
      }
      _syncWakelock();
    });
    Future.microtask(() => reconcile());
    return loaded;
  }

  Future<void> _persist() => _storage.saveTimer(state);

  Future<void> _syncWakelock() async {
    final on = _settings.wakelock &&
        state.isRunning &&
        state.phase == PomodoroPhase.focus;
    try {
      if (on) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  Future<void> start() async {
    final now = DateTime.now();
    if (state.isPaused) {
      final rem = state.pausedRemaining ?? state.duration;
      state = state.copyWith(
        status: TimerStatus.running,
        startedAt: now.subtract(Duration(seconds: state.duration - rem)),
        clearPausedRemaining: true,
      );
    } else {
      state = state.copyWith(
        status: TimerStatus.running,
        startedAt: now,
        duration: state.duration > 0
            ? state.duration
            : _settings.durationSecFor(state.phase),
        clearPausedRemaining: true,
      );
    }
    await _persist();
    await _syncWakelock();
  }

  Future<void> pause() async {
    if (!state.isRunning) return;
    final rem = state.remainingAt(DateTime.now());
    state = state.copyWith(
      status: TimerStatus.paused,
      pausedRemaining: rem,
      clearStartedAt: true,
    );
    await _persist();
    await _notifications.cancelPhaseEnd();
    await _syncWakelock();
  }

  Future<void> reset({bool confirmed = false}) async {
    if (!confirmed) return;
    final duration = _settings.durationSecFor(state.phase);
    state = state.copyWith(
      status: TimerStatus.idle,
      duration: duration,
      clearStartedAt: true,
      clearPausedRemaining: true,
      pausedRemaining: null,
    );
    await _persist();
    await _notifications.cancelPhaseEnd();
    await _syncWakelock();
  }

  Future<void> skip() async {
    await _notifications.cancelPhaseEnd();
    await _advancePhase(countFocus: false);
  }

  Future<void> reconcile() async {
    if (_completing) return;
    final now = DateTime.now();
    if (state.isRunning) {
      final rem = state.remainingAt(now);
      if (rem <= 0) {
        await _completePhase();
        return;
      }
    }
    await _syncWakelock();
  }

  Future<void> onAppPaused() async {
    if (!state.isRunning) {
      await _persist();
      return;
    }
    await _persist();
    if (!_settings.notifications) return;
    final rem = state.remainingAt(DateTime.now());
    if (rem <= 0) return;
    final when = DateTime.now().add(Duration(seconds: rem));
    final title = state.phase.isBreak ? 'Mola bitti' : 'Odak bitti';
    final body = state.phase.isBreak
        ? 'Odaklanmaya dönme zamanı.'
        : 'Kısa bir mola iyi gelebilir.';
    await _notifications.schedulePhaseEnd(
      when: when,
      title: title,
      body: body,
    );
  }

  Future<void> onAppResumed() async {
    await _notifications.cancelPhaseEnd();
    await reconcile();
  }

  Future<void> _completePhase() async {
    if (_completing) return;
    _completing = true;
    try {
      await _notifications.cancelPhaseEnd();
      await _audio.playBeep(enabled: _settings.sound);

      if (state.phase == PomodoroPhase.focus) {
        final activeTaskId = ref.read(activeTaskIdProvider);
        await ref.read(historyProvider.notifier).addFocusSession(
              durationSec: state.duration,
              taskId: activeTaskId,
            );
        await _autoMarkLinkedHabit(activeTaskId);
        ref.read(pendingHabitPromptProvider.notifier).offer();
      }

      await _advancePhase(countFocus: state.phase == PomodoroPhase.focus);
    } finally {
      _completing = false;
    }
  }

  /// If the active task has a linked habit, mark it done for today.
  Future<void> _autoMarkLinkedHabit(String? taskId) async {
    if (taskId == null) return;
    final task = ref.read(tasksProvider.notifier).byId(taskId);
    final habitId = task?.linkedHabitId;
    if (habitId == null) return;
    final habits = ref.read(habitsProvider);
    Habit? habit;
    for (final h in habits) {
      if (h.id == habitId) {
        habit = h;
        break;
      }
    }
    if (habit == null || habit.isDoneToday) return;
    await ref.read(habitsProvider.notifier).toggleToday(habitId);
  }

  Future<void> _advancePhase({required bool countFocus}) async {
    final next = TimerSession.nextPhase(
      current: state.phase,
      pomodoroCount: state.pomodoroCount,
      focusCompletedInCycle: state.focusCompletedInCycle,
      longBreakEvery: _settings.longBreakEvery,
      countFocus: countFocus,
    );
    final duration = _settings.durationSecFor(next.phase);
    final auto = _settings.autoStart;

    state = TimerSession(
      phase: next.phase,
      status: auto ? TimerStatus.running : TimerStatus.idle,
      startedAt: auto ? DateTime.now() : null,
      duration: duration,
      focusCompletedInCycle: next.focusCompletedInCycle,
      pomodoroCount: next.pomodoroCount,
    );
    await _persist();
    await _syncWakelock();
  }

  /// Apply new durations when idle (settings change).
  Future<void> syncDurationFromSettings() async {
    if (!state.isIdle) return;
    final duration = _settings.durationSecFor(state.phase);
    if (duration == state.duration) return;
    state = state.copyWith(duration: duration);
    await _persist();
  }

  int displayRound(PomodoroSettings settings) {
    final interval = settings.longBreakEvery < 1 ? 1 : settings.longBreakEvery;
    final inCycle = state.focusCompletedInCycle;
    return (inCycle % interval) + 1;
  }
}
