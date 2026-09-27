import 'package:flutter/material.dart';

/// Accent/break color families. Surfaces stay on lifted paper tokens.
enum ColorPaletteId {
  tomato,
  ocean,
  forest,
  grape,
  sunset,
  slate,
}

extension ColorPaletteIdX on ColorPaletteId {
  String get labelTr => switch (this) {
        ColorPaletteId.tomato => 'Domates',
        ColorPaletteId.ocean => 'Okyanus',
        ColorPaletteId.forest => 'Orman',
        ColorPaletteId.grape => '\u00dcz\u00fcm',
        ColorPaletteId.sunset => 'G\u00fcn bat\u0131m\u0131',
        ColorPaletteId.slate => 'Arduvaz',
      };

  Color get swatch => switch (this) {
        ColorPaletteId.tomato => const Color(0xFFF97316),
        ColorPaletteId.ocean => const Color(0xFF2563EB),
        ColorPaletteId.forest => const Color(0xFF059669),
        ColorPaletteId.grape => const Color(0xFF7C3AED),
        ColorPaletteId.sunset => const Color(0xFFEA580C),
        ColorPaletteId.slate => const Color(0xFF475569),
      };
}

@immutable
class PaletteAccents {
  const PaletteAccents({
    required this.accent,
    required this.accentPressed,
    required this.breakColor,
    required this.breakPressed,
  });

  final Color accent;
  final Color accentPressed;
  final Color breakColor;
  final Color breakPressed;

  static PaletteAccents of(ColorPaletteId id, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (id) {
      case ColorPaletteId.tomato:
        return dark
            ? const PaletteAccents(
                accent: Color(0xFFFF6B35),
                accentPressed: Color(0xFFE85A28),
                breakColor: Color(0xFF2EB8A1),
                breakPressed: Color(0xFF249E8A),
              )
            : const PaletteAccents(
                accent: Color(0xFFF97316),
                accentPressed: Color(0xFFEA580C),
                breakColor: Color(0xFF0D9488),
                breakPressed: Color(0xFF0F766E),
              );
      case ColorPaletteId.ocean:
        return dark
            ? const PaletteAccents(
                accent: Color(0xFF60A5FA),
                accentPressed: Color(0xFF3B82F6),
                breakColor: Color(0xFF2DD4BF),
                breakPressed: Color(0xFF14B8A6),
              )
            : const PaletteAccents(
                accent: Color(0xFF2563EB),
                accentPressed: Color(0xFF1D4ED8),
                breakColor: Color(0xFF0D9488),
                breakPressed: Color(0xFF0F766E),
              );
      case ColorPaletteId.forest:
        return dark
            ? const PaletteAccents(
                accent: Color(0xFF34D399),
                accentPressed: Color(0xFF10B981),
                breakColor: Color(0xFF2DD4BF),
                breakPressed: Color(0xFF14B8A6),
              )
            : const PaletteAccents(
                accent: Color(0xFF059669),
                accentPressed: Color(0xFF047857),
                breakColor: Color(0xFF0F766E),
                breakPressed: Color(0xFF115E59),
              );
      case ColorPaletteId.grape:
        return dark
            ? const PaletteAccents(
                accent: Color(0xFFA78BFA),
                accentPressed: Color(0xFF8B5CF6),
                breakColor: Color(0xFF2DD4BF),
                breakPressed: Color(0xFF14B8A6),
              )
            : const PaletteAccents(
                accent: Color(0xFF7C3AED),
                accentPressed: Color(0xFF6D28D9),
                breakColor: Color(0xFF0D9488),
                breakPressed: Color(0xFF0F766E),
              );
      case ColorPaletteId.sunset:
        return dark
            ? const PaletteAccents(
                accent: Color(0xFFFB923C),
                accentPressed: Color(0xFFF97316),
                breakColor: Color(0xFFF472B6),
                breakPressed: Color(0xFFEC4899),
              )
            : const PaletteAccents(
                accent: Color(0xFFEA580C),
                accentPressed: Color(0xFFC2410C),
                breakColor: Color(0xFFDB2777),
                breakPressed: Color(0xFFBE185D),
              );
      case ColorPaletteId.slate:
        return dark
            ? const PaletteAccents(
                accent: Color(0xFF94A3B8),
                accentPressed: Color(0xFF64748B),
                breakColor: Color(0xFF2DD4BF),
                breakPressed: Color(0xFF14B8A6),
              )
            : const PaletteAccents(
                accent: Color(0xFF475569),
                accentPressed: Color(0xFF334155),
                breakColor: Color(0xFF0F766E),
                breakPressed: Color(0xFF115E59),
              );
    }
  }
}
