import '../../features/habits/domain/habit.dart';
import '../../features/tasks/domain/task.dart';
import '../../features/timer/domain/pomodoro_phase.dart';
import '../../features/timer/domain/session_log.dart';
import 'app_storage.dart';

/// One-shot demo content so linking + styles are visible on first launch / screenshots.
Future<void> seedDemoIfEmpty(AppStorage storage) async {
  final tasks = storage.loadTasks();
  final habits = storage.loadHabits();
  final sessions = storage.loadSessions();
  if (tasks.isNotEmpty || habits.isNotEmpty || sessions.isNotEmpty) return;

  final now = DateTime.now();
  final today = todayKey(now);

  final habitFocus = Habit(
    id: 'habit-demo-1',
    title: 'Derin çalışma',
    emoji: '🎯',
    completions: [today],
    createdAt: now.subtract(const Duration(days: 3)),
    targetPerWeek: 5,
  );
  final habitWater = Habit(
    id: 'habit-demo-2',
    title: 'Su iç',
    emoji: '💧',
    completions: const [],
    createdAt: now.subtract(const Duration(days: 2)),
    targetPerWeek: 7,
  );
  await storage.saveHabits([habitFocus, habitWater]);

  final taskA = Task(
    id: 'task-demo-1',
    title: 'Pomodoro entegrasyonu',
    completed: false,
    createdAt: now.subtract(const Duration(hours: 2)),
    estimatedPomodoros: 4,
    linkedHabitId: habitFocus.id,
  );
  final taskB = Task(
    id: 'task-demo-2',
    title: 'UI stil paketleri',
    completed: false,
    createdAt: now.subtract(const Duration(hours: 1)),
    estimatedPomodoros: 3,
  );
  await storage.saveTasks([taskA, taskB]);
  await storage.saveActiveTaskId(taskA.id);

  final logs = <SessionLog>[
    SessionLog(
      id: 'sess-1',
      phase: PomodoroPhase.focus,
      durationSec: 25 * 60,
      completedAt: now.subtract(const Duration(hours: 3)),
      taskId: taskA.id,
    ),
    SessionLog(
      id: 'sess-2',
      phase: PomodoroPhase.focus,
      durationSec: 25 * 60,
      completedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      taskId: taskA.id,
    ),
    SessionLog(
      id: 'sess-3',
      phase: PomodoroPhase.focus,
      durationSec: 25 * 60,
      completedAt: now.subtract(const Duration(days: 1, hours: 2)),
      taskId: taskB.id,
    ),
  ];
  await storage.saveSessions(logs);
}
