import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../../../core/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, UserModel?>((ref) {
  return CurrentUserNotifier(ref.watch(authRepositoryProvider));
});

class CurrentUserNotifier extends StateNotifier<UserModel?> {
  final AuthRepository _authRepository;
  
  CurrentUserNotifier(this._authRepository) : super(null) {
    // Load user on initialization if token exists
    _loadUserFromToken();
  }
  
  Future<void> _loadUserFromToken() async {
    try {
      // Try to get profile from API if token exists
      final apiClient = ApiClient();
      final token = await apiClient.getAccessToken();
      if (token != null) {
        // Load user profile from API
        final profileResponse = await _authRepository.getProfile();
        if (profileResponse.success && profileResponse.data != null) {
          state = profileResponse.data!;
        }
      }
    } catch (e) {
      // Silently fail - user will need to login again
      // Don't print error as it's expected if token is invalid
    }
  }
  
  Future<bool> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
    String? fcmToken,
  }) async {
    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
        deviceId: deviceId,
        deviceName: deviceName,
        fcmToken: fcmToken,
      );
      
      if (response.success && response.data != null) {
        state = response.data!.user;
        return true;
      }
      return false;
    } catch (e) {
      // Re-throw to be caught by the UI layer
      rethrow;
    }
  }
  
  Future<void> logout({String? deviceId}) async {
    await _authRepository.logout(deviceId: deviceId);
    state = null;
  }
  
  void setUser(UserModel user) {
    state = user;
  }
  
  Future<void> refreshUser() async {
    try {
      final profileResponse = await _authRepository.getProfile();
      if (profileResponse.success && profileResponse.data != null) {
        state = profileResponse.data!;
      }
    } catch (e) {
      print('Failed to refresh user: $e');
    }
  }
}

