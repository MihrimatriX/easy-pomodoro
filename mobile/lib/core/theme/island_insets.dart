import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Clearance below scrollable content so the floating island + FAB never cover CTAs.
class IslandInsets {
  IslandInsets._();

  /// Bottom padding for ListView / Column bodies under [extendBody] scaffold.
  /// Uses device viewPadding (not the shell-injected MediaQuery.padding).
  static double bottom(BuildContext context) {
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    final island = math.max(
      AppTheme.floatingNavHeight,
      AppTheme.floatingFabSize,
    );
    // island + gap under island + safe + extra CTA clearance
    return island + AppTheme.floatingNavGap + math.max(safe, 8.0) + 16.0;
  }

  /// Sheet / modal bottom padding: keyboard viewInsets + island clearance.
  static double sheetBottom(BuildContext context) {
    return MediaQuery.viewInsetsOf(context).bottom + bottom(context);
  }

  static EdgeInsets listPadding(
    BuildContext context, {
    double horizontal = AppTheme.pagePaddingH,
    double top = 8,
  }) {
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom(context));
  }
}