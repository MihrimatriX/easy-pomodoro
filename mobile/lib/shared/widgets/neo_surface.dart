import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_surface_style.dart';

/// Style-aware surface — neo dual shadows / skeuo gradient / glass frost.
///
/// Fill + shadows share one [BoxDecoration] (non-glass) so extrusion always
/// paints. Glass keeps shadows outside [ClipRRect]/[BackdropFilter].
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

  /// When true and style is glass, wrap with BackdropFilter (chips / key cards).
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
    final radius = widget.borderRadius ?? surf.cardRadius;
    final allowBlur =
        surf.isGlass && widget.blur && AppSurfaceStyle.glassBlurEnabled(context);
    final deco = surf.cardDecoration(
      c,
      radius: radius,
      blurPanel: allowBlur,
      pressed: _pressed,
      opaqueFallback: surf.isGlass && widget.blur && !allowBlur,
    );

    Widget body = Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: widget.child,
    );

    if (widget.onTap != null) {
      body = Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: BorderRadius.circular(radius),
          splashColor: c.accent.withValues(alpha: 0.12),
          highlightColor: c.accent.withValues(alpha: 0.06),
          child: body,
        ),
      );
    } else {
      body = Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: body,
      );
    }

    if (allowBlur) {
      final shadows = deco.boxShadow;
      final fillDeco = deco.copyWith(boxShadow: const <BoxShadow>[]);
      final sigma = widget.blurSigma ?? surf.glassCardSigma;
      Widget panel = DecoratedBox(decoration: fillDeco, child: body);
      panel = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: panel,
        ),
      );
      return Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: const Color(0x00FFFFFF),
          boxShadow: shadows,
        ),
        child: panel,
      );
    }

    return Container(
      margin: widget.margin,
      decoration: deco,
      child: body,
    );
  }
}
