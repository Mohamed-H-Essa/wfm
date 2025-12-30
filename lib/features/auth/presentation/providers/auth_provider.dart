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
  
  CurrentUserNotifier(this._authRepository) : super(null);
  
  Future<bool> login({
    required String email,
    required String password,
    String? deviceId,
    String? deviceName,
    String? fcmToken,
  }) async {
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
  }
  
  Future<void> logout({String? deviceId}) async {
    await _authRepository.logout(deviceId: deviceId);
    state = null;
  }
  
  void setUser(UserModel user) {
    state = user;
  }
}

