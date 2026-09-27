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
import '../../habits/application/habits_notifier.dart';
import '../../habits/domain/habit.dart';
import '../../timer/application/history_notifier.dart';
import '../application/tasks_notifier.dart';
import '../domain/task.dart';

class _TaskEditorResult {
  const _TaskEditorResult.save({
    required this.title,
    required this.estimatedPomodoros,
    this.linkedHabitId,
  }) : delete = false;

  const _TaskEditorResult.delete()
      : delete = true,
        title = '',
        estimatedPomodoros = 0,
        linkedHabitId = null;

  final bool delete;
  final String title;
  final int estimatedPomodoros;
  final String? linkedHabitId;
}

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final activeId = ref.watch(activeTaskIdProvider);
    final history = ref.watch(historyProvider.notifier);
    final c = context.colors;
    final open = tasks.where((t) => !t.completed).toList();
    final done = tasks.where((t) => t.completed).toList();

    return Scaffold(
      backgroundColor: context.surfaceStyle.isGlass ? Colors.transparent : c.bg,
      appBar: AppBar(
        title: Text(
          'Görevler',
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
                    'Görev',
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
      body: tasks.isEmpty
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
                              'Açık görevler',
                              style: GoogleFonts.dmSans(
                                color: c.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${open.length}',
                              style: AppTheme.display(context, size: 28),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${done.length} tamamlandı',
                        style: GoogleFonts.dmSans(
                          color: c.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...open.map(
                  (t) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TaskRow(
                      task: t,
                      isActive: t.id == activeId,
                      completedPomos: history.focusCountForTask(t.id),
                      onToggle: () async {
                        await HapticFeedback.selectionClick();
                        await ref.read(tasksProvider.notifier).toggle(t.id);
                      },
                      onSelectActive: () async {
                        final next = activeId == t.id ? null : t.id;
                        await ref.read(activeTaskIdProvider.notifier).set(next);
                      },
                      onEdit: () => _showEditor(context, ref, existing: t),
                    ),
                  ),
                ),
                if (done.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tamamlananlar',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      color: c.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...done.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TaskRow(
                        task: t,
                        isActive: false,
                        completedPomos: history.focusCountForTask(t.id),
                        onToggle: () async {
                          await HapticFeedback.selectionClick();
                          await ref.read(tasksProvider.notifier).toggle(t.id);
                        },
                        onSelectActive: null,
                        onEdit: () => _showEditor(context, ref, existing: t),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Task? existing,
  }) async {
    final c = context.colors;
    final habits = ref.read(habitsProvider);

    final result = await showAppSheet<_TaskEditorResult>(
      context: context,
      builder: (sheetContext) {
        return _TaskEditorSheet(
          colors: c,
          existing: existing,
          habits: habits,
        );
      },
    );

    if (!context.mounted || result == null) return;

    final notifier = ref.read(tasksProvider.notifier);
    if (result.delete) {
      if (existing != null) await notifier.delete(existing.id);
      return;
    }
    if (result.title.trim().isEmpty) return;

    if (existing == null) {
      await notifier.add(
        title: result.title,
        estimatedPomodoros: result.estimatedPomodoros,
        linkedHabitId: result.linkedHabitId,
      );
    } else {
      await notifier.updateTask(
        existing.copyWith(
          title: result.title.trim(),
          estimatedPomodoros: result.estimatedPomodoros,
          linkedHabitId: result.linkedHabitId,
          clearLinkedHabitId: result.linkedHabitId == null,
        ),
      );
    }
  }
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.colors,
    required this.habits,
    this.existing,
  });

  final AppColors colors;
  final List<Habit> habits;
  final Task? existing;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late final TextEditingController _titleCtrl;
  late int _estimated;
  String? _linkedHabitId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(text: existing?.title ?? '');
    _estimated = existing?.estimatedPomodoros ?? 0;
    _linkedHabitId = existing?.linkedHabitId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _popSave() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      _TaskEditorResult.save(
        title: title,
        estimatedPomodoros: _estimated,
        linkedHabitId: _linkedHabitId,
      ),
    );
  }

  void _popDelete() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(const _TaskEditorResult.delete());
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
            existing == null ? 'Yeni görev' : 'Görevi düzenle',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
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
            'Tahmini pomodoro: $_estimated',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
          Slider(
            value: _estimated.toDouble(),
            min: 0,
            max: 20,
            divisions: 20,
            activeColor: c.accent,
            label: '$_estimated',
            onChanged: (v) => setState(() => _estimated = v.round()),
          ),
          if (widget.habits.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Bağlı alışkanlık (odak bitince işaretlenir)',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LinkChip(
                  label: 'Yok',
                  selected: _linkedHabitId == null,
                  onTap: () => setState(() => _linkedHabitId = null),
                ),
                ...widget.habits.map((h) {
                  final sel = _linkedHabitId == h.id;
                  return _LinkChip(
                    label: '${h.emoji} ${h.title}',
                    selected: sel,
                    onTap: () => setState(() => _linkedHabitId = h.id),
                  );
                }),
              ],
            ),
          ],
          const SizedBox(height: 16),
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
        padding: EdgeInsets.fromLTRB(32, 32, 32, IslandInsets.bottom(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📝', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Henüz görev yok',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Odaklanmak için bir görev ekle ve timer\'da seç.',
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
                        '+ Görev',
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

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isActive,
    required this.completedPomos,
    required this.onToggle,
    required this.onEdit,
    this.onSelectActive,
  });

  final Task task;
  final bool isActive;
  final int completedPomos;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onSelectActive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final est = task.estimatedClamped;
    final done = task.completed;

    return NeoSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onEdit,
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
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
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
                  : Icon(Icons.circle_outlined, color: c.textSecondary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
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
                  est > 0
                      ? '🍅 $completedPomos / $est'
                      : (completedPomos > 0
                          ? '🍅 $completedPomos'
                          : 'Tahmin yok'),
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onSelectActive != null)
            GestureDetector(
              onTap: onSelectActive,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: context.surfaceStyle.chipDecoration(
                  c,
                  selected: isActive,
                ),
                child: Text(
                  isActive ? 'Aktif' : 'Seç',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : c.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: context.surfaceStyle.chipDecoration(
          c,
          selected: selected,
          radius: AppTheme.radiusPill,
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}
