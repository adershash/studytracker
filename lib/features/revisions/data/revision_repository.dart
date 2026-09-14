import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../domain/revision.dart';

final revisionRepositoryProvider = Provider<RevisionRepository>((ref) {
  return RevisionRepository(DatabaseService.instance);
});

class RevisionRepository {
  final DatabaseService _dbService;

  RevisionRepository(this._dbService);

  Future<void> addRevisions(List<Revision> revisions) async {
    final db = await _dbService.database;
    final batch = db.batch();
    for (var rev in revisions) {
      batch.insert('revisions', rev.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Revision>> getPendingRevisionsForDate(DateTime date) async {
    final db = await _dbService.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    
    // We want revisions scheduled for this date or EARLIER (overdue) that are still pending
    final List<Map<String, dynamic>> maps = await db.query(
      'revisions',
      where: 'scheduledDate <= ? AND status = ?',
      whereArgs: [dateStr, 'pending'],
      orderBy: 'scheduledDate ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Revision.fromMap(maps[i]);
    });
  }

  Future<void> updateRevision(Revision revision) async {
    final db = await _dbService.database;
    await db.update(
      'revisions',
      revision.toMap(),
      where: 'id = ?',
      whereArgs: [revision.id],
    );
  }

  /// Get all revisions for analytics
  Future<List<Revision>> getAllRevisions() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'revisions',
      orderBy: 'scheduledDate ASC',
    );
    return List.generate(maps.length, (i) => Revision.fromMap(maps[i]));
  }

  /// Get revision stats: total, completed, pending, missed
  Future<Map<String, int>> getRevisionStats() async {
    final db = await _dbService.database;
    final total = await db.rawQuery('SELECT COUNT(*) as count FROM revisions');
    final completed = await db.rawQuery("SELECT COUNT(*) as count FROM revisions WHERE status = 'completed'");
    final pending = await db.rawQuery("SELECT COUNT(*) as count FROM revisions WHERE status = 'pending'");
    
    return {
      'total': total.first['count'] as int,
      'completed': completed.first['count'] as int,
      'pending': pending.first['count'] as int,
    };
  }

  /// Get a map of date -> completed revision count for the heatmap
  Future<Map<DateTime, int>> getCompletedRevisionsActivityMap(DateTime start, DateTime end) async {
    final db = await _dbService.database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();

    final List<Map<String, dynamic>> maps = await db.query(
      'revisions',
      where: 'completedDate >= ? AND completedDate <= ? AND status = ?',
      whereArgs: [startStr, endStr, 'completed'],
    );
    
    final Map<DateTime, int> activityMap = {};
    for (var map in maps) {
      final rev = Revision.fromMap(map);
      if (rev.completedDate != null) {
        final dateKey = DateTime(
          rev.completedDate!.year,
          rev.completedDate!.month,
          rev.completedDate!.day,
        );
        activityMap[dateKey] = (activityMap[dateKey] ?? 0) + 1;
      }
    }
    return activityMap;
  }
}
