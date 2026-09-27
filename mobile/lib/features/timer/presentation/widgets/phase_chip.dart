import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_surface_style.dart';
import '../../../../shared/widgets/neo_surface.dart';
import '../../domain/pomodoro_phase.dart';

class PhaseChip extends StatelessWidget {
  const PhaseChip({super.key, required this.phase});

  final PomodoroPhase phase;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isBreak = phase.isBreak;
    final fg = isBreak ? c.breakColor : c.accent;

    return NeoSurface(
      borderRadius: AppTheme.radiusPill,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      blur: true,
      blurSigma: context.surfaceStyle.glassChipSigma,
      child: Text(
        phase.labelTr,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: fg,
        ),
      ),
    );
  }
}
