import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../study/data/study_repository.dart';
import '../../study/domain/study_session.dart';
import '../../revisions/data/revision_repository.dart';

class ActivityData {
  final Map<DateTime, int> activityMap;
  final int totalSessions;
  final int totalActiveDays;
  final int currentStreak;
  final int longestStreak;

  ActivityData({
    required this.activityMap,
    required this.totalSessions,
    required this.totalActiveDays,
    required this.currentStreak,
    required this.longestStreak,
  });
}

final activityProvider = FutureProvider<ActivityData>((ref) async {
  final studyRepo = ref.watch(studyRepositoryProvider);

  // Get activity for the last 365 days
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yearAgo = today.subtract(const Duration(days: 365));

  final activityMap = await studyRepo.getActivityMap(yearAgo, today);
  final allSessions = await studyRepo.getAllSessions();
  
  final revisionRepo = ref.watch(revisionRepositoryProvider);
  final revActivityMap = await revisionRepo.getCompletedRevisionsActivityMap(yearAgo, today);

  for (final entry in revActivityMap.entries) {
    activityMap[entry.key] = (activityMap[entry.key] ?? 0) + entry.value;
  }

  // Calculate streaks - allow streak to start from yesterday if today not yet studied
  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;

  // Determine starting point: if today has activity, start from today (i=0)
  // If not, start from yesterday (i=1) — the user may not have studied yet today
  int startOffset = activityMap.containsKey(today) ? 0 : 1;
  bool streakBroken = false;

  for (int i = startOffset; i < 365; i++) {
    final dateToCheck = today.subtract(Duration(days: i));
    if (activityMap.containsKey(dateToCheck)) {
      if (!streakBroken) {
        currentStreak++;
      }
      tempStreak++;
    } else {
      streakBroken = true;
      if (tempStreak > longestStreak) {
        longestStreak = tempStreak;
      }
      tempStreak = 0;
    }
  }
  if (tempStreak > longestStreak) {
    longestStreak = tempStreak;
  }
  if (currentStreak > longestStreak) {
    longestStreak = currentStreak;
  }

  return ActivityData(
    activityMap: activityMap,
    totalSessions: allSessions.length,
    totalActiveDays: activityMap.length,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
  );
});

/// Provider for sessions in a specific month
final monthActivityProvider = FutureProvider.family<List<StudySession>, DateTime>((ref, month) async {
  final studyRepo = ref.watch(studyRepositoryProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0); // last day of month
  return studyRepo.getSessionsInRange(start, end);
});
