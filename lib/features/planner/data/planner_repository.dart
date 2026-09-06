import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../domain/weekly_plan.dart';
import '../domain/planned_task.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository(DatabaseService.instance);
});

class PlannerRepository {
  final DatabaseService _dbService;

  PlannerRepository(this._dbService);

  Future<WeeklyPlan> createPlan(WeeklyPlan plan) async {
    final db = await _dbService.database;
    await db.insert('weekly_plans', plan.toMap());
    return plan;
  }

  Future<WeeklyPlan?> getActivePlan() async {
    final db = await _dbService.database;
    
    // Just get the single active plan for the user (we assume one plan for now)
    final List<Map<String, dynamic>> maps = await db.query(
      'weekly_plans',
      orderBy: 'createdAt DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return WeeklyPlan.fromMap(maps.first);
    }
    return null;
  }

  Future<void> addTasks(List<PlannedTask> tasks) async {
    final db = await _dbService.database;
    final batch = db.batch();
    for (var task in tasks) {
      batch.insert('planned_tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PlannedTask>> getTasksForPlan(String planId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'planned_tasks',
      where: 'planId = ?',
      whereArgs: [planId],
      orderBy: 'dayNumber ASC, displayOrder ASC',
    );
    
    return List.generate(maps.length, (i) {
      return PlannedTask.fromMap(maps[i]);
    });
  }

  Future<List<PlannedTask>> getTasksForDayNumber(int dayNumber) async {
    final db = await _dbService.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'planned_tasks',
      where: 'dayNumber = ?',
      whereArgs: [dayNumber],
      orderBy: 'displayOrder ASC',
    );
    
    return List.generate(maps.length, (i) {
      return PlannedTask.fromMap(maps[i]);
    });
  }

  Future<void> updateTask(PlannedTask task) async {
    final db = await _dbService.database;
    await db.update(
      'planned_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String taskId) async {
    final db = await _dbService.database;
    await db.delete(
      'planned_tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}
