import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/habits/domain/habit.dart';
import '../../features/tasks/domain/task.dart';
import '../../features/timer/domain/pomodoro_settings.dart';
import '../../features/timer/domain/session_log.dart';
import '../../features/timer/domain/timer_session.dart';

class AppStorage {
  AppStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _kSettings = 'easy-pomodoro:settings';
  static const _kTimer = 'easy-pomodoro:timer';
  static const _kSessions = 'easy-pomodoro:sessions';
  static const _kHabits = 'easy-pomodoro:habits';
  static const _kTasks = 'easy-pomodoro:tasks';
  static const _kActiveTask = 'easy-pomodoro:active-task';

  PomodoroSettings loadSettings() {
    final raw = _prefs.getString(_kSettings);
    if (raw == null) return PomodoroSettings.defaults;
    try {
      return PomodoroSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return PomodoroSettings.defaults;
    }
  }

  Future<void> saveSettings(PomodoroSettings settings) async {
    await _prefs.setString(_kSettings, jsonEncode(settings.toJson()));
  }

  TimerSession loadTimer({required int fallbackDuration}) {
    final raw = _prefs.getString(_kTimer);
    if (raw == null) {
      return TimerSession(duration: fallbackDuration);
    }
    try {
      return TimerSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        fallbackDuration: fallbackDuration,
      );
    } catch (_) {
      return TimerSession(duration: fallbackDuration);
    }
  }

  Future<void> saveTimer(TimerSession session) async {
    await _prefs.setString(_kTimer, jsonEncode(session.toJson()));
  }

  List<SessionLog> loadSessions() {
    final raw = _prefs.getString(_kSessions);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SessionLog.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveSessions(List<SessionLog> sessions) async {
    final trimmed = sessions.take(500).toList();
    await _prefs.setString(
      _kSessions,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addSession(SessionLog log) async {
    final all = loadSessions();
    all.insert(0, log);
    await saveSessions(all);
  }

  List<Habit> loadHabits() {
    final raw = _prefs.getString(_kHabits);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHabits(List<Habit> habits) async {
    await _prefs.setString(
      _kHabits,
      jsonEncode(habits.map((e) => e.toJson()).toList()),
    );
  }

  List<Task> loadTasks() {
    final raw = _prefs.getString(_kTasks);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Task.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    await _prefs.setString(
      _kTasks,
      jsonEncode(tasks.map((e) => e.toJson()).toList()),
    );
  }

  String? loadActiveTaskId() => _prefs.getString(_kActiveTask);

  Future<void> saveActiveTaskId(String? id) async {
    if (id == null || id.isEmpty) {
      await _prefs.remove(_kActiveTask);
    } else {
      await _prefs.setString(_kActiveTask, id);
    }
  }
}
