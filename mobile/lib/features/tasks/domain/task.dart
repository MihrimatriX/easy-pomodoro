class Task {
  const Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    this.estimatedPomodoros = 0,
    this.linkedHabitId,
  });

  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;

  /// Target focus sessions for this task (0 = unset, max 20).
  final int estimatedPomodoros;

  /// Optional habit auto-checked when a focus session completes for this task.
  final String? linkedHabitId;

  int get estimatedClamped => estimatedPomodoros.clamp(0, 20);

  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? createdAt,
    int? estimatedPomodoros,
    String? linkedHabitId,
    bool clearLinkedHabitId = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      estimatedPomodoros: estimatedPomodoros ?? this.estimatedPomodoros,
      linkedHabitId: clearLinkedHabitId
          ? null
          : (linkedHabitId ?? this.linkedHabitId),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'estimatedPomodoros': estimatedPomodoros,
        if (linkedHabitId != null) 'linkedHabitId': linkedHabitId,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      estimatedPomodoros: (json['estimatedPomodoros'] as num?)?.toInt() ?? 0,
      linkedHabitId: json['linkedHabitId'] as String?,
    );
  }
}
