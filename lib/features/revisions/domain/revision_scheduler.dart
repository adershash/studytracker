import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'revision.dart';

final revisionSchedulerProvider = Provider<RevisionScheduler>((ref) {
  return RevisionScheduler();
});

class RevisionScheduler {
  /// Schedules the 1-4-7 revisions for a newly completed topic.
  /// Day 1 = next day
  /// Day 4 = 3 days after Day 1
  /// Day 7 = 3 days after Day 4
  List<Revision> scheduleRevisionsForTopic(String topicId, DateTime actualStudyDate) {
    // 1-4-7 rule interpretation:
    // If studied on Monday (Day 0)
    // 1st Revision: Tuesday (Day 1)
    // 2nd Revision: Friday (Day 4)
    // 3rd Revision: Monday next week (Day 7)
    
    final day1 = actualStudyDate.add(const Duration(days: 1));
    final day4 = actualStudyDate.add(const Duration(days: 4));
    final day7 = actualStudyDate.add(const Duration(days: 7));
    
    return [
      Revision(
        id: const Uuid().v4(),
        topicId: topicId,
        revisionType: 'Day 1',
        scheduledDate: DateTime(day1.year, day1.month, day1.day),
      ),
      Revision(
        id: const Uuid().v4(),
        topicId: topicId,
        revisionType: 'Day 4',
        scheduledDate: DateTime(day4.year, day4.month, day4.day),
      ),
      Revision(
        id: const Uuid().v4(),
        topicId: topicId,
        revisionType: 'Day 7',
        scheduledDate: DateTime(day7.year, day7.month, day7.day),
      ),
    ];
  }
}
