class Topic {
  final String id;
  final String studySessionId;
  final String subjectId;
  final String title;
  final String? notes;
  final DateTime firstStudiedDate;
  final DateTime createdAt;

  Topic({
    required this.id,
    required this.studySessionId,
    required this.subjectId,
    required this.title,
    this.notes,
    required this.firstStudiedDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studySessionId': studySessionId,
      'subjectId': subjectId,
      'title': title,
      'notes': notes,
      'firstStudiedDate': firstStudiedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Topic.fromMap(Map<String, dynamic> map) {
    return Topic(
      id: map['id'],
      studySessionId: map['studySessionId'],
      subjectId: map['subjectId'],
      title: map['title'],
      notes: map['notes'],
      firstStudiedDate: DateTime.parse(map['firstStudiedDate']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
