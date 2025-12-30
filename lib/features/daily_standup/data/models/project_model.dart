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
    // Handle id as either int or String
    int projectId;
    if (json['id'] is int) {
      projectId = json['id'] as int;
    } else if (json['id'] is String) {
      projectId = int.tryParse(json['id'] as String) ?? 0;
    } else {
      projectId = 0;
    }
    
    // Helper to parse boolean from dynamic (handles bool, String, int)
    bool parseBool(dynamic value, bool defaultValue) {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'yes';
      }
      if (value is int) return value != 0;
      return defaultValue;
    }
    
    return Project(
      id: projectId,
      title: json['title']?.toString() ?? '',
      color: json['color']?.toString() ?? '#667eea',
      isActive: parseBool(json['is_active'], true),
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

