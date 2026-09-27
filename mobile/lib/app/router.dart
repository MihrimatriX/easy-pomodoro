import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_surface_style.dart';
import '../core/theme/app_theme.dart';
import '../features/habits/presentation/habits_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/timer/presentation/timer_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: const String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/timer'),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ScaffoldWithNav(shell: navigationShell);
        },
        branches: [
          // Order matches floating island: Timer | Aliskanliklar | Gecmis | Gorevler | Ayarlar
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/timer',
              builder: (context, state) => const TimerScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/habits',
              builder: (context, state) => const HabitsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}

class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.shell});
  final StatefulNavigationShell shell;

  static const _barH = AppTheme.floatingNavHeight;
  static const _fab = AppTheme.floatingFabSize;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final safe = mq.padding.bottom;
    final bottomPad = math.max(safe, 8.0) + 8.0;
    final islandBlock = math.max(_barH, _fab) + bottomPad + 8;

    final body = MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(bottom: islandBlock),
      ),
      child: shell,
    );

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          body,
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomPad,
            child: _FloatingIslandNav(
              index: shell.currentIndex,
              onSelect: shell.goBranch,
              onAdd: () => shell.goBranch(3), // Gorevler / quick add
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIslandNav extends StatelessWidget {
  const _FloatingIslandNav({
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final void Function(int) onSelect;
  final VoidCallback onAdd;

  // Short selected labels — must fit inside equal-width slots.
  static const _items = <({IconData icon, IconData selected, String label})>[
    (icon: Icons.timer_outlined, selected: Icons.timer_rounded, label: 'Timer'),
    (
      icon: Icons.spa_outlined,
      selected: Icons.spa_rounded,
      label: 'Al\u0131\u015fk.'
    ),
    (
      icon: Icons.history_outlined,
      selected: Icons.history_rounded,
      label: 'Ge\u00e7mi\u015f'
    ),
    (
      icon: Icons.checklist_outlined,
      selected: Icons.checklist_rounded,
      label: 'G\u00f6rev'
    ),
    (
      icon: Icons.settings_outlined,
      selected: Icons.settings_rounded,
      label: 'Ayar'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final surf = context.surfaceStyle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadows = surf.islandShadows(c);

    // Neo: cream-on-cream + dual shadows (no Material float, no blur).
    // Skeuo: vertical gradient + rim. Glass: frost blur + hairline.
    final Color? barFill;
    final Gradient? barGradient;
    final Border? barBorder;
    if (surf.isNeo) {
      barFill = c.bg;
      barGradient = null;
      barBorder = null;
    } else if (surf.isSkeuo) {
      barFill = null;
      barGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [c.surfaceMuted, c.surface]
            : [
                Color.lerp(c.bgElevated, Colors.white, 0.45)!,
                c.surface,
              ],
      );
      barBorder = Border.all(
        color: isDark ? const Color(0x40FFFFFF) : const Color(0x99FFFFFF),
        width: 0.5,
      );
    } else {
      final allowBlur = AppSurfaceStyle.glassBlurEnabled(context);
      barFill = surf.islandFill(c, opaqueFallback: !allowBlur) ??
          c.bgElevated.withValues(alpha: isDark ? 0.88 : 0.90);
      barGradient = null;
      barBorder = Border.all(
        color: surf.islandBorderColor(c) ??
            (isDark
                ? const Color(0x1FFFF8F3)
                : const Color(0x9EFFFFFF)),
        width: 1,
      );
    }

    const barPadV = 8.0;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < _items.length; i++)
          Expanded(
            child: _NavChip(
              selected: index == i,
              icon: index == i ? _items[i].selected : _items[i].icon,
              label: _items[i].label,
              chipHeight: AppTheme.floatingNavHeight - (barPadV * 2),
              onTap: () => onSelect(i),
            ),
          ),
      ],
    );

    Widget inner = Container(
      height: AppTheme.floatingNavHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: barPadV),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: barFill,
        gradient: barGradient,
        borderRadius: BorderRadius.circular(999),
        border: barBorder,
      ),
      child: row,
    );

    if (surf.isGlass && AppSurfaceStyle.glassBlurEnabled(context)) {
      final blurSigma = surf.glassNavSigma;
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: inner,
        ),
      );
    } else {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: inner,
      );
    }

    final capsule = Container(
      height: AppTheme.floatingNavHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: shadows,
      ),
      child: inner,
    );

    // FAB uses CTA language (skeuo gradient + accent shadow when applicable).
    final fabDeco = surf.ctaDecoration(
      c,
      radius: AppTheme.floatingFabSize / 2,
    );
    final fab = Container(
      width: AppTheme.floatingFabSize,
      height: AppTheme.floatingFabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: fabDeco.gradient,
        color: fabDeco.gradient == null ? (fabDeco.color ?? c.accent) : null,
        boxShadow: fabDeco.boxShadow,
        border: fabDeco.border,
      ),
      child: ClipOval(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onAdd,
            customBorder: const CircleBorder(),
            splashColor: c.onAccent.withValues(alpha: 0.20),
            highlightColor: c.onAccent.withValues(alpha: 0.08),
            child: SizedBox(
              width: AppTheme.floatingFabSize,
              height: AppTheme.floatingFabSize,
              child: Icon(Icons.add_rounded, color: c.onAccent, size: 28),
            ),
          ),
        ),
      ),
    );

    return SizedBox(
      height: math.max(AppTheme.floatingNavHeight, AppTheme.floatingFabSize),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: capsule),
          const SizedBox(width: AppTheme.floatingNavGap),
          fab,
        ],
      ),
    );
  }
}

/// Equal-width nav slot. Selected and unselected keep the SAME width —
/// never AnimatedSize / never grow siblings.
class _NavChip extends StatelessWidget {
  const _NavChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.chipHeight,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final double chipHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: chipHeight,
            width: double.infinity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected ? c.accentMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              // Content is centered inside the FIXED slot; label fades in
              // without changing slot width.
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      ...previous,
                      ?current,
                    ],
                  );
                },
                child: selected
                    ? FittedBox(
                        key: const ValueKey('sel'),
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 20, color: c.accent),
                            const SizedBox(width: 3),
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.fade,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: c.accent,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Icon(
                        key: const ValueKey('unsel'),
                        icon,
                        size: 20,
                        color: c.textTertiary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}