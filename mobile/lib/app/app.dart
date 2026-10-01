import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_surface_style.dart';
import '../core/theme/app_theme.dart';
import '../features/timer/application/pomodoro_notifier.dart';
import '../features/timer/application/settings_notifier.dart';
import '../features/timer/domain/pomodoro_settings.dart';

class EasyPomodoroApp extends ConsumerStatefulWidget {
  const EasyPomodoroApp({super.key, required this.router});

  final GoRouter router;

  @override
  ConsumerState<EasyPomodoroApp> createState() => _EasyPomodoroAppState();
}

class _EasyPomodoroAppState extends ConsumerState<EasyPomodoroApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final n = ref.read(pomodoroProvider.notifier);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        n.onAppPaused();
      case AppLifecycleState.resumed:
        n.onAppResumed();
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final mode = switch (settings.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
    final ui = settings.uiStyle;
    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    return MaterialApp.router(
      title: 'Easy Productivity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(uiStyle: ui, palette: settings.paletteId),
      darkTheme: AppTheme.dark(uiStyle: ui, palette: settings.paletteId),
      themeMode: mode,
      // Style / palette / brightness changes morph: AppSurfaceStyle and
      // AppColors lerp continuously, so give the morph room to be seen.
      themeAnimationStyle: reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 420),
              curve: Curves.easeInOutCubic,
            ),
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        // Same tree for every style — the backdrop fades its glass wash in
        // and out instead of being inserted (which would remount the app).
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlayFor(brightness),
          child: AppBackdrop(child: child ?? const SizedBox.shrink()),
        );
      },
      routerConfig: widget.router,
    );
  }
}
