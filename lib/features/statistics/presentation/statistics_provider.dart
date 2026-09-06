import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../study/data/study_repository.dart';
import '../../revisions/data/revision_repository.dart';
import '../../subjects/presentation/subjects_provider.dart';
import '../../subjects/domain/subject.dart';

class SubjectStats {
  final Subject subject;
  final int sessionCount;
  final int topicCount;

  SubjectStats({
    required this.subject,
    required this.sessionCount,
    required this.topicCount,
  });
}

class StudyStatistics {
  final int totalSessions;
  final int totalTopics;
  final int totalActiveDays;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> revisionStats; // total, completed, pending
  final List<SubjectStats> subjectBreakdown;
  final Map<int, int> weekdayDistribution; // 1=Mon ... 7=Sun -> count
  final double avgSessionsPerDay; // average per active day

  StudyStatistics({
    required this.totalSessions,
    required this.totalTopics,
    required this.totalActiveDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.revisionStats,
    required this.subjectBreakdown,
    required this.weekdayDistribution,
    required this.avgSessionsPerDay,
  });
}

final statisticsProvider = FutureProvider<StudyStatistics>((ref) async {
  final studyRepo = ref.watch(studyRepositoryProvider);
  final revisionRepo = ref.watch(revisionRepositoryProvider);
  final subjects = ref.watch(subjectsProvider).value ?? [];

  final allSessions = await studyRepo.getAllSessions();
  final totalTopics = await studyRepo.getTotalTopicCount();
  final revisionStats = await revisionRepo.getRevisionStats();

  // Calculate active days and streaks
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final Set<DateTime> activeDays = {};
  final Map<String, int> sessionsBySubject = {};
  final Map<int, int> weekdayDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

  for (var session in allSessions) {
    final dateKey = DateTime(
      session.actualStudyDate.year,
      session.actualStudyDate.month,
      session.actualStudyDate.day,
    );
    activeDays.add(dateKey);
    sessionsBySubject[session.subjectId] = (sessionsBySubject[session.subjectId] ?? 0) + 1;
    weekdayDist[dateKey.weekday] = (weekdayDist[dateKey.weekday] ?? 0) + 1;
  }

  // Streak calculation — allow streak to survive if today hasn't been studied yet
  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;
  
  // If user studied today, start from today. Otherwise, start from yesterday.
  int startOffset = activeDays.contains(today) ? 0 : 1;
  bool streakBroken = false;

  for (int i = startOffset; i < 365; i++) {
    final dateToCheck = today.subtract(Duration(days: i));
    if (activeDays.contains(dateToCheck)) {
      if (!streakBroken) currentStreak++;
      tempStreak++;
    } else {
      streakBroken = true;
      if (tempStreak > longestStreak) longestStreak = tempStreak;
      tempStreak = 0;
    }
  }
  if (tempStreak > longestStreak) longestStreak = tempStreak;
  if (currentStreak > longestStreak) longestStreak = currentStreak;

  // Subject breakdown — only include subjects that have at least 1 session
  List<SubjectStats> subjectBreakdown = [];
  for (var subject in subjects) {
    final sessCount = sessionsBySubject[subject.id] ?? 0;
    if (sessCount > 0) {
      final topicsForSubject = await studyRepo.getTopicsForSubject(subject.id);
      subjectBreakdown.add(SubjectStats(
        subject: subject,
        sessionCount: sessCount,
        topicCount: topicsForSubject.length,
      ));
    }
  }
  subjectBreakdown.sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

  final avgPerDay = activeDays.isEmpty ? 0.0 : allSessions.length / activeDays.length;

  return StudyStatistics(
    totalSessions: allSessions.length,
    totalTopics: totalTopics,
    totalActiveDays: activeDays.length,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    revisionStats: revisionStats,
    subjectBreakdown: subjectBreakdown,
    weekdayDistribution: weekdayDist,
    avgSessionsPerDay: avgPerDay,
  );
});
