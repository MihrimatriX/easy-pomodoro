import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../timer/application/settings_notifier.dart';
import '../domain/task.dart';

final tasksProvider =
    NotifierProvider<TasksNotifier, List<Task>>(TasksNotifier.new);

final activeTaskIdProvider =
    NotifierProvider<ActiveTaskIdNotifier, String?>(ActiveTaskIdNotifier.new);

class TasksNotifier extends Notifier<List<Task>> {
  @override
  List<Task> build() {
    return ref.read(appStorageProvider).loadTasks();
  }

  Future<void> _persist(List<Task> next) async {
    state = next;
    await ref.read(appStorageProvider).saveTasks(next);
  }

  Future<void> add({
    required String title,
    int estimatedPomodoros = 0,
    String? linkedHabitId,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final task = Task(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      title: trimmed,
      completed: false,
      createdAt: DateTime.now(),
      estimatedPomodoros: estimatedPomodoros.clamp(0, 20),
      linkedHabitId: linkedHabitId,
    );
    await _persist([task, ...state]);
  }

  Future<void> updateTask(Task task) async {
    await _persist([
      for (final t in state) t.id == task.id ? task : t,
    ]);
  }

  Future<void> toggle(String id) async {
    await _persist([
      for (final t in state)
        t.id == id ? t.copyWith(completed: !t.completed) : t,
    ]);
  }

  Future<void> delete(String id) async {
    await _persist(state.where((t) => t.id != id).toList());
    final active = ref.read(activeTaskIdProvider);
    if (active == id) {
      await ref.read(activeTaskIdProvider.notifier).set(null);
    }
  }

  Task? byId(String? id) {
    if (id == null) return null;
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }
}

class ActiveTaskIdNotifier extends Notifier<String?> {
  @override
  String? build() {
    final id = ref.read(appStorageProvider).loadActiveTaskId();
    if (id == null) return null;
    final tasks = ref.read(appStorageProvider).loadTasks();
    return tasks.any((t) => t.id == id) ? id : null;
  }

  Future<void> set(String? id) async {
    state = id;
    await ref.read(appStorageProvider).saveActiveTaskId(id);
  }
}
