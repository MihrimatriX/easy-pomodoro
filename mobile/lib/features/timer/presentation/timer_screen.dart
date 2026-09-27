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
import '../../../shared/widgets/progress_ring.dart';
import '../../habits/application/habits_notifier.dart';
import '../../habits/domain/habit.dart';
import '../../tasks/application/tasks_notifier.dart';
import '../../tasks/domain/task.dart';
import '../application/pomodoro_notifier.dart';
import '../application/settings_notifier.dart';
import '../domain/pomodoro_phase.dart';
import '../domain/timer_status.dart';
import 'widgets/phase_chip.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  bool _habitSheetOpen = false;

  String _fmt(int totalSeconds) {
    final s = totalSeconds.clamp(0, 99999);
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmReset() async {
    final c = context.colors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sıfırla', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
          'Sayacı başa almak istediğine emin misin?',
          style: GoogleFonts.dmSans(color: c.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Vazgeç', style: GoogleFonts.dmSans(color: c.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sıfırla', style: GoogleFonts.dmSans(color: c.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(pomodoroProvider.notifier).reset(confirmed: true);
    }
  }

  Future<void> _pickActiveTask() async {
    final c = context.colors;
    final tasks = ref.read(tasksProvider).where((t) => !t.completed).toList();
    final activeId = ref.read(activeTaskIdProvider);

    final picked = await showAppSheet<String?>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: appSheetPadding(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSheetHandle(),
                const SizedBox(height: 16),
                Text(
                  'Aktif görev',
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    activeId == null ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: activeId == null ? c.accent : c.textSecondary,
                  ),
                  title: Text(
                    'Görev yok',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, ''),
                ),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Önce Görevler sekmesinden bir görev ekle.',
                      style: GoogleFonts.dmSans(color: c.textSecondary),
                    ),
                  )
                else
                  ...tasks.map(
                    (t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        activeId == t.id
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: activeId == t.id ? c.accent : c.textSecondary,
                      ),
                      title: Text(
                        t.title,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, t.id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    await ref.read(activeTaskIdProvider.notifier).set(
          picked.isEmpty ? null : picked,
        );
  }

  Future<void> _offerHabitCheckIn() async {
    if (_habitSheetOpen || !mounted) return;
    final habits = sortHabitsForToday(ref.read(habitsProvider));
    final incomplete = habits.where((h) => !h.isDoneToday).toList();
    ref.read(pendingHabitPromptProvider.notifier).clear();
    if (incomplete.isEmpty) return;

    _habitSheetOpen = true;
    final c = context.colors;
    try {
      final chosen = await showAppSheet<String>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: appSheetPadding(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSheetHandle(),
                  const SizedBox(height: 16),
                  Text(
                    'Bugün hangi alışkanlığı işaretle?',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Odak tamamlandı — isteğe bağlı',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(ctx).height * 0.4,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: incomplete
                          .map(
                            (h) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Text(h.emoji, style: const TextStyle(fontSize: 22)),
                              title: Text(
                                h.title,
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w600,
                                  color: c.textPrimary,
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx, h.id),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Atla',
                      style: GoogleFonts.dmSans(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (!mounted) return;
      if (chosen != null && chosen.isNotEmpty) {
        await HapticFeedback.selectionClick();
        await ref.read(habitsProvider.notifier).toggleToday(chosen);
      }
    } finally {
      _habitSheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pomodoroProvider);
    final settings = ref.watch(settingsProvider);
    final activeId = ref.watch(activeTaskIdProvider);
    final tasks = ref.watch(tasksProvider);
    Task? activeTask;
    for (final t in tasks) {
      if (t.id == activeId) {
        activeTask = t;
        break;
      }
    }

    ref.listen<bool>(pendingHabitPromptProvider, (prev, next) {
      if (next == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _offerHabitCheckIn();
        });
      }
    });

    ref.watch(timerTickProvider);
    final now = DateTime.now();
    final remaining = session.remainingAt(now);
    final progress = session.progressAt(now);

    if (session.isRunning && remaining <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pomodoroProvider.notifier).reconcile();
      });
    }

    final c = context.colors;
    final phaseColor = session.phase.isBreak ? c.breakColor : c.accent;
    final round = ref.read(pomodoroProvider.notifier).displayRound(settings);
    final interval = settings.longBreakEvery;

    String ctaLabel;
    switch (session.status) {
      case TimerStatus.idle:
        ctaLabel = 'Başlat';
      case TimerStatus.running:
        ctaLabel = 'Duraklat';
      case TimerStatus.paused:
        ctaLabel = 'Devam';
    }

    return Scaffold(
      backgroundColor: context.surfaceStyle.isGlass ? Colors.transparent : c.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppTheme.pagePaddingH,
            0,
            AppTheme.pagePaddingH,
            IslandInsets.bottom(context),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              NeoSurface(
                borderRadius: AppTheme.radiusPill,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                blur: true,
                blurSigma: context.surfaceStyle.glassChipSigma,
                child: Text(
                  'Tur $round / $interval',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              PhaseChip(phase: session.phase),
              const SizedBox(height: 12),
              _ActiveTaskChip(
                task: activeTask,
                onTap: _pickActiveTask,
              ),
              const Spacer(flex: 2),
              ProgressRing(
                progress: progress,
                color: phaseColor,
                trackColor: c.surfaceMuted,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmt(remaining), style: AppTheme.timerDigits(context)),
                    const SizedBox(height: 8),
                    Text(
                      session.phase.microcopyTr,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Builder(
                  builder: (ctx) {
                    final r = ctx.surfaceStyle.controlRadius;
                    final deco = ctx.surfaceStyle.ctaDecoration(
                      c,
                      color: phaseColor,
                    );
                    final fill = deco.copyWith(boxShadow: const <BoxShadow>[]);
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(r),
                        boxShadow: deco.boxShadow,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final n = ref.read(pomodoroProvider.notifier);
                            if (session.isRunning) {
                              await n.pause();
                            } else {
                              await n.start();
                            }
                          },
                          borderRadius: BorderRadius.circular(r),
                          child: Ink(
                            decoration: fill,
                            child: Center(
                              child: Text(
                                ctaLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: c.onAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Atla',
                      onPressed: () =>
                          ref.read(pomodoroProvider.notifier).skip(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Sıfırla',
                      onPressed: _confirmReset,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveTaskChip extends StatelessWidget {
  const _ActiveTaskChip({required this.task, required this.onTap});

  final Task? task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return NeoSurface(
      borderRadius: AppTheme.radiusPill,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      blur: true,
      blurSigma: context.surfaceStyle.glassChipSigma,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            task == null ? Icons.add_task_rounded : Icons.flag_rounded,
            size: 18,
            color: c.accent,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              task?.title ?? 'Görev seç',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: task == null ? c.textSecondary : c.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.expand_more_rounded, size: 18, color: c.textSecondary),
        ],
      ),
    );
  }
}

