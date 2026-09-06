import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../planner/presentation/planner_provider.dart';
import '../../subjects/presentation/subjects_provider.dart';
import '../../study/presentation/study_provider.dart';
import '../../planner/domain/planned_task.dart';
import '../../subjects/domain/subject.dart';
import '../../revisions/presentation/revisions_provider.dart';
import '../../activity/presentation/activity_provider.dart';
import '../../statistics/presentation/statistics_provider.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final DateTime _today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  Widget build(BuildContext context) {
    final plannerState = ref.watch(plannerProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final studyState = ref.watch(todayStudyProvider);
    final revisionsState = ref.watch(todayRevisionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: plannerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (planData) {
          // Calculate today's day number in the 7-day cycle
          int todayDayNumber = 1;
          if (planData.plan != null) {
            final cycleStart = planData.plan!.cycleStartDate;
            final start = DateTime(cycleStart.year, cycleStart.month, cycleStart.day);
            final diff = _today.difference(start).inDays;
            todayDayNumber = (diff % 7) + 1;
          }
          final tasksToday = planData.tasksByDayNumber[todayDayNumber] ?? [];
          final subjects = subjectsState.value ?? [];
          final completedSessions = studyState.value ?? [];
          final pendingRevisions = revisionsState.value ?? [];

          if (tasksToday.isEmpty && completedSessions.isEmpty && pendingRevisions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildProgressSection(tasksToday, completedSessions),
              const SizedBox(height: 24),
              const Text('PLANNED FOR TODAY', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              ...tasksToday.map((task) => _buildTaskCard(task, subjects, completedSessions)),
              
              if (pendingRevisions.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('REVISIONS DUE', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...pendingRevisions.map((revWithTopic) => _buildRevisionCard(revWithTopic, subjects)),
              ],

              if (completedSessions.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text('COMPLETED TODAY', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                ...completedSessions.map((session) => _buildSessionCard(session, subjects)),
              ]
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLogStudySheet(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Log Study'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('No tasks planned for today!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Take a break, or log an extra study session.', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildProgressSection(List<PlannedTask> tasks, List<dynamic> completedSessions) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    final completedTasksCount = tasks.where((t) => t.isCompleted).length;
    final progress = completedTasksCount / tasks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Daily Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('$completedTasksCount/${tasks.length}', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            color: AppColors.primary,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(PlannedTask task, List<Subject> subjects, List<dynamic> completedSessions) {
    if (task.isCompleted) return const SizedBox.shrink(); // Don't show in planned if completed
    
    final subject = subjects.firstWhere(
      (s) => s.id == task.subjectId, 
      orElse: () => Subject(
        id: '', 
        name: 'Unknown', 
        accentColor: '0xFFFFFF', 
        icon: 'book',
        isActive: false, 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );
    final color = Color(int.parse(subject.accentColor.replaceAll('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.book, color: color),
        ),
        title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: const Text('Tap to log study topics'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          color: AppColors.primary,
          onPressed: () => _showLogStudySheet(context, task),
        ),
        onTap: () => _showLogStudySheet(context, task),
      ),
    );
  }

  Widget _buildSessionCard(dynamic session, List<Subject> subjects) {
    final subject = subjects.firstWhere(
      (s) => s.id == session.subjectId, 
      orElse: () => Subject(
        id: '', 
        name: 'Unknown', 
        accentColor: '0xFFFFFF', 
        icon: 'book',
        isActive: false, 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );
    final color = Color(int.parse(subject.accentColor.replaceAll('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface.withValues(alpha: 0.5),
      child: ListTile(
        leading: Icon(Icons.check_circle, color: color),
        title: Text(subject.name, style: const TextStyle(decoration: TextDecoration.lineThrough)),
        subtitle: Text('Logged at ${DateFormat('HH:mm').format(session.completedAt ?? session.createdAt)}'),
      ),
    );
  }

  Widget _buildRevisionCard(RevisionWithTopic revWithTopic, List<Subject> subjects) {
    final subject = subjects.firstWhere(
      (s) => s.id == revWithTopic.topic.subjectId, 
      orElse: () => Subject(
        id: '', 
        name: 'Unknown', 
        accentColor: '0xFFFFFF', 
        icon: 'book',
        isActive: false, 
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );
    final color = Color(int.parse(subject.accentColor.replaceAll('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.error, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.repeat, color: AppColors.error),
        ),
        title: Text(revWithTopic.topic.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('${subject.name} - ${revWithTopic.revision.revisionType} Revision'),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          color: AppColors.error,
          onPressed: () {
            ref.read(revisionNotifierProvider).markRevisionCompleted(revWithTopic.revision);
          },
        ),
      ),
    );
  }

  void _showLogStudySheet(BuildContext context, PlannedTask? task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LogStudySheet(task: task, today: _today),
    );
  }
}

class _LogStudySheet extends ConsumerStatefulWidget {
  final PlannedTask? task;
  final DateTime today;

  const _LogStudySheet({this.task, required this.today});

  @override
  ConsumerState<_LogStudySheet> createState() => _LogStudySheetState();
}

class _LogStudySheetState extends ConsumerState<_LogStudySheet> {
  String? _selectedSubjectId;
  final List<TextEditingController> _topicControllers = [TextEditingController()];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _selectedSubjectId = widget.task!.subjectId;
    }
  }

  @override
  void dispose() {
    for (var controller in _topicControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addTopicField() {
    setState(() {
      _topicControllers.add(TextEditingController());
    });
  }

  void _removeTopicField(int index) {
    if (_topicControllers.length > 1) {
      setState(() {
        _topicControllers[index].dispose();
        _topicControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a subject')));
      return;
    }

    final topics = _topicControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (topics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter at least one topic')));
      return;
    }

    setState(() => _isLoading = true);

    await ref.read(todayStudyProvider.notifier).logStudySession(
      subjectId: _selectedSubjectId!,
      topics: topics,
      plannedTask: widget.task,
    );
    
    // Invalidate all dependent providers so data refreshes across tabs
    ref.invalidate(plannerProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(statisticsProvider);
    ref.invalidate(todayRevisionsProvider);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final subjects = subjectsState.value?.where((s) => s.isActive).toList() ?? [];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.task != null ? 'Complete Task' : 'Log Extra Study',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (widget.task == null) ...[
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: (val) => setState(() => _selectedSubjectId = val),
            ),
            const SizedBox(height: 16),
          ],

          const Text('Topics Covered', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          ..._topicControllers.asMap().entries.map((entry) {
            int idx = entry.key;
            var controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'e.g. Algebra Chapter 1',
                        prefixIcon: const Icon(Icons.notes),
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  if (_topicControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                      onPressed: () => _removeTopicField(idx),
                    )
                ],
              ),
            );
          }),
          
          TextButton.icon(
            onPressed: _addTopicField,
            icon: const Icon(Icons.add),
            label: const Text('Add another topic'),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save Study Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
