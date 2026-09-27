import 'package:flutter/material.dart';

import 'app_palette.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.bgElevated,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.accent,
    required this.accentPressed,
    required this.accentSoft,
    required this.breakColor,
    required this.breakPressed,
    required this.breakSoft,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.danger,
    required this.success,
    required this.neoShadows,
  });

  final Color bg;
  final Color bgElevated;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color accent;
  final Color accentPressed;
  final Color accentSoft;
  final Color breakColor;
  final Color breakPressed;
  final Color breakSoft;
  final Color onAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color danger;
  final Color success;
  final List<BoxShadow> neoShadows;

  /// Chip / soft fill â€” always derived from active [accent] via accentSoft.
  Color get accentMuted => accentSoft;
  Color get breakMuted => breakSoft;

  /// All accents/softs/muted surfaces come from [palette] + brightness.
  /// No hardcoded tomato/peach leftover â€” ocean UI is blue end-to-end.
  static AppColors resolve(Brightness brightness, ColorPaletteId palette) {
    final a = PaletteAccents.of(palette, brightness);
    const cream = Color(0xFFEDE7E0);
    const warmWhite = Color(0xFFF5F0EA);
    const ink = Color(0xFF1C1916);
    const darkBg = Color(0xFF1A1816);
    const darkElev = Color(0xFF221F1C);
    const darkSurf = Color(0xFF2E2A27);

    if (brightness == Brightness.dark) {
      final softA = Color.lerp(darkSurf, a.accent, 0.30)!;
      final softB = Color.lerp(darkSurf, a.breakColor, 0.28)!;
      final muted = Color.lerp(darkSurf, a.accent, 0.14)!;
      return AppColors(
        bg: darkBg,
        bgElevated: darkElev,
        surface: darkSurf,
        surfaceMuted: muted,
        border: Color.lerp(darkSurf, a.accent, 0.08)!.withValues(alpha: 1),
        accent: a.accent,
        accentPressed: a.accentPressed,
        accentSoft: softA,
        breakColor: a.breakColor,
        breakPressed: a.breakPressed,
        breakSoft: softB,
        onAccent: const Color(0xFFFFFFFF),
        textPrimary: const Color(0xFFF4F0EA),
        textSecondary: const Color(0xFFB5A99C),
        textTertiary: const Color(0xFF7A7168),
        danger: const Color(0xFFE85D4C),
        success: const Color(0xFF5BAF7A),
        neoShadows: const [
          BoxShadow(
            color: Color(0x99000000),
            offset: Offset(5, 6),
            blurRadius: 16,
          ),
          BoxShadow(
            color: Color(0xA34A433C),
            offset: Offset(-3, -3),
            blurRadius: 10,
          ),
        ],
      );
    }

    // Light: cream paper + surfaces lightly tinted by ACTIVE accent (not peach).
    final softA = Color.lerp(cream, a.accent, 0.18)!;
    final softB = Color.lerp(cream, a.breakColor, 0.16)!;
    // surface == bg so neo dual-shadow extrusion reads (not pure-white floating cards).
    const surface = cream;
    final surfaceMuted = Color.lerp(cream, a.accent, 0.11)!;
    final border = Color.lerp(const Color(0xFFE8E0D8), a.accent, 0.08)!;

    return AppColors(
      bg: cream,
      bgElevated: warmWhite,
      surface: surface,
      surfaceMuted: surfaceMuted,
      border: border,
      accent: a.accent,
      accentPressed: a.accentPressed,
      accentSoft: softA,
      breakColor: a.breakColor,
      breakPressed: a.breakPressed,
      breakSoft: softB,
      onAccent: const Color(0xFFFFFFFF),
      textPrimary: ink,
      textSecondary: const Color(0xFF5C554D),
      textTertiary: const Color(0xFF756A60),
      danger: const Color(0xFFC43C2E),
      success: const Color(0xFF2F8A54),
      neoShadows: const [
        BoxShadow(
          color: Color(0x401C1916),
          offset: Offset(6, 6),
          blurRadius: 18,
        ),
        BoxShadow(
          color: Color(0xFFFFFFFF),
          offset: Offset(-5, -5),
          blurRadius: 14,
        ),
      ],
    );
  }

  static AppColors get dark =>
      resolve(Brightness.dark, ColorPaletteId.tomato);
  static AppColors get light =>
      resolve(Brightness.light, ColorPaletteId.tomato);

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? bg,
    Color? bgElevated,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? accent,
    Color? accentPressed,
    Color? accentSoft,
    Color? breakColor,
    Color? breakPressed,
    Color? breakSoft,
    Color? onAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? danger,
    Color? success,
    List<BoxShadow>? neoShadows,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      bgElevated: bgElevated ?? this.bgElevated,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      accent: accent ?? this.accent,
      accentPressed: accentPressed ?? this.accentPressed,
      accentSoft: accentSoft ?? this.accentSoft,
      breakColor: breakColor ?? this.breakColor,
      breakPressed: breakPressed ?? this.breakPressed,
      breakSoft: breakSoft ?? this.breakSoft,
      onAccent: onAccent ?? this.onAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      neoShadows: neoShadows ?? this.neoShadows,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentPressed: Color.lerp(accentPressed, other.accentPressed, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      breakColor: Color.lerp(breakColor, other.breakColor, t)!,
      breakPressed: Color.lerp(breakPressed, other.breakPressed, t)!,
      breakSoft: Color.lerp(breakSoft, other.breakSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      neoShadows: t < 0.5 ? neoShadows : other.neoShadows,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => AppColors.of(this);
}