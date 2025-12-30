import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../providers/auth_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/fcm_token_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? const Uuid().v4();
    }
  }
  
  Future<bool> _checkBiometricAvailable() async {
    try {
      final localAuth = LocalAuthentication();
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      final isDeviceSupported = await localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _loginWithBiometric() async {
    try {
      final localAuth = LocalAuthentication();
      final isAvailable = await _checkBiometricAvailable();
      
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication is not available on this device'),
              backgroundColor: IntraZeroColors.warning,
            ),
          );
        }
        return;
      }
      
      final authenticated = await localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      if (!authenticated) {
        return;
      }
      
      // Get stored biometric token from secure storage
      const storage = FlutterSecureStorage();
      final storedEmail = await storage.read(key: 'biometric_email');
      final storedBiometricToken = await storage.read(key: 'biometric_token');
      final deviceId = await _getDeviceId();
      
      if (storedEmail == null || storedBiometricToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login not set up. Please login with email and password first.'),
              backgroundColor: IntraZeroColors.warning,
            ),
          );
        }
        return;
      }
      
      // Use biometric token to login (this would need backend support for biometric token validation)
      // For now, we'll show a message that full biometric login requires backend implementation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication successful. Please enter your password to complete login.'),
            backgroundColor: IntraZeroColors.info,
          ),
        );
        // Pre-fill email
        _emailController.text = storedEmail;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication failed: ${e.toString()}'),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final deviceId = await _getDeviceId();
      final authNotifier = ref.read(currentUserProvider.notifier);
      final apiClient = ref.read(apiClientProvider);
      
      final success = await authNotifier.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceId: deviceId,
        fcmToken: null, // Don't send in login - register separately with throttling
      );
      
      if (mounted) {
        if (success) {
          // Register FCM token separately with throttling (non-blocking, won't spam server)
          FCMTokenService.registerToken(apiClient, deviceId: deviceId)
              .catchError((e) {
            // Silently fail - token registration is not critical for login
            return;
          });
          
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'),
              backgroundColor: IntraZeroColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        if (e.toString().contains('type') && e.toString().contains('cast')) {
          errorMessage = 'Invalid response format from server. Please try again.';
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: IntraZeroColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: IntraZeroColors.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassmorphismCard(
                padding: const EdgeInsets.all(30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.business,
                        size: 80,
                        color: IntraZeroColors.primaryGradient.colors.first,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: IntraZeroColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 16,
                          color: IntraZeroColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GradientButton(
                              text: 'Sign In',
                              gradient: IntraZeroColors.primaryGradient,
                              icon: Icons.login,
                              isFullWidth: true,
                              onPressed: _login,
                            ),
                      const SizedBox(height: 20),
                      FutureBuilder<bool>(
                        future: _checkBiometricAvailable(),
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return TextButton.icon(
                              onPressed: _loginWithBiometric,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Use Biometric Login'),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

