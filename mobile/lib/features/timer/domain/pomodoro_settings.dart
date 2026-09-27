import '../../../core/theme/app_palette.dart';
import 'pomodoro_phase.dart';

enum AppThemeMode { system, light, dark }

/// Surface language ? independent of [ColorPaletteId].
enum UiSurfaceStyle { neo, skeuo, glass }

class PomodoroSettings {
  const PomodoroSettings({
    this.focusMin = 25,
    this.shortBreakMin = 5,
    this.longBreakMin = 15,
    this.longBreakEvery = 4,
    this.autoStart = true,
    this.sound = true,
    this.notifications = true,
    this.themeMode = AppThemeMode.system,
    this.wakelock = true,
    this.uiStyle = UiSurfaceStyle.neo,
    this.paletteId = ColorPaletteId.tomato,
  });

  final int focusMin;
  final int shortBreakMin;
  final int longBreakMin;
  final int longBreakEvery;
  final bool autoStart;
  final bool sound;
  final bool notifications;
  final AppThemeMode themeMode;
  final bool wakelock;
  final UiSurfaceStyle uiStyle;
  final ColorPaletteId paletteId;

  static const defaults = PomodoroSettings();

  int durationSecFor(PomodoroPhase phase) {
    final min = switch (phase) {
      PomodoroPhase.focus => focusMin,
      PomodoroPhase.shortBreak => shortBreakMin,
      PomodoroPhase.longBreak => longBreakMin,
    };
    return min * 60;
  }

  PomodoroSettings copyWith({
    int? focusMin,
    int? shortBreakMin,
    int? longBreakMin,
    int? longBreakEvery,
    bool? autoStart,
    bool? sound,
    bool? notifications,
    AppThemeMode? themeMode,
    bool? wakelock,
    UiSurfaceStyle? uiStyle,
    ColorPaletteId? paletteId,
  }) {
    return PomodoroSettings(
      focusMin: focusMin ?? this.focusMin,
      shortBreakMin: shortBreakMin ?? this.shortBreakMin,
      longBreakMin: longBreakMin ?? this.longBreakMin,
      longBreakEvery: longBreakEvery ?? this.longBreakEvery,
      autoStart: autoStart ?? this.autoStart,
      sound: sound ?? this.sound,
      notifications: notifications ?? this.notifications,
      themeMode: themeMode ?? this.themeMode,
      wakelock: wakelock ?? this.wakelock,
      uiStyle: uiStyle ?? this.uiStyle,
      paletteId: paletteId ?? this.paletteId,
    );
  }

  Map<String, dynamic> toJson() => {
        'focusMin': focusMin,
        'shortBreakMin': shortBreakMin,
        'longBreakMin': longBreakMin,
        'longBreakEvery': longBreakEvery,
        'autoStart': autoStart,
        'sound': sound,
        'notifications': notifications,
        'themeMode': themeMode.name,
        'wakelock': wakelock,
        'uiStyle': uiStyle.name,
        'paletteId': paletteId.name,
      };

  factory PomodoroSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return PomodoroSettings(
      focusMin: (json['focusMin'] as num?)?.toInt() ?? 25,
      shortBreakMin: (json['shortBreakMin'] as num?)?.toInt() ?? 5,
      longBreakMin: (json['longBreakMin'] as num?)?.toInt() ?? 15,
      longBreakEvery: (json['longBreakEvery'] as num?)?.toInt() ?? 4,
      autoStart: json['autoStart'] as bool? ?? true,
      sound: json['sound'] as bool? ?? true,
      notifications: json['notifications'] as bool? ?? true,
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      wakelock: json['wakelock'] as bool? ?? true,
      uiStyle: UiSurfaceStyle.values.firstWhere(
        (e) => e.name == json['uiStyle'] || e.name == json['surfaceStyle'],
        orElse: () => UiSurfaceStyle.neo,
      ),
      paletteId: ColorPaletteId.values.firstWhere(
        (e) => e.name == json['paletteId'] || e.name == json['colorTheme'],
        orElse: () => ColorPaletteId.tomato,
      ),
    );
  }
}
