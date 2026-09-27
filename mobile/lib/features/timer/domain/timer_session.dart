import 'pomodoro_phase.dart';
import 'timer_status.dart';

/// Source of truth: startedAt + duration + status + pause remaining.
class TimerSession {
  const TimerSession({
    this.phase = PomodoroPhase.focus,
    this.status = TimerStatus.idle,
    this.startedAt,
    required this.duration,
    this.focusCompletedInCycle = 0,
    this.pausedRemaining,
    this.pomodoroCount = 0,
  });

  final PomodoroPhase phase;
  final TimerStatus status;

  /// Wall-clock start when [status] is running.
  final DateTime? startedAt;

  /// Full phase duration in seconds.
  final int duration;

  /// Focus sessions completed in current cycle (resets after long break).
  final int focusCompletedInCycle;

  /// Total completed focus sessions (never resets) — shared-domain parity.
  final int pomodoroCount;

  /// Remaining seconds stored while paused.
  final int? pausedRemaining;

  bool get isRunning => status == TimerStatus.running;
  bool get isPaused => status == TimerStatus.paused;
  bool get isIdle => status == TimerStatus.idle;

  /// Remaining seconds at [now]. UI ticker only; engine uses this for reconcile.
  int remainingAt(DateTime now) {
    if (status == TimerStatus.paused) {
      return (pausedRemaining ?? duration).clamp(0, duration);
    }
    if (status == TimerStatus.running && startedAt != null) {
      final elapsed = now.difference(startedAt!).inMilliseconds / 1000.0;
      final left = duration - elapsed;
      return left.ceil().clamp(0, duration);
    }
    return duration;
  }

  double progressAt(DateTime now) {
    if (duration <= 0) return 0;
    final rem = remainingAt(now);
    return ((duration - rem) / duration).clamp(0.0, 1.0);
  }

  /// Shared getNextPhase parity: after focus increment; % interval == 0 → long.
  static ({PomodoroPhase phase, int pomodoroCount, int focusCompletedInCycle})
      nextPhase({
    required PomodoroPhase current,
    required int pomodoroCount,
    required int focusCompletedInCycle,
    required int longBreakEvery,
    bool countFocus = true,
  }) {
    if (current != PomodoroPhase.focus) {
      return (
        phase: PomodoroPhase.focus,
        pomodoroCount: pomodoroCount,
        focusCompletedInCycle: focusCompletedInCycle,
      );
    }
    if (!countFocus) {
      return (
        phase: PomodoroPhase.shortBreak,
        pomodoroCount: pomodoroCount,
        focusCompletedInCycle: focusCompletedInCycle,
      );
    }
    final newCount = pomodoroCount + 1;
    final interval = longBreakEvery < 1 ? 1 : longBreakEvery;
    final newCycle = focusCompletedInCycle + 1;
    if (newCount % interval == 0 || newCycle >= interval) {
      return (
        phase: PomodoroPhase.longBreak,
        pomodoroCount: newCount,
        focusCompletedInCycle: 0,
      );
    }
    return (
      phase: PomodoroPhase.shortBreak,
      pomodoroCount: newCount,
      focusCompletedInCycle: newCycle,
    );
  }

  TimerSession copyWith({
    PomodoroPhase? phase,
    TimerStatus? status,
    DateTime? startedAt,
    bool clearStartedAt = false,
    int? duration,
    int? focusCompletedInCycle,
    int? pomodoroCount,
    int? pausedRemaining,
    bool clearPausedRemaining = false,
  }) {
    return TimerSession(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      startedAt: clearStartedAt ? null : (startedAt ?? this.startedAt),
      duration: duration ?? this.duration,
      focusCompletedInCycle:
          focusCompletedInCycle ?? this.focusCompletedInCycle,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      pausedRemaining: clearPausedRemaining
          ? null
          : (pausedRemaining ?? this.pausedRemaining),
    );
  }

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'status': status.name,
        'startedAt': startedAt?.toIso8601String(),
        'duration': duration,
        'focusCompletedInCycle': focusCompletedInCycle,
        'pomodoroCount': pomodoroCount,
        'pausedRemaining': pausedRemaining,
      };

  factory TimerSession.fromJson(Map<String, dynamic>? json, {int fallbackDuration = 25 * 60}) {
    if (json == null) {
      return TimerSession(duration: fallbackDuration);
    }
    return TimerSession(
      phase: PomodoroPhaseX.fromStorage(json['phase'] as String?),
      status: TimerStatusX.fromStorage(json['status'] as String?),
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'] as String)
          : null,
      duration: (json['duration'] as num?)?.toInt() ?? fallbackDuration,
      focusCompletedInCycle:
          (json['focusCompletedInCycle'] as num?)?.toInt() ?? 0,
      pomodoroCount: (json['pomodoroCount'] as num?)?.toInt() ?? 0,
      pausedRemaining: (json['pausedRemaining'] as num?)?.toInt(),
    );
  }
}