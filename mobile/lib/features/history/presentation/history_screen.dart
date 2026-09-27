import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_surface_style.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/island_insets.dart';
import '../../../shared/widgets/neo_surface.dart';
import '../../habits/application/habits_notifier.dart';
import '../../tasks/application/tasks_notifier.dart';
import '../../timer/application/history_notifier.dart';
import '../../timer/domain/pomodoro_phase.dart';
import '../../timer/domain/session_log.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(historyProvider);
    final history = ref.read(historyProvider.notifier);
    final tasks = ref.watch(tasksProvider);
    final habits = ref.watch(habitsProvider);
    final c = context.colors;

    final todayCount = history.todayFocusCount();
    final todayMins = history.todayFocusMinutes();
    final habitsDone = habits.where((h) => h.isDoneToday).length;
    final habitsTotal = habits.length;
    final week = history.last7FocusCounts();
    final maxBar = week.values.fold<int>(1, (a, b) => a > b ? a : b);

    String? taskTitle(String? id) {
      if (id == null) return null;
      for (final t in tasks) {
        if (t.id == id) return t.title;
      }
      return null;
    }

    return Scaffold(
      backgroundColor: context.surfaceStyle.isGlass ? Colors.transparent : c.bg,
      appBar: AppBar(title: const Text('Geçmiş')),
      body: ListView(
        padding: IslandInsets.listPadding(context),
        children: [
          NeoSurface(
            blur: true,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bugün',
                  style: GoogleFonts.dmSans(fontSize: 14, color: c.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(value: '$todayCount', label: 'odak'),
                    ),
                    Expanded(
                      child: _StatCell(value: '$todayMins', label: 'dk'),
                    ),
                    Expanded(
                      child: _StatCell(
                        value: habitsTotal == 0
                            ? '—'
                            : '$habitsDone/$habitsTotal',
                        label: 'alışkanlık',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Son 7 gün',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          NeoSurface(
            blur: true,
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: SizedBox(
              height: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: week.entries.map((e) {
                  final h = (e.value / maxBar) * 72;
                  final dayLabel =
                      DateFormat('E', 'tr').format(DateTime.parse(e.key));
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${e.value}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: c.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: h.clamp(4, 80),
                          width: 18,
                          decoration: BoxDecoration(
                            color: e.value > 0 ? c.accent : c.surfaceMuted,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusControl),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Oturumlar',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Henüz tamamlanan odak yok.',
                  style: GoogleFonts.dmSans(color: c.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ...logs.take(50).map(
                  (log) => _SessionTile(
                    log: log,
                    taskTitle: taskTitle(log.taskId),
                  ),
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        Text(value, style: AppTheme.display(context, size: 26)),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.dmSans(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.log, this.taskTitle});
  final SessionLog log;
  final String? taskTitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final time = DateFormat('d MMM · HH:mm', 'tr').format(log.completedAt);
    final mins = (log.durationSec / 60).round();
    final phaseLabel = switch (log.phase) {
      PomodoroPhase.focus => 'Odak',
      PomodoroPhase.shortBreak => 'Kısa mola',
      PomodoroPhase.longBreak => 'Uzun mola',
    };
    final title = taskTitle == null || taskTitle!.isEmpty
        ? '$phaseLabel · $mins dk'
        : '$phaseLabel · $mins dk · $taskTitle';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NeoSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: context.surfaceStyle.insetDecoration(
                c,
                radius: AppTheme.radiusControl,
              ),
              child: Icon(Icons.check_rounded, color: c.accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
