import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timer/application/settings_notifier.dart';
import '../../timer/domain/session_log.dart';
import '../domain/habit.dart';

final habitsProvider =
    NotifierProvider<HabitsNotifier, List<Habit>>(HabitsNotifier.new);

class HabitsNotifier extends Notifier<List<Habit>> {
  @override
  List<Habit> build() {
    return ref.read(appStorageProvider).loadHabits();
  }

  Future<void> _persist(List<Habit> next) async {
    state = next;
    await ref.read(appStorageProvider).saveHabits(next);
  }

  Future<void> add({
    required String title,
    required String emoji,
    int targetPerWeek = 7,
  }) async {
    final habit = Habit(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      emoji: emoji,
      completions: const [],
      createdAt: DateTime.now(),
      targetPerWeek: targetPerWeek.clamp(1, 7),
    );
    await _persist([...state, habit]);
  }

  Future<void> updateHabit(Habit habit) async {
    await _persist([
      for (final h in state) h.id == habit.id ? habit : h,
    ]);
  }

  Future<void> delete(String id) async {
    await _persist(state.where((h) => h.id != id).toList());
  }

  Future<void> toggleToday(String id) async {
    final key = todayKey();
    await _persist([
      for (final h in state) h.id == id ? h.toggleDate(key) : h,
    ]);
  }
}