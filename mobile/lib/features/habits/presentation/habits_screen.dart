import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surface_style.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/island_insets.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/neo_surface.dart';
import '../../timer/domain/session_log.dart';
import '../application/habits_notifier.dart';
import '../domain/habit.dart';

/// Result from the habit editor sheet. Mutations must run *after* the sheet
/// is fully closed — never via [WidgetRef] during [Navigator.pop].
class _HabitEditorResult {
  const _HabitEditorResult.save({
    required this.title,
    required this.emoji,
    required this.targetPerWeek,
  }) : delete = false;

  const _HabitEditorResult.delete()
      : delete = true,
        title = '',
        emoji = '',
        targetPerWeek = 0;

  final bool delete;
  final String title;
  final String emoji;
  final int targetPerWeek;
}

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = sortHabitsForToday(ref.watch(habitsProvider));
    final c = context.colors;
    final week = last7DayKeys();
    final doneToday = habits.where((h) => h.isDoneToday).length;

    return Scaffold(
      backgroundColor: context.surfaceStyle.isGlass ? Colors.transparent : c.bg,
      appBar: AppBar(
        title: Text(
          'Alışkanlıklar',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: NeoSurface(
              borderRadius: AppTheme.radiusPill,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              blur: true,
              onTap: () => _showEditor(context, ref),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: c.accent),
                  const SizedBox(width: 4),
                  Text(
                    'Alışkanlık',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: habits.isEmpty
          ? _Empty(onAdd: () => _showEditor(context, ref))
          : ListView(
              padding: IslandInsets.listPadding(context),
              children: [
                NeoSurface(
                  blur: true,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bugün',
                              style: GoogleFonts.dmSans(
                                color: c.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$doneToday / ${habits.length}',
                              style: AppTheme.display(context, size: 28),
                            ),
                          ],
                        ),
                      ),
                      _MiniRing(
                        progress: habits.isEmpty
                            ? 0
                            : doneToday / habits.length,
                        color: c.accent,
                        track: c.surfaceMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...habits.map(
                  (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HabitRow(
                      habit: h,
                      weekDays: week,
                      onToggle: () async {
                        await HapticFeedback.selectionClick();
                        await ref
                            .read(habitsProvider.notifier)
                            .toggleToday(h.id);
                      },
                      onEdit: () => _showEditor(context, ref, existing: h),
                      onDelete: () => ref
                          .read(habitsProvider.notifier)
                          .delete(h.id),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Habit? existing,
  }) async {
    // Capture theme colors from the *parent* before opening the sheet so the
    // sheet never needs parent context after it is disposed.
    final c = context.colors;

    final result = await showAppSheet<_HabitEditorResult>(
      context: context,
      builder: (sheetContext) {
        return _HabitEditorSheet(
          colors: c,
          existing: existing,
        );
      },
    );

    // Sheet route is fully dismissed here. Do not use sheet BuildContext.
    if (!context.mounted || result == null) return;

    final notifier = ref.read(habitsProvider.notifier);
    if (result.delete) {
      if (existing != null) await notifier.delete(existing.id);
      return;
    }

    if (result.title.trim().isEmpty) return;

    if (existing == null) {
      await notifier.add(
        title: result.title,
        emoji: result.emoji,
        targetPerWeek: result.targetPerWeek,
      );
    } else {
      await notifier.updateHabit(
        existing.copyWith(
          title: result.title.trim(),
          emoji: result.emoji,
          targetPerWeek: result.targetPerWeek,
        ),
      );
    }
  }
}

/// Owns [TextEditingController] and local emoji/target state so dispose is
/// tied to the sheet element lifecycle (not the parent after async gaps).
class _HabitEditorSheet extends StatefulWidget {
  const _HabitEditorSheet({
    required this.colors,
    this.existing,
  });

  final AppColors colors;
  final Habit? existing;

  @override
  State<_HabitEditorSheet> createState() => _HabitEditorSheetState();
}

class _HabitEditorSheetState extends State<_HabitEditorSheet> {
  late final TextEditingController _titleCtrl;
  late String _emoji;
  late int _target;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _emoji = existing?.emoji ?? '🎯';
    _target = existing?.targetPerWeek ?? 7;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _popSave() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    // Drop keyboard focus before pop so MediaQuery viewInsets dependents
    // are not mid-rebuild while the route InheritedWidgets unmount.
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      _HabitEditorResult.save(
        title: title,
        emoji: _emoji,
        targetPerWeek: _target,
      ),
    );
  }

  void _popDelete() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(const _HabitEditorResult.delete());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final existing = widget.existing;

    return Padding(
      padding: appSheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSheetHandle(),
          const SizedBox(height: 16),
          Text(
            existing == null ? 'Yeni alışkanlık' : 'Düzenle',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: habitEmojis.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final e = habitEmojis[i];
                final sel = e == _emoji;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: sel
                        ? BoxDecoration(
                            color: c.accentSoft,
                            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                          )
                        : context.surfaceStyle.insetDecoration(
                            c,
                            radius: AppTheme.radiusControl,
                          ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: existing == null,
            style: GoogleFonts.dmSans(color: c.textPrimary),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _popSave(),
            decoration: InputDecoration(
              hintText: 'Başlık',
              filled: true,
              fillColor: c.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Haftalık hedef: $_target',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          Slider(
            value: _target.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            activeColor: c.accent,
            label: '$_target',
            onChanged: (v) => setState(() => _target = v.round()),
          ),
          const SizedBox(height: 8),
          AppCtaButton(
            label: existing == null ? 'Ekle' : 'Kaydet',
            onPressed: _popSave,
          ),
          if (existing != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _popDelete,
              child: Text(
                'Sil',
                style: GoogleFonts.dmSans(color: c.danger),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌱', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Henüz alışkanlık yok',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Küçük adımlarla günlük ritmini kur.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(
                  context.surfaceStyle.controlRadius,
                ),
                child: Ink(
                  decoration: context.surfaceStyle.ctaDecoration(c),
                  child: SizedBox(
                    width: 180,
                    height: 48,
                    child: Center(
                      child: Text(
                        '+ Alışkanlık',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          color: c.onAccent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.weekDays,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final List<String> weekDays;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final streak = habit.currentStreak();
    final weekDone = habit.weeklyDone(weekDays);
    final done = habit.isDoneToday;

    return NeoSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onEdit,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedScale(
              scale: done ? 1.0 : 0.96,
              duration: const Duration(milliseconds: 160),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: done
                  ? context.surfaceStyle.ctaDecoration(
                      c,
                      radius: AppTheme.radiusControl,
                    )
                  : context.surfaceStyle.insetDecoration(
                      c,
                      radius: AppTheme.radiusControl,
                    ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 24)
                    : Text(habit.emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: c.textPrimary,
                    decoration: done ? TextDecoration.lineThrough : null,
                    decorationColor: c.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak > 0
                      ? '🔥 $streak gün · hafta $weekDone/${habit.weekTarget}'
                      : 'Hafta $weekDone/${habit.weekTarget} · en iyi ${habit.bestStreak()}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                _WeekDots(habit: habit, weekDays: weekDays),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRing extends StatelessWidget {
  const _MiniRing({
    required this.progress,
    required this.color,
    required this.track,
  });
  final double progress;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: CircularProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        strokeWidth: 5,
        backgroundColor: track,
        color: color,
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.habit, required this.weekDays});
  final Habit habit;
  final List<String> weekDays;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final surf = context.surfaceStyle;
    return Row(
      children: [
        for (final day in weekDays)
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              width: 12,
              height: 12,
              decoration: habit.isDoneOn(day)
                  ? surf.ctaDecoration(c, radius: 6)
                  : surf.insetDecoration(c, radius: 6),
            ),
          ),
      ],
    );
  }
}
