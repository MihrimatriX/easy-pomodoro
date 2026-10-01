import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../features/timer/domain/pomodoro_settings.dart';
import 'app_colors.dart';
import 'app_theme.dart';

/// Surface language (neo / skeuo / glass) expressed as a *blend* of the three
/// styles. Accents always come from [AppColors] / palette.
///
/// A pure style has one weight at 1.0. While [MaterialApp] animates between
/// two themes, [lerp] produces intermediate blends and every decoration below
/// is interpolated with [BoxDecoration.lerp], so switching styles morphs
/// smoothly instead of snapping half-way through the animation.
///
/// Rules that keep the morph glitch-free:
///  * fills are always [LinearGradient]s (a solid colour is a two-stop
///    gradient) — lerping `color` ↔ `gradient` would dip the opacity mid-way;
///  * borders are always uniform (`Border.all`) — required with a radius;
///  * widgets keep the same tree shape for every style (blur is toggled with
///    [BackdropFilter.enabled], never by inserting/removing wrappers).
@immutable
class AppSurfaceStyle extends ThemeExtension<AppSurfaceStyle> {
  const AppSurfaceStyle({required this.style})
    : neoWeight = style == UiSurfaceStyle.neo ? 1.0 : 0.0,
      skeuoWeight = style == UiSurfaceStyle.skeuo ? 1.0 : 0.0,
      glassWeight = style == UiSurfaceStyle.glass ? 1.0 : 0.0;

  const AppSurfaceStyle._({
    required this.style,
    required this.neoWeight,
    required this.skeuoWeight,
    required this.glassWeight,
  });

  /// Normalised blend; [style] becomes the dominant component.
  factory AppSurfaceStyle.blend({
    required double neo,
    required double skeuo,
    required double glass,
  }) {
    final n = math.max(0.0, neo);
    final s = math.max(0.0, skeuo);
    final g = math.max(0.0, glass);
    final sum = n + s + g;
    if (sum <= 0) return AppSurfaceStyle.neo;
    final dominant = n >= s && n >= g
        ? UiSurfaceStyle.neo
        : (s >= g ? UiSurfaceStyle.skeuo : UiSurfaceStyle.glass);
    return AppSurfaceStyle._(
      style: dominant,
      neoWeight: n / sum,
      skeuoWeight: s / sum,
      glassWeight: g / sum,
    );
  }

  static const neo = AppSurfaceStyle(style: UiSurfaceStyle.neo);
  static const skeuo = AppSurfaceStyle(style: UiSurfaceStyle.skeuo);
  static const glass = AppSurfaceStyle(style: UiSurfaceStyle.glass);

  /// Dominant style (the target once a theme animation has settled).
  final UiSurfaceStyle style;
  final double neoWeight;
  final double skeuoWeight;
  final double glassWeight;

  bool get isNeo => style == UiSurfaceStyle.neo;
  bool get isSkeuo => style == UiSurfaceStyle.skeuo;
  bool get isGlass => style == UiSurfaceStyle.glass;

  /// True while a theme animation is between two styles.
  bool get isBlending => weightOf(style) < 0.999;

  double weightOf(UiSurfaceStyle s) => switch (s) {
    UiSurfaceStyle.neo => neoWeight,
    UiSurfaceStyle.skeuo => skeuoWeight,
    UiSurfaceStyle.glass => glassWeight,
  };

  double _mix(double Function(UiSurfaceStyle s) of) =>
      neoWeight * of(UiSurfaceStyle.neo) +
      skeuoWeight * of(UiSurfaceStyle.skeuo) +
      glassWeight * of(UiSurfaceStyle.glass);

  /// Builds the decoration for every style that has weight and blends them.
  BoxDecoration _mixDeco(BoxDecoration Function(UiSurfaceStyle s) of) {
    if (!isBlending) return of(style);
    BoxDecoration? acc;
    var accWeight = 0.0;
    for (final s in UiSurfaceStyle.values) {
      final w = weightOf(s);
      if (w <= 0.0005) continue;
      final d = of(s);
      if (acc == null) {
        acc = d;
        accWeight = w;
        continue;
      }
      final next = accWeight + w;
      acc = BoxDecoration.lerp(acc, d, w / next);
      accWeight = next;
    }
    return acc ?? of(style);
  }

