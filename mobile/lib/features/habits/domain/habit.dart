import '../../timer/domain/session_log.dart';

const habitEmojis = [
  '💧', '📚', '🏃', '🧘', '🥗', '💤', '✍️', '🎯',
  '🎸', '🧠', '🧹', '🌿', '🦷', '💊', '🚶', '🌞',
];

class Habit {
  const Habit({
    required this.id,
    required this.title,
    required this.emoji,
    required this.completions,
    required this.createdAt,
    this.targetPerWeek = 7,
  });

  final String id;
  final String title;
  final String emoji;
  final List<String> completions;
  final DateTime createdAt;
  final int targetPerWeek;

  int get weekTarget => targetPerWeek.clamp(1, 7);

  bool isDoneOn(String dateKey) => completions.contains(dateKey);
  bool get isDoneToday => isDoneOn(todayKey());

  Habit toggleDate(String dateKey) {
    final has = completions.contains(dateKey);
    final next = has
        ? completions.where((d) => d != dateKey).toList()
        : [...completions, dateKey]..sort();
    return copyWith(completions: next);
  }

  int currentStreak([String? today]) {
    final key = today ?? todayKey();
    final set = completions.toSet();
    var cursor = DateTime.parse('${key}T12:00:00');
    if (!set.contains(key)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (true) {
      final k = todayKey(cursor);
      if (!set.contains(k)) break;
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int bestStreak() {
    if (completions.isEmpty) return 0;
    final sorted = [...completions]..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse('${sorted[i - 1]}T12:00:00');
      final curr = DateTime.parse('${sorted[i]}T12:00:00');
      final diff = curr.difference(prev).inDays;
      if (diff == 1) {
        current += 1;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return best;
  }

  int weeklyDone(List<String> weekDays) =>
      weekDays.where(completions.contains).length;

  Habit copyWith({
    String? id,
    String? title,
    String? emoji,
    List<String>? completions,
    DateTime? createdAt,
    int? targetPerWeek,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      completions: completions ?? this.completions,
      createdAt: createdAt ?? this.createdAt,
      targetPerWeek: targetPerWeek ?? this.targetPerWeek,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'completions': completions,
        'createdAt': createdAt.toIso8601String(),
        'targetPerWeek': targetPerWeek,
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      emoji: json['emoji'] as String? ?? '🎯',
      completions: (json['completions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      targetPerWeek: (json['targetPerWeek'] as num?)?.toInt() ?? 7,
    );
  }
}

List<Habit> sortHabitsForToday(List<Habit> habits) {
  final list = [...habits];
  list.sort((a, b) {
    if (a.isDoneToday != b.isDoneToday) return a.isDoneToday ? 1 : -1;
    return b.currentStreak() - a.currentStreak();
  });
  return list;
}