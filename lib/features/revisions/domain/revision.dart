class Revision {
  final String id;
  final String topicId;
  final String revisionType; // e.g. 'Day 1', 'Day 4', 'Day 7'
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final String status; // 'pending', 'completed', 'missed'
  final int? daysLate;

  Revision({
    required this.id,
    required this.topicId,
    required this.revisionType,
    required this.scheduledDate,
    this.completedDate,
    this.status = 'pending',
    this.daysLate,
  });

  Revision copyWith({
    String? id,
    String? topicId,
    String? revisionType,
    DateTime? scheduledDate,
    DateTime? completedDate,
    String? status,
    int? daysLate,
  }) {
    return Revision(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      revisionType: revisionType ?? this.revisionType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      daysLate: daysLate ?? this.daysLate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topicId': topicId,
      'revisionType': revisionType,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'status': status,
      'daysLate': daysLate,
    };
  }

  factory Revision.fromMap(Map<String, dynamic> map) {
    return Revision(
      id: map['id'],
      topicId: map['topicId'],
      revisionType: map['revisionType'],
      scheduledDate: DateTime.parse(map['scheduledDate']),
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      status: map['status'],
      daysLate: map['daysLate'],
    );
  }
}
