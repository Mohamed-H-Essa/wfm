class Project {
  final int id;
  final String title;
  final String color;
  final bool isActive;

  Project({
    required this.id,
    required this.title,
    required this.color,
    required this.isActive,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      title: json['title'] as String,
      color: json['color'] as String? ?? '#667eea',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'color': color,
      'is_active': isActive,
    };
  }
}

