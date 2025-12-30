import 'user_model.dart';

class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;
  
  LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
  
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle expires_in as either int or String
    int expiresInValue = 3600;
    if (json['expires_in'] != null) {
      if (json['expires_in'] is int) {
        expiresInValue = json['expires_in'] as int;
      } else if (json['expires_in'] is String) {
        expiresInValue = int.tryParse(json['expires_in'] as String) ?? 3600;
      }
    }
    
    return LoginResponseModel(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      expiresIn: expiresInValue,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}

