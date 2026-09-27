import 'dart:ui';

import 'package:flutter/material.dart';

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
    final r = surf.sheetRadius;
    final allowBlur =
        surf.isGlass && AppSurfaceStyle.glassBlurEnabled(context);
    final deco = surf.sheetDecoration(
      c,
      blurPanel: true,
      opaqueFallback: surf.isGlass && !allowBlur,
    );
    final shadows = deco.boxShadow;
    final fill = deco.copyWith(boxShadow: const <BoxShadow>[]);

    Widget body = Container(
      width: double.infinity,
      decoration: fill,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );

    if (surf.isGlass && allowBlur) {
      body = ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: surf.glassSheetSigma,
            sigmaY: surf.glassSheetSigma,
          ),
          child: body,
        ),
      );
    } else {
      body = ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
        child: body,
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(r)),
          boxShadow: shadows,
        ),
        child: body,
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
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    final r = surf.controlRadius;
    final deco = surf.ctaDecoration(c, color: color, radius: r);
    final fill = deco.copyWith(boxShadow: const <BoxShadow>[]);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        boxShadow: deco.boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(r),
          child: Ink(
            decoration: fill,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: c.onAccent,
                  fontSize: 15,
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
/// Glass: frost chip (σ14) + hairline; textPrimary for readability.
class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 48,
  });

  final String label;
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
    final r = surf.controlRadius;
    final allowBlur =
        surf.isGlass && AppSurfaceStyle.glassBlurEnabled(context);
    final deco = surf.secondaryDecoration(
      c,
      radius: r,
      pressed: _pressed,
      opaqueFallback: surf.isGlass && !allowBlur,
    );
    final labelColor = surf.isGlass ? c.textPrimary : c.textSecondary;

    Widget ink = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(r),
        child: Ink(
          height: widget.height,
          decoration: deco.copyWith(
            boxShadow: const <BoxShadow>[],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: labelColor,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );

    if (surf.isGlass && allowBlur) {
      ink = ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: surf.glassChipSigma,
            sigmaY: surf.glassChipSigma,
          ),
          child: ink,
        ),
      );
    }

    return ink;
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
