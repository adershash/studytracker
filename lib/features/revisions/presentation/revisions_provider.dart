import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/revision.dart';
import '../data/revision_repository.dart';
import '../../study/data/study_repository.dart';
import '../../study/domain/topic.dart';

class RevisionWithTopic {
  final Revision revision;
  final Topic topic;

  RevisionWithTopic(this.revision, this.topic);
}

final todayRevisionsProvider = FutureProvider<List<RevisionWithTopic>>((ref) async {
  final revRepo = ref.watch(revisionRepositoryProvider);
  final studyRepo = ref.watch(studyRepositoryProvider);
  
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  
  final pendingRevisions = await revRepo.getPendingRevisionsForDate(today);
  
  List<RevisionWithTopic> result = [];
  for (var rev in pendingRevisions) {
    final topic = await studyRepo.getTopicById(rev.topicId);
    if (topic != null) {
      result.add(RevisionWithTopic(rev, topic));
    }
  }
  
  return result;
});

// A provider for completing a revision
final revisionNotifierProvider = Provider((ref) => RevisionNotifier(ref));

class RevisionNotifier {
  final Ref ref;
  
  RevisionNotifier(this.ref);
  
  Future<void> markRevisionCompleted(Revision revision) async {
    final revRepo = ref.read(revisionRepositoryProvider);
    final updated = revision.copyWith(
      status: 'completed',
      completedDate: DateTime.now(),
    );
    await revRepo.updateRevision(updated);
    
    // Invalidate the today revisions provider to refresh the UI
    ref.invalidate(todayRevisionsProvider);
  }
}
