import 'package:easy_pomodoro/core/theme/app_colors.dart';
import 'package:easy_pomodoro/core/theme/app_palette.dart';
import 'package:easy_pomodoro/core/theme/app_surface_style.dart';
import 'package:easy_pomodoro/features/timer/domain/pomodoro_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every decoration the app paints, for one style blend + palette.
List<BoxDecoration> _allDecorations(AppSurfaceStyle s, AppColors c) => [
  s.cardDecoration(c),
  s.cardDecoration(c, blurPanel: true),
  s.cardDecoration(c, pressed: true),
  s.cardDecoration(c, opaqueFallback: true),
  s.sheetDecoration(c),
  s.secondaryDecoration(c),
  s.chipDecoration(c),
  s.chipDecoration(c, selected: true),
  s.islandDecoration(c),
  s.ctaDecoration(c),
  s.ctaDecoration(c, color: c.breakColor),
  s.insetDecoration(c),
  s.ringWellDecoration(c),
];

void main() {
  final palettes = [
    for (final b in Brightness.values)
      for (final p in ColorPaletteId.values) AppColors.resolve(b, p),
  ];

  group('AppSurfaceStyle weights', () {
    test('pure styles have a single full weight', () {
      for (final style in UiSurfaceStyle.values) {
        final s = AppSurfaceStyle(style: style);
        expect(s.weightOf(style), 1.0);
        expect(s.isBlending, isFalse);
        expect(
          UiSurfaceStyle.values.map(s.weightOf).reduce((a, b) => a + b),
          1.0,
        );
      }
    });

    test('lerp blends continuously instead of snapping at t = 0.5', () {
      const neo = AppSurfaceStyle.neo;
      const glass = AppSurfaceStyle.glass;
      expect(neo.lerp(glass, 0), same(neo));
      expect(neo.lerp(glass, 1), same(glass));

      final quarter = neo.lerp(glass, 0.25);
      expect(quarter.neoWeight, closeTo(0.75, 1e-9));
      expect(quarter.glassWeight, closeTo(0.25, 1e-9));
      expect(quarter.style, UiSurfaceStyle.neo);
      expect(quarter.isBlending, isTrue);

      final late = neo.lerp(glass, 0.8);
      expect(late.style, UiSurfaceStyle.glass);
      expect(late.glassWeight, closeTo(0.8, 1e-9));
    });

    test('re-targeting mid animation keeps weights normalised', () {
      final mid = AppSurfaceStyle.neo.lerp(AppSurfaceStyle.glass, 0.5);
      final retarget = mid.lerp(AppSurfaceStyle.skeuo, 0.5);
      final sum =
          retarget.neoWeight + retarget.skeuoWeight + retarget.glassWeight;
      expect(sum, closeTo(1.0, 1e-9));
      expect(retarget.skeuoWeight, closeTo(0.5, 1e-9));
      expect(retarget.neoWeight, closeTo(0.25, 1e-9));
    });

    test('radii and blur interpolate', () {
      final half = AppSurfaceStyle.neo.lerp(AppSurfaceStyle.glass, 0.5);
      expect(
        half.cardRadius,
        closeTo(
          (AppSurfaceStyle.neo.cardRadius + AppSurfaceStyle.glass.cardRadius) /
              2,
          1e-9,
        ),
      );
      expect(AppSurfaceStyle.neo.blurSigma(20), 0);
      expect(half.blurSigma(20), closeTo(10, 1e-9));
      expect(AppSurfaceStyle.glass.blurSigma(20), 20);
    });

    test('value equality keeps unchanged themes from re-animating', () {
      expect(
        const AppSurfaceStyle(style: UiSurfaceStyle.skeuo),
        AppSurfaceStyle.skeuo,
      );
      expect(
        AppColors.resolve(Brightness.light, ColorPaletteId.ocean),
        AppColors.resolve(Brightness.light, ColorPaletteId.ocean),
      );
    });
  });

  group('decorations are morph-safe', () {
    final blends = [
      for (final s in UiSurfaceStyle.values) AppSurfaceStyle(style: s),
      for (final a in UiSurfaceStyle.values)
        for (final b in UiSurfaceStyle.values)
          if (a != b)
            for (final t in [0.2, 0.5, 0.8])
              AppSurfaceStyle(style: a).lerp(AppSurfaceStyle(style: b), t),
    ];

    test('fills are gradients, never a bare colour', () {
      // color ↔ gradient lerps multiply alphas and make surfaces flicker.
      for (final c in palettes) {
        for (final s in blends) {
          for (final d in _allDecorations(s, c)) {
            expect(d.color, isNull);
            expect(d.gradient, isA<LinearGradient>());
          }
        }
      }
    });

    test('borders stay uniform so rounded corners can paint them', () {
      for (final c in palettes) {
        for (final s in blends) {
          for (final d in _allDecorations(s, c)) {
            final border = d.border;
            if (border == null) continue;
            expect(border.isUniform, isTrue, reason: '$border');
          }
        }
      }
    });

    test('blend at the start of an animation equals the source style', () {
      final c = palettes.first;
      for (final a in UiSurfaceStyle.values) {
        for (final b in UiSurfaceStyle.values) {
          final start = AppSurfaceStyle(style: a)
              .lerp(AppSurfaceStyle(style: b), 1e-6);
          expect(
            start.cardDecoration(c).gradient!.colors.first.a,
            closeTo(
              AppSurfaceStyle(style: a).cardDecoration(c).gradient!.colors.first.a,
              1e-3,
            ),
          );
        }
      }
    });
  });

  test('neo shadows lerp between light and dark instead of snapping', () {
    final light = AppColors.resolve(Brightness.light, ColorPaletteId.tomato);
    final dark = AppColors.resolve(Brightness.dark, ColorPaletteId.tomato);
    final mid = light.lerp(dark, 0.5);
    expect(mid.neoShadows, isNot(light.neoShadows));
    expect(mid.neoShadows, isNot(dark.neoShadows));
  });
}