  // ---------------------------------------------------------------- metrics

  double get cardRadius => _mix(
    (s) => switch (s) {
      UiSurfaceStyle.neo => AppTheme.radiusCard,
      UiSurfaceStyle.skeuo => 14,
      UiSurfaceStyle.glass => 20,
    },
  );

  double get controlRadius => _mix(
    (s) => switch (s) {
      UiSurfaceStyle.neo => AppTheme.radiusControl,
      UiSurfaceStyle.skeuo => 12,
      UiSurfaceStyle.glass => 16,
    },
  );

  double get sheetRadius => AppTheme.radiusSheet;

  /// Card / panel blur sigma (18–22).
  double get glassCardSigma => 20;

  /// Chip / secondary control blur (14–16).
  double get glassChipSigma => 15;

  /// Nav island blur (24–28).
  double get glassNavSigma => 26;

  /// Sheet blur (26–30).
  double get glassSheetSigma => 28;

  /// Effective blur for a glass role, scaled by how "glass" the blend is.
  double blurSigma(double roleSigma) => roleSigma * glassWeight;

  /// Whether translucent frost may be used. High-contrast mode is the closest
  /// signal Flutter exposes to "reduce transparency", so glass falls back to
  /// opaque fills there.
  static bool glassBlurEnabled(BuildContext context) {
    return !(MediaQuery.maybeHighContrastOf(context) ?? false);
  }

  // ----------------------------------------------------------------- tokens

  static const Color glassFillLight = Color(0xFFFFFBF7);
  static const Color glassFillDark = Color(0xFF2E2A27);
  static const Color _ink = Color(0xFF1C1916);

  static bool _isDark(AppColors c) => c.bg.computeLuminance() < 0.5;

