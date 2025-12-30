class UserModel {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? profileImage;
  final String role;
  final String? department;
  final String? position;
  
  UserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.profileImage,
    required this.role,
    this.department,
    this.position,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle id as either int or String
    int userId;
    if (json['id'] is int) {
      userId = json['id'] as int;
    } else if (json['id'] is String) {
      userId = int.tryParse(json['id'] as String) ?? 0;
    } else {
      userId = 0;
    }
    
    return UserModel(
      id: userId,
      firstname: json['firstname']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      profileImage: json['profile_image']?.toString(),
      role: json['role']?.toString() ?? 'employee',
      department: json['department']?.toString(),
      position: json['position']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'profile_image': profileImage,
      'role': role,
      'department': department,
      'position': position,
    };
  }
  
  String get fullName => '$firstname $lastname';
}

