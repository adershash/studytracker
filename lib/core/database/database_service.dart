import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('studytracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Drop all tables and recreate on upgrade for early dev phase
        await db.execute('DROP TABLE IF EXISTS revisions');
        await db.execute('DROP TABLE IF EXISTS topics');
        await db.execute('DROP TABLE IF EXISTS study_sessions');
        await db.execute('DROP TABLE IF EXISTS planned_tasks');
        await db.execute('DROP TABLE IF EXISTS weekly_plans');
        await db.execute('DROP TABLE IF EXISTS subjects');
        await _createDB(db, newVersion);
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNull = 'TEXT';
    const boolType = 'INTEGER NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const intNull = 'INTEGER';

    await db.execute('''
CREATE TABLE subjects (
  id $idType,
  name $textType,
  description $textNull,
  icon $textType,
  accentColor $textType,
  isActive $boolType,
  createdAt $textType,
  updatedAt $textType
)
''');

    await db.execute('''
CREATE TABLE weekly_plans (
  id $idType,
  cycleStartDate $textType,
  createdAt $textType,
  updatedAt $textType
)
''');

    await db.execute('''
CREATE TABLE planned_tasks (
  id $idType,
  planId $textType,
  subjectId $textType,
  dayNumber $intType,
  displayOrder $intType,
  status $textType,
  FOREIGN KEY (planId) REFERENCES weekly_plans (id) ON DELETE CASCADE,
  FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE study_sessions (
  id $idType,
  subjectId $textType,
  plannedTaskId $textNull,
  plannedDate $textNull,
  actualStudyDate $textType,
  status $textType,
  createdAt $textType,
  completedAt $textNull,
  FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE,
  FOREIGN KEY (plannedTaskId) REFERENCES planned_tasks (id) ON DELETE SET NULL
)
''');

    await db.execute('''
CREATE TABLE topics (
  id $idType,
  studySessionId $textType,
  subjectId $textType,
  title $textType,
  notes $textNull,
  firstStudiedDate $textType,
  createdAt $textType,
  FOREIGN KEY (studySessionId) REFERENCES study_sessions (id) ON DELETE CASCADE,
  FOREIGN KEY (subjectId) REFERENCES subjects (id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE revisions (
  id $idType,
  topicId $textType,
  revisionType $textType,
  scheduledDate $textType,
  completedDate $textNull,
  status $textType,
  daysLate $intNull,
  FOREIGN KEY (topicId) REFERENCES topics (id) ON DELETE CASCADE
)
''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
