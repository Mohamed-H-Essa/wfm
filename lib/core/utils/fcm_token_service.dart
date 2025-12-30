import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// Service to manage FCM token registration with throttling and caching
class FCMTokenService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static String? _cachedToken;
  static DateTime? _lastRegistrationAttempt;
  static bool _isRegistering = false;
  
  // Minimum time between registration attempts (5 minutes)
  static const Duration _throttleDuration = Duration(minutes: 5);
  
  /// Get FCM token (cached if available)
  static Future<String?> getToken() async {
    try {
      if (_cachedToken != null) {
        return _cachedToken;
      }
      
      final token = await FirebaseMessaging.instance.getToken();
      _cachedToken = token;
      return token;
    } catch (e) {
      return null;
    }
  }
  
  /// Register FCM token with server (throttled and cached)
  static Future<bool> registerToken(ApiClient apiClient, {String? deviceId}) async {
    // Prevent concurrent registration attempts
    if (_isRegistering) {
      return false;
    }
    
    // Throttle: Don't register if last attempt was too recent
    if (_lastRegistrationAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(_lastRegistrationAttempt!);
      if (timeSinceLastAttempt < _throttleDuration) {
        return false; // Too soon, skip this registration
      }
    }
    
    try {
      _isRegistering = true;
      _lastRegistrationAttempt = DateTime.now();
      
      // Get current token
      final token = await getToken();
      if (token == null) {
        _isRegistering = false;
        return false;
      }
      
      // Check if token has changed since last registration
      final lastRegisteredToken = await _storage.read(key: 'last_registered_fcm_token');
      if (lastRegisteredToken == token) {
        // Token hasn't changed, no need to register again
        _isRegistering = false;
        return true;
      }
      
      // Register token with server
      try {
        await apiClient.dio.post(
          ApiConstants.notificationsRegisterDevice,
          data: {
            'fcm_token': token,
            if (deviceId != null) 'device_id': deviceId,
          },
        );
        
        // Cache the registered token
        await _storage.write(key: 'last_registered_fcm_token', value: token);
        _isRegistering = false;
        return true;
      } on DioException catch (e) {
        // If registration fails, don't cache the token
        _isRegistering = false;
        return false;
      }
    } catch (e) {
      _isRegistering = false;
      return false;
    }
  }
  
  /// Clear cached token (call on logout)
  static Future<void> clearToken() async {
    _cachedToken = null;
    await _storage.delete(key: 'last_registered_fcm_token');
  }
  
  /// Force token refresh and registration (bypasses throttle, use sparingly)
  static Future<bool> forceRegisterToken(ApiClient apiClient, {String? deviceId}) async {
    _lastRegistrationAttempt = null; // Reset throttle
    _cachedToken = null; // Force token refresh
    await _storage.delete(key: 'last_registered_fcm_token'); // Force re-registration
    return await registerToken(apiClient, deviceId: deviceId);
  }
}

