import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_surface_style.dart';

/// Style-aware surface — neo dual shadows / skeuo gradient / glass frost.
///
/// The widget tree is identical for every style (shadows → [SurfaceBlur] →
/// fill → ink), so a theme animation morphs the surface without remounting
/// its child. Shadows sit outside the clip so they are never cut off.
/// Pressed (when [onTap] set): muted fill + halved shadows (inset-ish).
class NeoSurface extends StatefulWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.blur = false,
    this.blurSigma,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;

  /// When true and style is glass, frost the backdrop (chips / key cards).
  final bool blur;

  /// Override blur sigma (defaults to [AppSurfaceStyle.glassCardSigma]).
  final double? blurSigma;

  @override
  State<NeoSurface> createState() => _NeoSurfaceState();
}

class _NeoSurfaceState extends State<NeoSurface> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null) return;
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    final radius = BorderRadius.circular(widget.borderRadius ?? surf.cardRadius);
    final blurAllowed = AppSurfaceStyle.glassBlurEnabled(context);
    final deco = surf.cardDecoration(
      c,
      radius: radius.topLeft.x,
      blurPanel: widget.blur && blurAllowed,
      pressed: _pressed,
      opaqueFallback: widget.blur && !blurAllowed,
    );

    Widget body = Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: widget.child,
    );

    body = Material(
      type: MaterialType.transparency,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: widget.onTap == null
          ? body
          : InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              borderRadius: radius,
              splashColor: c.accent.withValues(alpha: 0.12),
              highlightColor: c.accent.withValues(alpha: 0.06),
              child: body,
            ),
    );

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: deco.boxShadow,
      ),
      child: SurfaceBlur(
        enabled: widget.blur,
        borderRadius: radius,
        sigma: widget.blurSigma,
        child: DecoratedBox(
          decoration: deco.copyWith(boxShadow: const <BoxShadow>[]),
          child: body,
        ),
      ),
    );
  }
}
