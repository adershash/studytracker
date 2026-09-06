class StudySession {
  final String id;
  final String subjectId;
  final String? plannedTaskId;
  final DateTime? plannedDate;
  final DateTime actualStudyDate;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;

  StudySession({
    required this.id,
    required this.subjectId,
    this.plannedTaskId,
    this.plannedDate,
    required this.actualStudyDate,
    this.status = 'completed',
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'plannedTaskId': plannedTaskId,
      'plannedDate': plannedDate?.toIso8601String(),
      'actualStudyDate': actualStudyDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'],
      subjectId: map['subjectId'],
      plannedTaskId: map['plannedTaskId'],
      plannedDate: map['plannedDate'] != null ? DateTime.parse(map['plannedDate']) : null,
      actualStudyDate: DateTime.parse(map['actualStudyDate']),
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
    );
  }
}
