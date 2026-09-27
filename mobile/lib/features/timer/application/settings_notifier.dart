import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/app_storage.dart';
import '../../../core/theme/app_palette.dart';
import '../domain/pomodoro_settings.dart';

final appStorageProvider = Provider<AppStorage>((ref) {
  throw UnimplementedError('AppStorage must be overridden in bootstrap');
});

final settingsProvider =
    NotifierProvider<SettingsNotifier, PomodoroSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<PomodoroSettings> {
  @override
  PomodoroSettings build() {
    return ref.read(appStorageProvider).loadSettings();
  }

  Future<void> update(PomodoroSettings next) async {
    state = next;
    await ref.read(appStorageProvider).saveSettings(next);
  }

  Future<void> setFocusMin(int v) =>
      update(state.copyWith(focusMin: v.clamp(1, 120)));
  Future<void> setShortBreakMin(int v) =>
      update(state.copyWith(shortBreakMin: v.clamp(1, 60)));
  Future<void> setLongBreakMin(int v) =>
      update(state.copyWith(longBreakMin: v.clamp(1, 60)));
  Future<void> setLongBreakEvery(int v) =>
      update(state.copyWith(longBreakEvery: v.clamp(1, 12)));
  Future<void> setAutoStart(bool v) => update(state.copyWith(autoStart: v));
  Future<void> setSound(bool v) => update(state.copyWith(sound: v));
  Future<void> setNotifications(bool v) =>
      update(state.copyWith(notifications: v));
  Future<void> setThemeMode(AppThemeMode v) =>
      update(state.copyWith(themeMode: v));
  Future<void> setWakelock(bool v) => update(state.copyWith(wakelock: v));
  Future<void> setUiStyle(UiSurfaceStyle v) =>
      update(state.copyWith(uiStyle: v));
  Future<void> setPaletteId(ColorPaletteId v) =>
      update(state.copyWith(paletteId: v));
}
