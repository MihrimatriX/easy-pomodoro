import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_phase.dart';
import '../domain/session_log.dart';
import 'settings_notifier.dart';

final historyProvider =
    NotifierProvider<HistoryNotifier, List<SessionLog>>(HistoryNotifier.new);

class HistoryNotifier extends Notifier<List<SessionLog>> {
  @override
  List<SessionLog> build() {
    return ref.read(appStorageProvider).loadSessions();
  }

  Future<void> addSession({
    required PomodoroPhase phase,
    required int durationSec,
    String? taskId,
  }) async {
    final log = SessionLog(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      phase: phase,
      durationSec: durationSec,
      completedAt: DateTime.now(),
      taskId: taskId,
    );
    await ref.read(appStorageProvider).addSession(log);
    state = ref.read(appStorageProvider).loadSessions();
  }

  /// Backward-compatible focus helper used by the timer engine.
  Future<void> addFocusSession({
    required int durationSec,
    String? taskId,
  }) =>
      addSession(
        phase: PomodoroPhase.focus,
        durationSec: durationSec,
        taskId: taskId,
      );

  void reload() {
    state = ref.read(appStorageProvider).loadSessions();
  }

  Iterable<SessionLog> _todayFocus() {
    final key = todayKey();
    return state.where(
      (s) => s.phase == PomodoroPhase.focus && todayKey(s.completedAt) == key,
    );
  }

  int todayFocusCount() => _todayFocus().length;

  int todayFocusMinutes() {
    final sec = _todayFocus().fold<int>(0, (a, s) => a + s.durationSec);
    return (sec / 60).round();
  }

  int focusCountForTask(String taskId) {
    return state
        .where(
          (s) => s.phase == PomodoroPhase.focus && s.taskId == taskId,
        )
        .length;
  }

  Map<String, int> last7FocusCounts() {
    final keys = last7DayKeys();
    final map = {for (final k in keys) k: 0};
    for (final s in state) {
      if (s.phase != PomodoroPhase.focus) continue;
      final k = todayKey(s.completedAt);
      if (map.containsKey(k)) map[k] = map[k]! + 1;
    }
    return map;
  }

  Map<String, int> last7FocusMinutes() {
    final keys = last7DayKeys();
    final map = {for (final k in keys) k: 0};
    for (final s in state) {
      if (s.phase != PomodoroPhase.focus) continue;
      final k = todayKey(s.completedAt);
      if (map.containsKey(k)) {
        map[k] = map[k]! + (s.durationSec / 60).round();
      }
    }
    return map;
  }
}
