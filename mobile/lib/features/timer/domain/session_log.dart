import 'pomodoro_phase.dart';

class SessionLog {
  const SessionLog({
    required this.id,
    required this.phase,
    required this.durationSec,
    required this.completedAt,
    this.taskId,
  });

  final String id;
  final PomodoroPhase phase;
  final int durationSec;
  final DateTime completedAt;
  final String? taskId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'phase': phase.name,
        'durationSec': durationSec,
        'completedAt': completedAt.toIso8601String(),
        if (taskId != null) 'taskId': taskId,
      };

  factory SessionLog.fromJson(Map<String, dynamic> json) {
    return SessionLog(
      id: json['id'] as String,
      phase: PomodoroPhaseX.fromStorage(json['phase'] as String?),
      durationSec: (json['durationSec'] as num).toInt(),
      completedAt: DateTime.parse(json['completedAt'] as String),
      taskId: json['taskId'] as String?,
    );
  }
}

String todayKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

List<String> last7DayKeys([DateTime? now]) {
  final base = now ?? DateTime.now();
  return List.generate(7, (i) {
    final d = base.subtract(Duration(days: 6 - i));
    return todayKey(d);
  });
}
