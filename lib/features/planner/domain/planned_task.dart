class PlannedTask {
  final String id;
  final String planId;
  final String subjectId;
  final int dayNumber; // 1 to 7
  final int displayOrder;
  final String status; // 'planned', 'completed', 'skipped', 'missed'

  bool get isCompleted => status == 'completed';

  PlannedTask({
    required this.id,
    required this.planId,
    required this.subjectId,
    required this.dayNumber,
    required this.displayOrder,
    this.status = 'planned',
  });

  PlannedTask copyWith({
    String? id,
    String? planId,
    String? subjectId,
    int? dayNumber,
    int? displayOrder,
    String? status,
  }) {
    return PlannedTask(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      subjectId: subjectId ?? this.subjectId,
      dayNumber: dayNumber ?? this.dayNumber,
      displayOrder: displayOrder ?? this.displayOrder,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'subjectId': subjectId,
      'dayNumber': dayNumber,
      'displayOrder': displayOrder,
      'status': status,
    };
  }

  factory PlannedTask.fromMap(Map<String, dynamic> map) {
    return PlannedTask(
      id: map['id'],
      planId: map['planId'],
      subjectId: map['subjectId'],
      dayNumber: map['dayNumber'],
      displayOrder: map['displayOrder'],
      status: map['status'],
    );
  }
}
