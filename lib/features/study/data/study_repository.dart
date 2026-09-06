import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../domain/study_session.dart';
import '../domain/topic.dart';

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepository(DatabaseService.instance);
});

class StudyRepository {
  final DatabaseService _dbService;

  StudyRepository(this._dbService);

  Future<void> addStudySession(StudySession session) async {
    final db = await _dbService.database;
    await db.insert('study_sessions', session.toMap());
  }

  Future<void> addTopic(Topic topic) async {
    final db = await _dbService.database;
    await db.insert('topics', topic.toMap());
  }

  Future<List<StudySession>> getSessionsForDate(DateTime date) async {
    final db = await _dbService.database;
    
    // We only care about the date part
    final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'actualStudyDate >= ? AND actualStudyDate <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'actualStudyDate DESC',
    );

    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  Future<List<Topic>> getTopicsForSession(String sessionId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'topics',
      where: 'studySessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'createdAt ASC',
    );
    return maps.map((map) => Topic.fromMap(map)).toList();
  }

  Future<Topic?> getTopicById(String id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'topics',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Topic.fromMap(maps.first);
    }
    return null;
  }

  /// Get all study sessions (for overall analytics)
  Future<List<StudySession>> getAllSessions() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      orderBy: 'actualStudyDate DESC',
    );
    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  /// Get sessions in a date range
  Future<List<StudySession>> getSessionsInRange(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'actualStudyDate >= ? AND actualStudyDate <= ?',
      whereArgs: [startStr, endStr],
      orderBy: 'actualStudyDate ASC',
    );
    return maps.map((map) => StudySession.fromMap(map)).toList();
  }

  /// Get a map of date -> session count for the heatmap
  Future<Map<DateTime, int>> getActivityMap(DateTime start, DateTime end) async {
    final sessions = await getSessionsInRange(start, end);
    final Map<DateTime, int> activityMap = {};
    for (var session in sessions) {
      final dateKey = DateTime(
        session.actualStudyDate.year,
        session.actualStudyDate.month,
        session.actualStudyDate.day,
      );
      activityMap[dateKey] = (activityMap[dateKey] ?? 0) + 1;
    }
    return activityMap;
  }

  /// Get total topic count
  Future<int> getTotalTopicCount() async {
    final db = await _dbService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM topics');
    return result.first['count'] as int;
  }

  /// Get all topics for a subject
  Future<List<Topic>> getTopicsForSubject(String subjectId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'topics',
      where: 'subjectId = ?',
      whereArgs: [subjectId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Topic.fromMap(map)).toList();
  }
}