  static LinearGradient _solid(Color color) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [color, color],
  );

  static Color _glassHairline(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.14)
      : Colors.white.withValues(alpha: 0.72);

  static List<BoxShadow> _glassFloat(bool isDark, {bool pressed = false}) => [
    BoxShadow(
      color: isDark ? const Color(0x73000000) : const Color(0x1F1C1916),
      offset: Offset(0, pressed ? 4 : 10),
      blurRadius: pressed ? 14 : 28,
      spreadRadius: -4,
    ),
  ];

  /// Frost fill: a diagonal sheen (brighter top-left) so panels read as glass
  /// even where the page wash behind them is flat.
  static LinearGradient _frost(
    bool isDark, {
    required double alpha,
    Color? tint,
  }) {
    final base = isDark ? Colors.white : glassFillLight;
    final tinted = tint == null ? base : Color.lerp(base, tint, 0.35)!;
    final hi = (alpha + (isDark ? 0.05 : 0.14)).clamp(0.0, 1.0);
    final lo = (alpha - (isDark ? 0.03 : 0.10)).clamp(0.0, 1.0);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        tinted.withValues(alpha: hi),
        tinted.withValues(alpha: lo),
      ],
    );
  }

  /// Soften dual neo shadows (pressed / secondary).
  static List<BoxShadow> _halveNeo(List<BoxShadow> src) => [
    for (final s in src)
      BoxShadow(
        color: s.color.withValues(alpha: (s.color.a * 0.55).clamp(0.0, 1.0)),
        offset: Offset(s.offset.dx * 0.5, s.offset.dy * 0.5),
        blurRadius: s.blurRadius * 0.55,
        spreadRadius: s.spreadRadius * 0.5,
      ),
  ];

  static List<BoxShadow> _skeuoShadows(bool isDark, {bool pressed = false}) => [
    // Contact — deeper than neo dual, vertical-only.
    BoxShadow(
      color: isDark ? const Color(0xB3000000) : const Color(0x4D1C1916),
      offset: Offset(0, pressed ? 3 : 8),
      blurRadius: pressed ? 7 : 16,
      spreadRadius: -2,
    ),
    // Ambient.
    BoxShadow(
      color: isDark ? const Color(0x55000000) : const Color(0x241C1916),
      offset: Offset(0, pressed ? 1 : 2),
      blurRadius: pressed ? 2 : 4,
    ),
  ];

  static LinearGradient _skeuoFill(AppColors c, {bool pressed = false}) {
    final isDark = _isDark(c);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              Color.lerp(c.surfaceMuted, Colors.white, pressed ? 0.08 : 0.16)!,
              pressed ? c.surfaceMuted : c.surface,
              Color.lerp(c.bgElevated, Colors.black, pressed ? 0.30 : 0.24)!,
            ]
          : [
              Color.lerp(c.bgElevated, Colors.white, pressed ? 0.55 : 0.80)!,
              pressed ? c.surface : Color.lerp(c.bgElevated, c.surface, 0.35)!,
              Color.lerp(c.surface, _ink, pressed ? 0.15 : 0.10)!,
            ],
      stops: const [0.0, 0.42, 1.0],
    );
  }

  static Border _skeuoRim(bool isDark) => Border.all(
    color: isDark ? const Color(0x47FFFFFF) : const Color(0xCCFFFFFF),
    width: 0.8,
  );

  // ------------------------------------------------------------ decorations

  /// Card / panel decoration.
  /// Neo: fill ≈ bg + dual soft shadows (SE dark + NW light).
  /// Skeuo: vertical gradient + contact + ambient + rim.
  /// Glass: frost sheen + hairline + soft float (blur via [SurfaceBlur]).
  /// [pressed]: neo inset-ish (muted fill + halved shadows).
  /// [opaqueFallback]: reduce-transparency — solid fill, no frost alpha.
  BoxDecoration cardDecoration(
    AppColors c, {
    double? radius,
    bool blurPanel = false,
    bool pressed = false,
    bool opaqueFallback = false,
  }) {
    final r = BorderRadius.circular(radius ?? cardRadius);
    final isDark = _isDark(c);
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _solid(pressed ? c.surfaceMuted : c.bg),
            boxShadow: pressed ? _halveNeo(c.neoShadows) : c.neoShadows,
          );
        case UiSurfaceStyle.skeuo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _skeuoFill(c, pressed: pressed),
            border: _skeuoRim(isDark),
            boxShadow: _skeuoShadows(isDark, pressed: pressed),
          );
        case UiSurfaceStyle.glass:
          if (opaqueFallback) {
            return BoxDecoration(
              borderRadius: r,
              gradient: _solid(isDark ? glassFillDark : glassFillLight),
              border: Border.all(color: _glassHairline(isDark)),
              boxShadow: _glassFloat(isDark, pressed: pressed),
            );
          }
          // Blurred panels can afford less fill; plain rows need a bit more
          // body because nothing frosts the wash behind them.
          var alpha = isDark
              ? (blurPanel ? 0.09 : 0.11)
              : (blurPanel ? 0.50 : 0.56);
          if (pressed) alpha += isDark ? 0.05 : 0.08;
          return BoxDecoration(
            borderRadius: r,
            gradient: _frost(isDark, alpha: alpha),
            border: Border.all(color: _glassHairline(isDark)),
            boxShadow: _glassFloat(isDark, pressed: pressed),
          );
      }
    });
  }

  /// Bottom sheet panel (top corners only).
  BoxDecoration sheetDecoration(
    AppColors c, {
    bool blurPanel = true,
    bool opaqueFallback = false,
  }) {
    final r = BorderRadius.vertical(top: Radius.circular(sheetRadius));
    final isDark = _isDark(c);
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _solid(c.bg),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x99000000) : const Color(0x261C1916),
                offset: const Offset(0, -6),
                blurRadius: 24,
              ),
            ],
          );
        case UiSurfaceStyle.skeuo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _skeuoFill(c),
            border: _skeuoRim(isDark),
            boxShadow: _skeuoShadows(isDark),
          );
        case UiSurfaceStyle.glass:
          final fill = opaqueFallback
              ? _solid(c.bgElevated)
              : _frost(
                  isDark,
                  alpha: isDark ? 0.16 : 0.74,
                  tint: isDark ? null : c.bgElevated,
                );
          return BoxDecoration(
            borderRadius: r,
            gradient: fill,
            border: Border.all(color: _glassHairline(isDark)),
            boxShadow: _glassFloat(isDark),
          );
      }
    });
  }

  /// Secondary control (Skip / Reset) — raised soft surface, not a flat
  /// outline.
  BoxDecoration secondaryDecoration(
    AppColors c, {
    double? radius,
    bool pressed = false,
    bool opaqueFallback = false,
  }) {
    return cardDecoration(
      c,
      radius: radius ?? controlRadius,
      blurPanel: true,
      pressed: pressed,
      opaqueFallback: opaqueFallback,
    );
  }

  /// Small chip / pill (Seç, filter chips). Selected = solid accent.
  BoxDecoration chipDecoration(
    AppColors c, {
    double? radius,
    bool selected = false,
    bool pressed = false,
    bool opaqueFallback = false,
  }) {
    final r = BorderRadius.circular(radius ?? AppTheme.radiusPill);
    final isDark = _isDark(c);
    if (selected) {
      return BoxDecoration(
        borderRadius: r,
        gradient: _solid(c.accent),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: 0.32),
            offset: const Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      );
    }
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _solid(pressed ? c.surfaceMuted : c.bg),
            boxShadow: _halveNeo(c.neoShadows),
          );
        case UiSurfaceStyle.skeuo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _skeuoFill(c, pressed: pressed),
            border: _skeuoRim(isDark),
            boxShadow: _skeuoShadows(isDark, pressed: true),
          );
        case UiSurfaceStyle.glass:
          return BoxDecoration(
            borderRadius: r,
            gradient: opaqueFallback
                ? _solid(c.accentMuted)
                : _frost(
                    isDark,
                    alpha: isDark ? 0.10 : 0.50,
                    tint: c.accentMuted,
                  ),
            border: Border.all(color: _glassHairline(isDark)),
          );
      }
    });
  }

  /// Floating nav island capsule.
  BoxDecoration islandDecoration(AppColors c, {bool opaqueFallback = false}) {
    final r = BorderRadius.circular(AppTheme.radiusPill);
    final isDark = _isDark(c);
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          return BoxDecoration(
            borderRadius: r,
            gradient: _solid(c.bg),
            boxShadow: c.neoShadows,
          );
        case UiSurfaceStyle.skeuo:
          return BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [c.surfaceMuted, c.surface]
                  : [Color.lerp(c.bgElevated, Colors.white, 0.45)!, c.surface],
            ),
            border: _skeuoRim(isDark),
            boxShadow: [
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
            ],
          );
        case UiSurfaceStyle.glass:
          return BoxDecoration(
            borderRadius: r,
            gradient: opaqueFallback
                ? _solid(c.bgElevated)
                : _frost(
                    isDark,
                    alpha: isDark ? 0.12 : 0.62,
                    tint: isDark ? null : c.bgElevated,
                  ),
            border: Border.all(color: _glassHairline(isDark)),
            boxShadow: _glassFloat(isDark),
          );
      }
    });
  }

  /// Primary CTA — solid fill for neo, sheen for glass, highlight→base→pressed
  /// bevel for skeuo.
  BoxDecoration ctaDecoration(AppColors c, {Color? color, double? radius}) {
    final r = BorderRadius.circular(radius ?? controlRadius);
    final base = color ?? c.accent;
    final isDark = _isDark(c);
    final glow = [
      BoxShadow(
        color: base.withValues(alpha: 0.40),
        offset: const Offset(0, 6),
        blurRadius: 14,
        spreadRadius: -2,
      ),
    ];
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          return BoxDecoration(borderRadius: r, gradient: _solid(base), boxShadow: glow);
        case UiSurfaceStyle.skeuo:
          final highlight = Color.lerp(base, Colors.white, isDark ? 0.30 : 0.26)!;
          final pressed = base == c.accent
              ? c.accentPressed
              : (base == c.breakColor
                    ? c.breakPressed
                    : Color.lerp(base, Colors.black, 0.12)!);
          return BoxDecoration(
            borderRadius: r,
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
        case UiSurfaceStyle.glass:
          // Glass CTA stays solid (frosted CTAs are unreadable) with a sheen.
          return BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(base, Colors.white, 0.16)!, base],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            boxShadow: glow,
          );
      }
    });
  }

  /// Recessed well (unchecked circle, empty week dot, history badge).
  BoxDecoration insetDecoration(AppColors c, {double? radius}) {
    final r = BorderRadius.circular(radius ?? controlRadius);
    final isDark = _isDark(c);
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          // Concave: darker top-left, lit bottom-right edge.
          return BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(c.surfaceMuted, isDark ? Colors.black : _ink, isDark ? 0.28 : 0.07)!,
                Color.lerp(c.surfaceMuted, Colors.white, isDark ? 0.04 : 0.42)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x4D4A433C) : const Color(0xCCFFFFFF),
                offset: const Offset(1.5, 1.5),
                blurRadius: 3,
              ),
              BoxShadow(
                color: isDark ? const Color(0x66000000) : const Color(0x1F1C1916),
                offset: const Offset(-1, -1),
                blurRadius: 3,
              ),
            ],
          );
        case UiSurfaceStyle.skeuo:
          return BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.lerp(c.surfaceMuted, Colors.black, isDark ? 0.30 : 0.10)!,
                c.surfaceMuted,
              ],
            ),
            border: Border.all(
              color: isDark ? const Color(0x33FFFFFF) : _ink.withValues(alpha: 0.12),
              width: 0.8,
            ),
          );
        case UiSurfaceStyle.glass:
          return BoxDecoration(
            borderRadius: r,
            gradient: _solid(
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : c.surfaceMuted.withValues(alpha: 0.55),
            ),
            border: Border.all(color: _glassHairline(isDark)),
          );
      }
    });
  }

  /// Disc behind the timer ring — neo dual extrusion, skeuo bevel, glass
  /// frosted lens. Always a circle so blends never change shape.
  BoxDecoration ringWellDecoration(AppColors c) {
    final isDark = _isDark(c);
    return _mixDeco((s) {
      switch (s) {
        case UiSurfaceStyle.neo:
          return BoxDecoration(
            shape: BoxShape.circle,
            gradient: _solid(c.bg),
            boxShadow: isDark
                ? const [
                    BoxShadow(color: Color(0x8C000000), offset: Offset(6, 6), blurRadius: 16, spreadRadius: 1),
                    BoxShadow(color: Color(0x7A4A433C), offset: Offset(-5, -5), blurRadius: 12),
                  ]
                : const [
                    BoxShadow(color: Color(0x381C1916), offset: Offset(7, 7), blurRadius: 18, spreadRadius: 1),
                    BoxShadow(color: Color(0xFFFFFFFF), offset: Offset(-6, -6), blurRadius: 14),
                  ],
          );
        case UiSurfaceStyle.skeuo:
          return BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      Color.lerp(c.surfaceMuted, Colors.white, 0.08)!,
                      Color.lerp(c.bgElevated, Colors.black, 0.18)!,
                    ]
                  : [
                      Color.lerp(c.bgElevated, Colors.white, 0.55)!,
                      Color.lerp(c.surface, _ink, 0.07)!,
                    ],
            ),
            border: Border.all(
              color: isDark ? const Color(0x40FFFFFF) : const Color(0xB3FFFFFF),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? const Color(0x99000000) : const Color(0x381C1916),
                offset: const Offset(0, 10),
                blurRadius: 20,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: isDark ? const Color(0x55000000) : const Color(0x1F1C1916),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          );
        case UiSurfaceStyle.glass:
          return BoxDecoration(
            shape: BoxShape.circle,
            gradient: _frost(isDark, alpha: isDark ? 0.07 : 0.34),
            border: Border.all(color: _glassHairline(isDark)),
            boxShadow: _glassFloat(isDark),
          );
      }
    });
  }

  @override
  AppSurfaceStyle copyWith({UiSurfaceStyle? style}) =>
      style == null ? this : AppSurfaceStyle(style: style);

  @override
  AppSurfaceStyle lerp(ThemeExtension<AppSurfaceStyle>? other, double t) {
    if (other is! AppSurfaceStyle) return this;
    if (t <= 0) return this;
    if (t >= 1) return other;
    return AppSurfaceStyle.blend(
      neo: lerpDouble(neoWeight, other.neoWeight, t)!,
      skeuo: lerpDouble(skeuoWeight, other.skeuoWeight, t)!,
      glass: lerpDouble(glassWeight, other.glassWeight, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSurfaceStyle &&
      other.style == style &&
      other.neoWeight == neoWeight &&
      other.skeuoWeight == skeuoWeight &&
      other.glassWeight == glassWeight;

  @override
  int get hashCode => Object.hash(style, neoWeight, skeuoWeight, glassWeight);
}

extension AppSurfaceStyleX on BuildContext {
  AppSurfaceStyle get surfaceStyle =>
      Theme.of(this).extension<AppSurfaceStyle>() ?? AppSurfaceStyle.neo;
}

/// Page background shared by every route: palette `bg` plus a colourful wash
/// that fades in with the glass weight (frost needs something to blur).
///
/// Lives once at the app root so scaffolds can stay transparent for every
/// style — no `bg → transparent` colour lerp (which flashes muddy grey).
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final glass = context.surfaceStyle.glassWeight.clamp(0.0, 1.0);
    return ColoredBox(
      color: c.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(
                opacity: glass,
                child: CustomPaint(painter: GlassWashPainter(c)),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Soft accent / break-colour light pools painted behind glass surfaces.
class GlassWashPainter extends CustomPainter {
  GlassWashPainter(this.c);

  final AppColors c;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final isDark = c.bg.computeLuminance() < 0.5;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accent.withValues(alpha: isDark ? 0.12 : 0.09),
            c.bg.withValues(alpha: 0),
            c.breakColor.withValues(alpha: isDark ? 0.12 : 0.08),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    final w = size.width;
    final h = size.height;
    final mid = Color.lerp(c.accent, c.breakColor, 0.5)!;
    _blob(canvas, Offset(w * 0.98, h * 0.07), w * 0.78,
        c.accent.withValues(alpha: isDark ? 0.40 : 0.30));
    _blob(canvas, Offset(w * -0.06, h * 0.50), w * 0.80,
        c.breakColor.withValues(alpha: isDark ? 0.30 : 0.22));
    _blob(canvas, Offset(w * 0.80, h * 0.92), w * 0.70,
        mid.withValues(alpha: isDark ? 0.26 : 0.18));
  }

  void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant GlassWashPainter old) =>
      old.c.accent != c.accent ||
      old.c.breakColor != c.breakColor ||
      old.c.bg != c.bg;
}

/// Clips + frosts its child according to the current glass weight.
///
/// The widget tree is identical for every style; the blur is switched with
/// [BackdropFilter.enabled] so children never lose state mid-transition.
class SurfaceBlur extends StatelessWidget {
  const SurfaceBlur({
    super.key,
    required this.child,
    required this.borderRadius,
    this.sigma,
    this.enabled = true,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Role sigma at full glass (defaults to [AppSurfaceStyle.glassCardSigma]).
  final double? sigma;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final surf = context.surfaceStyle;
    final allowed = enabled && AppSurfaceStyle.glassBlurEnabled(context);
    final s = allowed ? surf.blurSigma(sigma ?? surf.glassCardSigma) : 0.0;
    final on = s > 0.25;
    return ClipRRect(
      borderRadius: borderRadius,
      clipBehavior: on ? Clip.antiAlias : Clip.none,
      child: BackdropFilter(
        enabled: on,
        filter: ImageFilter.blur(sigmaX: s, sigmaY: s),
        child: child,
      ),
    );
  }
}
