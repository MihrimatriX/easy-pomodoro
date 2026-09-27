enum TimerStatus { idle, running, paused }

extension TimerStatusX on TimerStatus {
  String get storageValue => name;

  static TimerStatus fromStorage(String? v) {
    return TimerStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => TimerStatus.idle,
    );
  }
}