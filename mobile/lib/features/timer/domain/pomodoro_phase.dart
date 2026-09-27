enum PomodoroPhase { focus, shortBreak, longBreak }

extension PomodoroPhaseX on PomodoroPhase {
  String get labelTr => switch (this) {
        PomodoroPhase.focus => 'ODAK',
        PomodoroPhase.shortBreak => 'KISA MOLA',
        PomodoroPhase.longBreak => 'UZUN MOLA',
      };

  String get microcopyTr => switch (this) {
        PomodoroPhase.focus => 'Molaya kalan',
        PomodoroPhase.shortBreak => 'Odaka dönüş',
        PomodoroPhase.longBreak => 'Odaka dönüş',
      };

  bool get isBreak => this != PomodoroPhase.focus;

  String get storageValue => name;

  static PomodoroPhase fromStorage(String? v) {
    return PomodoroPhase.values.firstWhere(
      (e) => e.name == v,
      orElse: () => PomodoroPhase.focus,
    );
  }
}