class WeeklyPlan {
  final String id;
  final DateTime cycleStartDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklyPlan({
    required this.id,
    required this.cycleStartDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycleStartDate': cycleStartDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WeeklyPlan.fromMap(Map<String, dynamic> map) {
    return WeeklyPlan(
      id: map['id'],
      cycleStartDate: DateTime.parse(map['cycleStartDate']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
