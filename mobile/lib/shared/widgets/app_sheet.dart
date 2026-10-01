import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_surface_style.dart';
import '../../core/theme/island_insets.dart';

/// Style-aware modal sheet — neo dual / skeuo gradient / glass frost panel.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (sheetContext) {
      return AppSheetFrame(
        child: builder(sheetContext),
      );
    },
  );
}

/// Outer chrome for bottom sheets (and reusable dialog panels).
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    final radius = BorderRadius.vertical(top: Radius.circular(surf.sheetRadius));
    final deco = surf.sheetDecoration(
      c,
      opaqueFallback: !AppSurfaceStyle.glassBlurEnabled(context),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: deco.boxShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: SurfaceBlur(
            borderRadius: radius,
            sigma: surf.glassSheetSigma,
            child: Container(
              width: double.infinity,
              decoration: deco.copyWith(boxShadow: const <BoxShadow>[]),
              child: Material(
                type: MaterialType.transparency,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Drag handle used at the top of sheets.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: c.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Primary CTA filled with [AppSurfaceStyle.ctaDecoration].
class AppCtaButton extends StatelessWidget {
  const AppCtaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.height = 52,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    final radius = BorderRadius.circular(surf.controlRadius);
    final deco = surf.ctaDecoration(c, color: color, radius: radius.topLeft.x);
    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: deco.boxShadow),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          splashColor: c.onAccent.withValues(alpha: 0.18),
          highlightColor: c.onAccent.withValues(alpha: 0.08),
          child: Ink(
            decoration: deco.copyWith(boxShadow: const <BoxShadow>[]),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: c.onAccent,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary raised control (Skip / Reset) via [secondaryDecoration].
/// Glass: frost chip (σ15) + hairline; textPrimary for readability.
class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    final radius = BorderRadius.circular(surf.controlRadius);
    final deco = surf.secondaryDecoration(
      c,
      radius: radius.topLeft.x,
      pressed: _pressed,
      opaqueFallback: !AppSurfaceStyle.glassBlurEnabled(context),
    );
    final labelColor = Color.lerp(
      c.textSecondary,
      c.textPrimary,
      surf.glassWeight,
    )!;

    // Shadows live outside the clip — the neo extrusion used to be dropped
    // here, leaving Skip / Reset invisible on the cream background.
    return Container(
      height: widget.height,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: deco.boxShadow),
      child: SurfaceBlur(
        borderRadius: radius,
        sigma: surf.glassChipSigma,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: radius,
            child: Ink(
              decoration: deco.copyWith(boxShadow: const <BoxShadow>[]),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: labelColor),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience padding for sheet bodies.
EdgeInsets appSheetPadding(BuildContext context) {
  return EdgeInsets.fromLTRB(
    20,
    16,
    20,
    20 + IslandInsets.sheetBottom(context),
  );
}
