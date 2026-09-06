import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';
import '../domain/subject.dart';

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository(DatabaseService.instance);
});

class SubjectRepository {
  final DatabaseService _dbService;

  SubjectRepository(this._dbService);

  Future<Subject> addSubject(Subject subject) async {
    final db = await _dbService.database;
    await db.insert('subjects', subject.toMap());
    return subject;
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) {
      return Subject.fromMap(maps[i]);
    });
  }

  Future<List<Subject>> getActiveSubjects() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt ASC',
    );
    return List.generate(maps.length, (i) {
      return Subject.fromMap(maps[i]);
    });
  }

  Future<Subject> updateSubject(Subject subject) async {
    final db = await _dbService.database;
    await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
    return subject;
  }

  Future<void> archiveSubject(String id) async {
    final db = await _dbService.database;
    await db.update(
      'subjects',
      {'isActive': 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSubject(String id) async {
    final db = await _dbService.database;
    await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
