import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/study_session.dart';
import '../domain/topic.dart';
import '../data/study_repository.dart';
import '../../planner/data/planner_repository.dart';
import '../../planner/domain/planned_task.dart';
import '../../revisions/data/revision_repository.dart';
import '../../revisions/domain/revision_scheduler.dart';

final todayStudyProvider = AsyncNotifierProvider<TodayStudyNotifier, List<StudySession>>(TodayStudyNotifier.new);

class TodayStudyNotifier extends AsyncNotifier<List<StudySession>> {
  @override
  Future<List<StudySession>> build() async {
    final repository = ref.watch(studyRepositoryProvider);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return repository.getSessionsForDate(today);
  }

  Future<void> logStudySession({
    required String subjectId,
    required List<String> topics,
    PlannedTask? plannedTask,
  }) async {
    final repository = ref.read(studyRepositoryProvider);
    final plannerRepo = ref.read(plannerRepositoryProvider);
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // 1. Create Session
      final sessionId = const Uuid().v4();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final session = StudySession(
        id: sessionId,
        subjectId: subjectId,
        plannedTaskId: plannedTask?.id,
        plannedDate: plannedTask != null ? today : null,
        actualStudyDate: today,
        createdAt: now,
        completedAt: now,
        status: 'completed',
      );
      
      await repository.addStudySession(session);

      // 2. Add Topics and Generate Revisions
      final revisionRepo = ref.read(revisionRepositoryProvider);
      final revisionScheduler = ref.read(revisionSchedulerProvider);

      for (var topicTitle in topics) {
        if (topicTitle.trim().isEmpty) continue;
        
        final topic = Topic(
          id: const Uuid().v4(),
          studySessionId: sessionId,
          subjectId: subjectId,
          title: topicTitle.trim(),
          firstStudiedDate: now,
          createdAt: now,
        );
        await repository.addTopic(topic);
        
        // Generate 1-4-7 revisions
        final revisions = revisionScheduler.scheduleRevisionsForTopic(topic.id, today);
        await revisionRepo.addRevisions(revisions);
      }

      // 3. Update Planned Task status if provided
      if (plannedTask != null) {
        final updatedTask = plannedTask.copyWith(
          status: 'completed',
        );
        await plannerRepo.updateTask(updatedTask);
      }

      return repository.getSessionsForDate(today);
    });
  }
}
