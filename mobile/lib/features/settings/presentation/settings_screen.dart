import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_surface_style.dart';
import '../../../core/theme/island_insets.dart';
import '../../../shared/widgets/neo_surface.dart';
import '../../timer/application/pomodoro_notifier.dart';
import '../../timer/application/settings_notifier.dart';
import '../../timer/domain/pomodoro_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: IslandInsets.listPadding(context),
        children: [
          _SectionTitle('Y\u00fczey stili'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kart ve panel dili',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kartların, butonların ve arka planın dokusu. Geçiş canlı olarak uygulanır.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final opt in _styleOptions) ...[
                        if (opt != _styleOptions.first) const SizedBox(width: 10),
                        Expanded(
                          child: _StyleChip(
                            style: opt.style,
                            label: opt.label,
                            subtitle: opt.subtitle,
                            selected: s.uiStyle == opt.style,
                            onTap: () => n.setUiStyle(opt.style),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _SectionTitle('Renk paleti'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vurgu ve mola renkleri',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Y\u00fczey stili ba\u011f\u0131ms\u0131z kal\u0131r.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final id in ColorPaletteId.values)
                        _PaletteSwatch(
                          id: id,
                          selected: s.paletteId == id,
                          onTap: () => n.setPaletteId(id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ]),

          const SizedBox(height: 20),
          _SectionTitle('S\u00fcreler'),
          _Card(children: [
            _StepperTile(
              label: 'Odak (dk)',
              value: s.focusMin,
              onChanged: (v) async {
                await n.setFocusMin(v);
                await ref.read(pomodoroProvider.notifier).syncDurationFromSettings();
              },
            ),
            _Divider(),
            _StepperTile(
              label: 'K\u0131sa mola (dk)',
              value: s.shortBreakMin,
              onChanged: (v) async {
                await n.setShortBreakMin(v);
                await ref.read(pomodoroProvider.notifier).syncDurationFromSettings();
              },
            ),
            _Divider(),
            _StepperTile(
              label: 'Uzun mola (dk)',
              value: s.longBreakMin,
              onChanged: (v) async {
                await n.setLongBreakMin(v);
                await ref.read(pomodoroProvider.notifier).syncDurationFromSettings();
              },
            ),
            _Divider(),
            _StepperTile(
              label: 'Uzun mola aral\u0131\u011f\u0131',
              value: s.longBreakEvery,
              min: 1,
              max: 12,
              onChanged: n.setLongBreakEvery,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionTitle('Davran\u0131\u015f'),
          _Card(children: [
            _SwitchTile(
              label: 'Otomatik ba\u015flat',
              subtitle: 'Faz bitince sonraki faz\u0131 ba\u015flat',
              value: s.autoStart,
              onChanged: n.setAutoStart,
            ),
            _Divider(),
            _SwitchTile(
              label: 'Ses',
              subtitle: 'Faz biti\u015finde bip',
              value: s.sound,
              onChanged: n.setSound,
            ),
            _Divider(),
            _SwitchTile(
              label: 'Bildirimler',
              subtitle: 'Arka planda faz biti\u015f uyar\u0131s\u0131',
              value: s.notifications,
              onChanged: n.setNotifications,
            ),
            _Divider(),
            _SwitchTile(
              label: 'Ekran\u0131 a\u00e7\u0131k tut',
              subtitle: 'Odak s\u0131ras\u0131nda uyku engeli',
              value: s.wakelock,
              onChanged: n.setWakelock,
            ),
          ]),
          const SizedBox(height: 20),
          _SectionTitle('G\u00f6r\u00fcn\u00fcm'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<AppThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: AppThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 18), label: Text('Sistem')),
                      ButtonSegment(value: AppThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18), label: Text('A\u00e7\u0131k')),
                      ButtonSegment(value: AppThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18), label: Text('Koyu')),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (set) => n.setThemeMode(set.first),
                    style: ButtonStyle(
                      side: WidgetStatePropertyAll(
                        BorderSide(color: c.border.withValues(alpha: 0.6)),
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return c.textSecondary;
                      }),
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return c.accent;
                        }
                        return c.surfaceMuted.withValues(alpha: 0.6);
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _SectionTitle('Hakk\u0131nda'),
          _Card(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Easy Productivity\nEasy Pomodoro companion\n\u00c7evrimd\u0131\u015f\u0131 \u00b7 hesaps\u0131z',
                style: GoogleFonts.dmSans(
                  height: 1.5,
                  color: c.textSecondary,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

const _styleOptions = <({UiSurfaceStyle style, String label, String subtitle})>[
  (style: UiSurfaceStyle.neo, label: 'Yumu\u015fak', subtitle: 'Neumorphism'),
  (style: UiSurfaceStyle.skeuo, label: 'Dokulu', subtitle: 'Skeuomorphism'),
  (style: UiSurfaceStyle.glass, label: 'Cam', subtitle: 'Glassmorphism'),
];

class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final UiSurfaceStyle style;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    final radius = BorderRadius.circular(16);
    final deco = surf.chipDecoration(c, radius: 16);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label y\u00fczey stili',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
            decoration: selected
                ? deco.copyWith(border: Border.all(color: c.accent, width: 2))
                : deco,
            child: Column(
              children: [
                _StylePreview(style: style),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Padding(
                              key: const ValueKey('on'),
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_circle_rounded, size: 15, color: c.accent),
                            )
                          : const SizedBox(key: ValueKey('off')),
                    ),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: selected ? c.accent : c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    style: GoogleFonts.dmSans(fontSize: 11, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniature scene rendered with the *target* style's real widgets, so the
/// preview always matches what the app turns into.
class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.style});

  final UiSurfaceStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final target = AppSurfaceStyle(style: style);
    return Theme(
      data: theme.copyWith(extensions: [c, target]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.bg),
              if (style == UiSurfaceStyle.glass)
                CustomPaint(painter: GlassWashPainter(c)),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
                child: Row(
                  children: [
                    Expanded(
                      child: NeoSurface(
                        blur: true,
                        borderRadius: target.cardRadius * 0.6,
                        padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Bar(width: 22, color: c.textPrimary.withValues(alpha: 0.55)),
                            _Bar(width: 14, color: c.textSecondary.withValues(alpha: 0.45)),
                            Container(
                              height: 9,
                              decoration: target.ctaDecoration(c, radius: 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: target.insetDecoration(c, radius: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 4,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.colors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return NeoSurface(
      blur: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: context.colors.border);
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SwitchListTile(
      title: Text(label, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: c.textPrimary)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: GoogleFonts.dmSans(fontSize: 13, color: c.textSecondary)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 120,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: Icon(Icons.remove_circle_outline, color: c.textSecondary),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.fraunces(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: Icon(Icons.add_circle_outline, color: c.accent),
          ),
        ],
      ),
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final ColorPaletteId id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 96,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: selected
              ? context.surfaceStyle
                  .chipDecoration(c, radius: 14)
                  .copyWith(border: Border.all(color: c.accent, width: 2))
              : context.surfaceStyle.chipDecoration(c, radius: 14),
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: id.swatch,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: id.swatch.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                id.labelTr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: selected ? c.accent : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

