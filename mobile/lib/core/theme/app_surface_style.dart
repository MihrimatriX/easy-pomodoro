import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/timer/domain/pomodoro_settings.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Surface language (neo / skeuo / glass). Accents always come from [AppColors] / palette.
@immutable
class AppSurfaceStyle extends ThemeExtension<AppSurfaceStyle> {
  const AppSurfaceStyle({required this.style});

  final UiSurfaceStyle style;

  static const neo = AppSurfaceStyle(style: UiSurfaceStyle.neo);
  static const skeuo = AppSurfaceStyle(style: UiSurfaceStyle.skeuo);
  static const glass = AppSurfaceStyle(style: UiSurfaceStyle.glass);

  bool get isNeo => style == UiSurfaceStyle.neo;
  bool get isSkeuo => style == UiSurfaceStyle.skeuo;
  bool get isGlass => style == UiSurfaceStyle.glass;

  double get cardRadius => switch (style) {
        UiSurfaceStyle.neo => AppTheme.radiusCard,
        UiSurfaceStyle.skeuo => 15,
        UiSurfaceStyle.glass => 18,
      };

  double get controlRadius => switch (style) {
        UiSurfaceStyle.neo => AppTheme.radiusControl,
        UiSurfaceStyle.skeuo => 14,
        UiSurfaceStyle.glass => 14,
      };

  double get sheetRadius => AppTheme.radiusSheet;

  // --- Glass recipe (designer brief) ---
  static const Color glassFillLight = Color(0xFFFFF9F4);
  static const Color glassFillDark = Color(0xFF2E2A27);
  static const Color glassHairlineLight = Color(0xFFFFFFFF);
  static const Color glassHairlineDark = Color(0xFFFFF8F3);

  /// Card / panel blur sigma (18–22).
  double get glassCardSigma => 20;

  /// Chip / secondary control blur (14–16).
  double get glassChipSigma => 15;

  /// Nav island blur (24–28).
  double get glassNavSigma => 26;

  /// Sheet blur (26–30).
  double get glassSheetSigma => 28;

  /// @deprecated Prefer [glassCardSigma] / role-specific getters.
  double get glassBlurSigma => glassCardSigma;

  /// True when BackdropFilter should run (off for reduce-motion / a11y proxy).
  static bool glassBlurEnabled(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    if (mq == null) return true;
    return !mq.disableAnimations;
  }

  Color _glassHairline(bool isDark) => isDark
      ? glassHairlineDark.withValues(alpha: 0.12)
      : glassHairlineLight.withValues(alpha: 0.62);

  List<BoxShadow> _glassFloat(bool isDark, {bool pressed = false}) => [
        BoxShadow(
          color: isDark ? const Color(0x66000000) : const Color(0x141C1916),
          offset: Offset(0, isDark ? (pressed ? 6 : 10) : (pressed ? 4 : 8)),
          blurRadius: isDark ? (pressed ? 16 : 28) : (pressed ? 14 : 24),
          spreadRadius: -2,
        ),
      ];

