import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/habits_model.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitsModel = context.watch<HabitsModel>();
    final habits = habitsModel.habits;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Habits'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade900,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHabitSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New habit'),
      ),
      body: SafeArea(
        child: habitsModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _DashboardHeader(model: habitsModel),
                  Expanded(
                    child: habits.isEmpty
                        ? _EmptyState(onAdd: () => _showHabitSheet(context))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: habits.length,
                            itemBuilder: (context, index) {
                              final habit = habits[index];
                              return _HabitCard(
                                habit: habit,
                                onToggle: () => habitsModel
                                    .toggleCompletionForToday(habit.id),
                                onEdit: () => _showHabitSheet(
                                  context,
                                  existing: habit,
                                ),
                                onDelete: () => _confirmDelete(
                                  context,
                                  habit.id,
                                  habit.name,
                                ),
                                onReset: () =>
                                    habitsModel.resetCompletions(habit.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete habit'),
          content: Text('Delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                dialogContext.read<HabitsModel>().deleteHabit(id);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showHabitSheet(BuildContext context, {Habit? existing}) async {
    final result = await showModalBottomSheet<_HabitFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _HabitFormSheet(existing: existing);
      },
    );

    if (result == null) return;
    final model = context.read<HabitsModel>();
    if (existing == null) {
      await model.addHabit(
        name: result.name,
        targetPerWeek: result.targetPerWeek,
        colorValue: result.colorValue,
      );
    } else {
      await model.updateHabit(
        existing.id,
        name: result.name,
        targetPerWeek: result.targetPerWeek,
        colorValue: result.colorValue,
      );
    }
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.model});

  final HabitsModel model;

  @override
  Widget build(BuildContext context) {
    final total = model.habits.length;
    final todayDone = model.completedTodayCount;
    final todayProgress = total == 0 ? 0.0 : todayDone / total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF4DB6AC)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '$todayDone of $total done',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: todayProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white30,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Last 7 days',
                  value: '${model.totalCheckInsLast7Days}',
                  helper: 'check-ins',
                  icon: Icons.calendar_month,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Avg progress',
                  value: '${(model.averageWeeklyProgress * 100).round()}%',
                  helper: 'week goals',
                  icon: Icons.show_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Best streak',
                  value: '${model.longestStreak}',
                  helper: 'days',
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
  });

  final String title;
  final String value;
  final String helper;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.grey.shade800, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onReset,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final accent = Color(habit.colorValue);
    final isDoneToday = habit.isCompletedOn(DateTime.now());
    final thisWeek = habit.completionsWithinDays(7);
    final weeklyProgress =
        (thisWeek / habit.targetPerWeek).clamp(0, 1).toDouble();
    final days = List.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDoneToday ? Icons.check : Icons.flag,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      'Streak ${habit.streak} | ${habit.targetPerWeek}/week',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                style: IconButton.styleFrom(
                  backgroundColor:
                      isDoneToday ? accent.withOpacity(0.18) : Colors.grey[200],
                ),
                icon: Icon(
                  isDoneToday
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: accent,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'reset':
                      onReset();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit habit'),
                  ),
                  PopupMenuItem(
                    value: 'reset',
                    child: Text('Reset completions'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: weeklyProgress,
              minHeight: 8,
              color: accent,
              backgroundColor: accent.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week: $thisWeek/${habit.targetPerWeek}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
              ),
              Text(
                habit.isCompletedOn(DateTime.now())
                    ? 'Completed today'
                    : 'Tap to complete',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDoneToday ? accent : Colors.grey.shade600,
                      fontWeight:
                          isDoneToday ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: days
                .map(
                  (day) => Expanded(
                    child: _DayPill(
                      label: _weekdayLabel(day),
                      isDone: habit.isCompletedOn(day),
                      isToday: _isSameDay(day, DateTime.now()),
                      color: accent,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.isDone,
    required this.isToday,
    required this.color,
  });

  final String label;
  final bool isDone;
  final bool isToday;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDone ? color.withOpacity(0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday ? color.withOpacity(0.4) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDone ? color.darken() : Colors.grey.shade700,
                ),
          ),
          const SizedBox(height: 2),
          Icon(
            isDone ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isDone ? color : Colors.grey.shade500,
          ),
        ],
      ),
    );
  }
}

class _HabitFormSheet extends StatefulWidget {
  const _HabitFormSheet({this.existing});

  final Habit? existing;

  @override
  State<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<_HabitFormSheet> {
  late final TextEditingController _controller;
  late int _targetPerWeek;
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.name ?? '');
    _targetPerWeek = widget.existing?.targetPerWeek ?? 7;
    _colorValue = widget.existing?.colorValue ?? HabitsModel.palette.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              widget.existing == null ? 'Create habit' : 'Edit habit',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Drink 2L of water',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Weekly target: $_targetPerWeek days',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Slider(
              value: _targetPerWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              label: '$_targetPerWeek',
              onChanged: (value) {
                setState(() {
                  _targetPerWeek = value.round();
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: HabitsModel.palette
                  .map(
                    (color) => GestureDetector(
                      onTap: () => setState(() => _colorValue = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorValue == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _colorValue == color
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      Navigator.of(context).pop(
                        _HabitFormResult(
                          name: text,
                          targetPerWeek: _targetPerWeek,
                          colorValue: _colorValue,
                        ),
                      );
                    },
                    child: Text(widget.existing == null ? 'Add' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitFormResult {
  _HabitFormResult({
    required this.name,
    required this.targetPerWeek,
    required this.colorValue,
  });

  final String name;
  final int targetPerWeek;
  final int colorValue;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.spa_outlined, size: 64, color: Colors.teal),
            const SizedBox(height: 12),
            Text(
              'Start a new ritual',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first habit and track your streaks.\nTap the button below to begin.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add habit'),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekdayLabel(DateTime date) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[date.weekday - 1];
}

extension _ColorHelpers on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final lowered = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return lowered.toColor();
  }
}
