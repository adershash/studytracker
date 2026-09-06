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
}
