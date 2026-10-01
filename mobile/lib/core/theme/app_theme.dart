import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/timer/domain/pomodoro_settings.dart';
import 'app_colors.dart';
import 'app_palette.dart';
import 'app_surface_style.dart';

class AppTheme {
  static const radiusControl = 12.0;
  static const radiusCard = 16.0;
  static const radiusSheet = 20.0;
  static const radiusPill = 999.0;
  static const ringStroke = 7.0;
  static const pagePaddingH = 20.0;
  static const floatingNavHeight = 58.0;
  static const floatingFabSize = 56.0;
  static const floatingNavGap = 12.0;

  static ThemeData light({
    UiSurfaceStyle uiStyle = UiSurfaceStyle.neo,
    ColorPaletteId palette = ColorPaletteId.tomato,
  }) =>
      _build(AppColors.resolve(Brightness.light, palette), Brightness.light, uiStyle);

  static ThemeData dark({
    UiSurfaceStyle uiStyle = UiSurfaceStyle.neo,
    ColorPaletteId palette = ColorPaletteId.tomato,
  }) =>
      _build(AppColors.resolve(Brightness.dark, palette), Brightness.dark, uiStyle);

  static SystemUiOverlayStyle overlayFor(Brightness brightness) {
    final light = brightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
      statusBarBrightness: light ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          light ? Brightness.dark : Brightness.light,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData _build(
    AppColors colors,
    Brightness brightness,
    UiSurfaceStyle uiStyle,
  ) {
    final dmSans = GoogleFonts.dmSansTextTheme();
    final base = brightness == Brightness.light
        ? ThemeData.light(useMaterial3: true)
        : ThemeData.dark(useMaterial3: true);
    final surfaceExt = AppSurfaceStyle(style: uiStyle);

    return base.copyWith(
      brightness: brightness,
      // Every style paints its page background once in [AppBackdrop]
      // (palette bg + glass wash). Scaffolds stay transparent so a style
      // switch never lerps bg → transparent black (muddy grey flash).
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: colors.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        onPrimary: colors.onAccent,
        secondary: colors.breakColor,
        onSecondary: colors.onAccent,
        error: colors.danger,
        onError: colors.onAccent,
        surface: colors.bgElevated,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceMuted,
        surfaceContainerHigh: colors.surface,
        surfaceContainer: colors.surface,
        surfaceContainerLow: colors.bgElevated,
        surfaceContainerLowest: colors.bg,
        outline: colors.border,
        outlineVariant: colors.border,
        onSurfaceVariant: colors.textSecondary,
      ),
      textTheme: dmSans.apply(
        bodyColor: colors.textPrimary,
        displayColor: colors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlayFor(brightness),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      dividerColor: colors.border,
      cardTheme: CardThemeData(
        color: colors.bgElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(surfaceExt.cardRadius),
          side: BorderSide(color: colors.border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return colors.accent;
          return colors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return colors.accentSoft;
          return colors.surfaceMuted;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: uiStyle == UiSurfaceStyle.neo ? colors.bg : colors.bgElevated,
        elevation: uiStyle == UiSurfaceStyle.neo ? 0 : 6,
        shadowColor: colors.textPrimary.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surface,
        contentTextStyle: GoogleFonts.dmSans(color: colors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusControl),
        ),
      ),
      extensions: [colors, surfaceExt],
    );
  }

  static TextStyle timerDigits(BuildContext context, {double size = 56}) {
    final c = context.colors;
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: c.textPrimary,
      letterSpacing: 1.5,
      height: 1.0,
    );
  }

  static TextStyle display(BuildContext context, {double size = 28}) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: context.colors.textPrimary,
    );
  }
}
