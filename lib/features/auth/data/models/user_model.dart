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
    return UserModel(
      id: json['id'] as int,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      email: json['email'] as String,
      profileImage: json['profile_image'] as String?,
      role: json['role'] as String? ?? 'employee',
      department: json['department'] as String?,
      position: json['position'] as String?,
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