  /// Page wash behind scaffolds (glass needs variation so frost reads).
  /// Accent @ 6–10% + soft cream — blobs painted by [GlassPageWash].
  BoxDecoration? pageDecoration(AppColors c) {
    if (style != UiSurfaceStyle.glass) return null;
    final isDark = c.bg.computeLuminance() < 0.5;
    if (isDark) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF141A28), c.accent, 0.08)!,
            Color.lerp(c.bg, c.accent, 0.06)!,
            Color.lerp(const Color(0xFF0C1019), c.accent, 0.04)!,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(const Color(0xFFF5F0EA), c.accent, 0.07)!,
          Color.lerp(c.bg, c.accent, 0.08)!,
          Color.lerp(const Color(0xFFEDE7E0), c.accent, 0.10)!,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  /// Soften dual neo shadows (pressed / secondary).
  List<BoxShadow> _halveNeo(List<BoxShadow> src) => [
        for (final s in src)
          BoxShadow(
            color: s.color.withValues(alpha: (s.color.a * 0.55).clamp(0.0, 1.0)),
            offset: Offset(s.offset.dx * 0.5, s.offset.dy * 0.5),
            blurRadius: s.blurRadius * 0.55,
            spreadRadius: s.spreadRadius * 0.5,
          ),
      ];

  /// Card / panel decoration.
  /// Neo: fill ≈ bg + dual soft shadows (SE dark + NW light).
  /// Skeuo: vertical gradient + contact + ambient + 0.5px rim.
  /// Glass: frost fill + hairline + soft float (blur via [blurPanel] / GlassBlurPanel).
  /// [pressed]: neo inset-ish (muted fill + halved shadows).
  /// [opaqueFallback]: reduce-transparency — solid fill, no frost alpha.
  BoxDecoration cardDecoration(
    AppColors c, {
    double? radius,
    bool blurPanel = false,
    bool pressed = false,
    bool opaqueFallback = false,
  }) {
    final r = radius ?? cardRadius;
    switch (style) {
      case UiSurfaceStyle.neo:
        // Cream-on-cream extrusion; pressed = muted + softer dual shadows.
        return BoxDecoration(
          color: pressed ? c.surfaceMuted : c.bg,
          borderRadius: BorderRadius.circular(r),
          boxShadow: pressed ? _halveNeo(c.neoShadows) : c.neoShadows,
        );
      case UiSurfaceStyle.skeuo:
        final isDark = c.bg.computeLuminance() < 0.5;
        final shadows = [
          // Contact — deeper than neo dual, vertical-only
          BoxShadow(
            color: isDark
                ? const Color(0xB3000000)
                : const Color(0x4D1C1916),
            offset: Offset(0, pressed ? 4 : 9),
            blurRadius: pressed ? 8 : 18,
            spreadRadius: -1,
          ),
          // Ambient
          BoxShadow(
            color: isDark
                ? const Color(0x55000000)
                : const Color(0x241C1916),
            offset: Offset(0, pressed ? 1 : 3),
            blurRadius: pressed ? 3 : 6,
          ),
        ];
        return BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    Color.lerp(c.surfaceMuted, Colors.white, pressed ? 0.10 : 0.16)!,
                    pressed ? c.surfaceMuted : c.surface,
                    Color.lerp(c.bgElevated, Colors.black, pressed ? 0.28 : 0.24)!,
                  ]
                : [
                    Color.lerp(c.bgElevated, Colors.white, pressed ? 0.62 : 0.78)!,
                    pressed ? c.surface : Color.lerp(c.bgElevated, c.surface, 0.35)!,
                    Color.lerp(c.surface, const Color(0xFF1C1916), pressed ? 0.14 : 0.10)!,
                  ],
            stops: const [0.0, 0.42, 1.0],
          ),
          border: Border.all(
            color: isDark
                ? const Color(0x55FFFFFF)
                : const Color(0xCCFFFFFF),
            width: 0.8,
          ),
          boxShadow: shadows,
        );
      case UiSurfaceStyle.glass:
        final isDark = c.bg.computeLuminance() < 0.5;
        if (opaqueFallback) {
          return BoxDecoration(
            color: isDark ? glassFillDark : glassFillLight,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: _glassHairline(isDark), width: 1),
            boxShadow: _glassFloat(isDark, pressed: pressed),
          );
        }
        // Frost panels: ~60% light / ~50% dark. Tint-only rows: ~55%/45% (never 80%+ milk).
        var alpha = blurPanel
            ? (isDark ? 0.48 : 0.55)
            : (isDark ? 0.38 : 0.42);
        if (pressed) alpha = (alpha + 0.06).clamp(0.0, 0.72);
        final fill = isDark
            ? glassFillDark.withValues(alpha: alpha)
            : glassFillLight.withValues(alpha: alpha);
        return BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: _glassHairline(isDark), width: 1),
          boxShadow: _glassFloat(isDark, pressed: pressed),
        );
    }
  }

  /// Bottom sheet / dialog panel — glass: bgElevated @ ~80%, σ via sheet getter.
  BoxDecoration sheetDecoration(
    AppColors c, {
    bool blurPanel = true,
    bool opaqueFallback = false,
  }) {
    if (style != UiSurfaceStyle.glass) {
      return cardDecoration(
        c,
        radius: sheetRadius,
        blurPanel: blurPanel,
        opaqueFallback: opaqueFallback,
      );
    }
    final isDark = c.bg.computeLuminance() < 0.5;
    final r = sheetRadius;
    if (opaqueFallback) {
      return BoxDecoration(
        color: c.bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
        border: Border(
          top: BorderSide(color: _glassHairline(isDark), width: 1),
        ),
        boxShadow: _glassFloat(isDark),
      );
    }
    return BoxDecoration(
      color: c.bgElevated.withValues(alpha: 0.80),
      borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
      border: Border(
        top: BorderSide(color: _glassHairline(isDark), width: 1),
      ),
      boxShadow: _glassFloat(isDark),
    );
  }

  /// Secondary control (Skip / Reset) — raised soft surface, not flat outline.
  /// Glass: bg @ 50% + hairline (blur via caller / GlassBlurPanel σ14).
  BoxDecoration secondaryDecoration(
    AppColors c, {
    double? radius,
    bool pressed = false,
    bool opaqueFallback = false,
  }) {
    final r = radius ?? controlRadius;
    switch (style) {
      case UiSurfaceStyle.neo:
        return BoxDecoration(
          color: pressed ? c.surfaceMuted : c.bg,
          borderRadius: BorderRadius.circular(r),
          boxShadow: pressed
              ? _halveNeo(c.neoShadows)
              : c.neoShadows,
        );
      case UiSurfaceStyle.skeuo:
        return cardDecoration(c, radius: r, pressed: pressed);
      case UiSurfaceStyle.glass:
        final isDark = c.bg.computeLuminance() < 0.5;
        if (opaqueFallback) {
          return BoxDecoration(
            color: isDark ? glassFillDark : glassFillLight,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: _glassHairline(isDark), width: 1),
          );
        }
        final alpha = pressed ? 0.58 : 0.50;
        return BoxDecoration(
          color: isDark
              ? c.bg.withValues(alpha: alpha)
              : glassFillLight.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: _glassHairline(isDark), width: 1),
        );
    }
  }

  /// Small chip / pill (Seç, emoji picker, filter chips).
  /// Glass unselected: accentMuted or frost @50% + hairline; selected = solid accent.
  BoxDecoration chipDecoration(
    AppColors c, {
    double? radius,
    bool selected = false,
    bool pressed = false,
    bool opaqueFallback = false,
  }) {
    final r = radius ?? AppTheme.radiusPill;
    if (selected) {
      return BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.32),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      );
    }
    switch (style) {
      case UiSurfaceStyle.neo:
        return BoxDecoration(
          color: pressed ? c.surfaceMuted : c.bg,
          borderRadius: BorderRadius.circular(r),
          boxShadow: _halveNeo(c.neoShadows),
        );
      case UiSurfaceStyle.skeuo:
        return cardDecoration(c, radius: r, pressed: pressed);
      case UiSurfaceStyle.glass:
        final isDark = c.bg.computeLuminance() < 0.5;
        if (opaqueFallback) {
          return BoxDecoration(
            color: c.accentMuted,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: _glassHairline(isDark), width: 1),
          );
        }
        final alpha = pressed ? 0.58 : 0.50;
        return BoxDecoration(
          color: Color.lerp(
            isDark ? c.bg : glassFillLight,
            c.accentMuted,
            0.35,
          )!.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(color: _glassHairline(isDark), width: 1),
        );
    }
  }

  /// Floating island bar shadows — neo dual only; skeuo/glass float.
  List<BoxShadow> islandShadows(AppColors c) {
    final isDark = c.bg.computeLuminance() < 0.5;
    switch (style) {
      case UiSurfaceStyle.neo:
        return c.neoShadows;
      case UiSurfaceStyle.skeuo:
        return [
          BoxShadow(
            color: isDark ? const Color(0x99000000) : const Color(0x3D1C1916),
            offset: const Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: isDark ? const Color(0x44000000) : const Color(0x1A1C1916),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ];
      case UiSurfaceStyle.glass:
        return _glassFloat(isDark);
    }
  }

  /// Nav island fill — glass: bgElevated @ 85–92%.
  Color? islandFill(AppColors c, {bool opaqueFallback = false}) {
    if (style != UiSurfaceStyle.glass) return null;
    if (opaqueFallback) return c.bgElevated;
    final isDark = c.bg.computeLuminance() < 0.5;
    return c.bgElevated.withValues(alpha: isDark ? 0.88 : 0.90);
  }

  Color? islandBorderColor(AppColors c) {
    if (style != UiSurfaceStyle.glass) return null;
    return _glassHairline(c.bg.computeLuminance() < 0.5);
  }

  /// Primary CTA — solid fill for neo/glass; highlight→base→pressed for skeuo.
  /// Glass CTA stays solid accent (frost CTA is unreadable).
  BoxDecoration ctaDecoration(AppColors c, {Color? color, double? radius}) {
    final r = radius ?? controlRadius;
    final base = color ?? c.accent;
    final isDark = c.bg.computeLuminance() < 0.5;
    final isAccent = base == c.accent;
    if (style == UiSurfaceStyle.skeuo) {
      final highlight = Color.lerp(base, Colors.white, isDark ? 0.30 : 0.26)!;
      final pressed = isAccent
          ? c.accentPressed
          : (base == c.breakColor
              ? c.breakPressed
              : Color.lerp(base, Colors.black, 0.12)!);
      return BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [highlight, base, pressed],
          stops: const [0.0, 0.48, 1.0],
        ),
        border: Border.all(
          color: Color.lerp(base, Colors.white, 0.35)!.withValues(alpha: 0.55),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: 0.42),
            offset: const Offset(0, 6),
            blurRadius: 12,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: base.withValues(alpha: 0.18),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );
    }
    // Neo / glass: solid accent + soft float (accent @ 40%, (0,6), blur 12).
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(r),
      boxShadow: [
        BoxShadow(
          color: base.withValues(alpha: 0.40),
          offset: const Offset(0, 6),
          blurRadius: 12,
        ),
      ],
    );
  }

  /// Recessed well (progress ring track / unchecked circle) — neo inset shadows.
  BoxDecoration insetDecoration(AppColors c, {double? radius}) {
    final r = radius ?? controlRadius;
    final isDark = c.bg.computeLuminance() < 0.5;
    if (style == UiSurfaceStyle.neo) {
      return BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(r),
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0x8C000000),
                  offset: Offset(2, 2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Color(0x663A342E),
                  offset: Offset(-2, -2),
                  blurRadius: 5,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x331C1916),
                  offset: Offset(2, 2),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Color(0xE6FFFFFF),
                  offset: Offset(-2, -2),
                  blurRadius: 5,
                ),
              ],
      );
    }
    // skeuo / glass: soft muted well, no dual inset
    return BoxDecoration(
      color: c.surfaceMuted,
      borderRadius: BorderRadius.circular(r),
      border: style == UiSurfaceStyle.glass
          ? Border.all(color: _glassHairline(isDark), width: 1)
          : null,
    );
  }

  /// Soft well behind the timer ring — neo dual-inset; skeuo gradient.
  /// Glass: null (flat bg + page wash only — no frost card on the ring stage).
  BoxDecoration? ringWellDecoration(AppColors c, {double size = 300}) {
    final isDark = c.bg.computeLuminance() < 0.5;
    if (style == UiSurfaceStyle.neo) {
      return BoxDecoration(
        color: c.bg,
        shape: BoxShape.circle,
        boxShadow: isDark
            ? const [
                BoxShadow(
                  color: Color(0x8C000000),
                  offset: Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Color(0x663A342E),
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x2E1C1916),
                  offset: Offset(4, 4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Color(0xE6FFFFFF),
                  offset: Offset(-3, -3),
                  blurRadius: 8,
                ),
              ],
      );
    }
    if (style == UiSurfaceStyle.skeuo) {
      return BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Color.lerp(c.surfaceMuted, Colors.white, 0.06)!,
                  Color.lerp(c.bgElevated, Colors.black, 0.14)!,
                ]
              : [
                  Color.lerp(c.bgElevated, Colors.white, 0.45)!,
                  Color.lerp(c.surface, const Color(0xFF1C1916), 0.05)!,
                ],
        ),
        border: Border.all(
          color: isDark ? const Color(0x40FFFFFF) : const Color(0x99FFFFFF),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x66000000) : const Color(0x241C1916),
            offset: const Offset(0, 6),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      );
    }
    // glass: flat — page wash shows through; no frost disk over the ring.
    return null;
  }

  @override
  AppSurfaceStyle copyWith({UiSurfaceStyle? style}) =>
      AppSurfaceStyle(style: style ?? this.style);

  @override
  AppSurfaceStyle lerp(ThemeExtension<AppSurfaceStyle>? other, double t) {
    if (other is! AppSurfaceStyle) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppSurfaceStyleX on BuildContext {
  AppSurfaceStyle get surfaceStyle =>
      Theme.of(this).extension<AppSurfaceStyle>() ?? AppSurfaceStyle.neo;
}

/// Soft accent corner blobs so BackdropFilter has visible content to frost.
class GlassPageWash extends StatelessWidget {
  const GlassPageWash({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surf = context.surfaceStyle;
    final c = context.colors;
    final page = surf.pageDecoration(c);
    if (page == null) return child;

    final isDark = c.bg.computeLuminance() < 0.5;
    final blobA = c.accent.withValues(alpha: isDark ? 0.22 : 0.16);
    final blobB = c.accent.withValues(alpha: isDark ? 0.16 : 0.12);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: page),
        Positioned(
          top: -80,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [blobA, blobA.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -90,
          child: IgnorePointer(
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [blobB, blobB.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 280,
          left: 40,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.breakColor.withValues(alpha: isDark ? 0.14 : 0.10),
                    c.breakColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Wraps child with BackdropFilter when glass + [enableBlur].
class GlassBlurPanel extends StatelessWidget {
  const GlassBlurPanel({
    super.key,
    required this.child,
    this.enableBlur = true,
    this.borderRadius,
    this.padding,
    this.sigma,
  });

  final Widget child;
  final bool enableBlur;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  /// Defaults to [AppSurfaceStyle.glassCardSigma].
  final double? sigma;

  @override
  Widget build(BuildContext context) {
    final surf = context.surfaceStyle;
    final c = context.colors;
    final r = borderRadius ?? surf.cardRadius;
    final allowBlur = enableBlur && AppSurfaceStyle.glassBlurEnabled(context);
    final deco = surf.cardDecoration(
      c,
      radius: r,
      blurPanel: true,
      opaqueFallback: surf.isGlass && !allowBlur,
    );
    final shadows = deco.boxShadow;
    final fillDeco = deco.copyWith(boxShadow: const <BoxShadow>[]);

    Widget body = Container(
      padding: padding,
      decoration: fillDeco,
      child: child,
    );

    if (surf.isGlass && allowBlur) {
      final s = sigma ?? surf.glassCardSigma;
      body = ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: s, sigmaY: s),
          child: body,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: shadows,
      ),
      child: body,
    );
  }
}
