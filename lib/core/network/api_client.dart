import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.add(AuthInterceptor(_storage));
    _dio.interceptors.add(ErrorInterceptor());
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }
  
  Dio get dio => _dio;
  
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }
  
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }
  
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }
  
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }
  
  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

