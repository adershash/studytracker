class Subject {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String accentColor;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subject({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.accentColor,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    String? accentColor,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'accentColor': accentColor,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      icon: map['icon'],
      accentColor: map['accentColor'],
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
