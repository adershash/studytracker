import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'planner_provider.dart';
import '../../subjects/presentation/subjects_provider.dart';
import '../../subjects/domain/subject.dart';

class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  /// Calculate today's day number (1–7) from the cycle start date.
  int _todayDayNumber(DateTime? cycleStartDate) {
    if (cycleStartDate == null) return 1;
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final start = DateTime(cycleStartDate.year, cycleStartDate.month, cycleStartDate.day);
    final diff = today.difference(start).inDays;
    return (diff % 7) + 1; // 1-based
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plannerState = ref.watch(plannerProvider);
    final subjectsState = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Auto Distribute',
            onPressed: () {
              _showAutoDistributeDialog(context, ref, subjectsState);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Plan',
            onPressed: () {
              ref.read(plannerProvider.notifier).clearPlan();
            },
          )
        ],
      ),
      body: plannerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (state) {
          if (state.tasksByDayNumber.isEmpty) {
            return _buildEmptyState(context, ref, subjectsState);
          }
          return _buildWeeklyPlan(context, ref, state, subjectsState);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, AsyncValue<List<Subject>> subjectsState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'Your cycle is waiting.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first study plan.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAutoDistributeDialog(context, ref, subjectsState);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Auto Distribute'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlan(BuildContext context, WidgetRef ref, WeeklyPlanState state, AsyncValue<List<Subject>> subjectsState) {
    final todayDayNum = _todayDayNumber(state.plan?.cycleStartDate);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final dayNumber = index + 1; // 1 to 7
        final tasks = state.tasksByDayNumber[dayNumber] ?? [];
        final isToday = dayNumber == todayDayNum;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isToday
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'DAY $dayNumber',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primary : AppColors.textSecondary,
                            letterSpacing: 1.2,
                            fontSize: isToday ? 16 : 14,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'TODAY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () => _showAddManualTaskDialog(context, ref, dayNumber, subjectsState),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (tasks.isEmpty)
                  const Text('No subjects planned.', style: TextStyle(color: AppColors.textDisabled))
                else
                  ...tasks.map((task) {
                    final subjectOpt = subjectsState.value?.where((s) => s.id == task.subjectId).firstOrNull;
                    if (subjectOpt == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(int.parse(subjectOpt.accentColor.replaceAll('#', '0xFF'))),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subjectOpt.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.error),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref.read(plannerProvider.notifier).deleteTask(task.id);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAutoDistributeDialog(BuildContext context, WidgetRef ref, AsyncValue<List<Subject>> subjectsState) {
    if (subjectsState.value == null || subjectsState.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add subjects first!')));
      return;
    }

    int subjectsPerDay = 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Auto Distribute'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How many subjects do you want to study each day?'),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: subjectsPerDay > 1 ? () => setState(() => subjectsPerDay--) : null,
                      ),
                      Text(
                        '$subjectsPerDay',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: subjectsPerDay < 10 ? () => setState(() => subjectsPerDay++) : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final subjects = subjectsState.value!;
                    final activeSubjects = subjects.where((s) => s.isActive).toList();

                    ref.read(plannerProvider.notifier).autoDistribute(activeSubjects, subjectsPerDay);
                    Navigator.pop(context);
                  },
                  child: const Text('Generate Plan'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showAddManualTaskDialog(BuildContext context, WidgetRef ref, int dayNumber, AsyncValue<List<Subject>> subjectsState) {
    if (subjectsState.value == null || subjectsState.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add subjects first!')));
      return;
    }

    final activeSubjects = subjectsState.value!.where((s) => s.isActive).toList();
    if (activeSubjects.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Subject for Day $dayNumber'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: activeSubjects.length,
              itemBuilder: (context, index) {
                final subject = activeSubjects[index];
                return ListTile(
                  leading: Container(
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: Color(int.parse(subject.accentColor.replaceAll('#', '0xFF'))),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(subject.name),
                  onTap: () {
                    ref.read(plannerProvider.notifier).addManualTask(subject, dayNumber);
                    Navigator.pop(context);
                  },
                );
              }
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
