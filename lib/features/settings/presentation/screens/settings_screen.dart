import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../app/themes/colors.dart';
import '../../../../shared/widgets/glassmorphism_card.dart';
import '../../data/repositories/settings_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/data/repositories/auth_repository.dart';

final appSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = SettingsRepository(ref.watch(apiClientProvider));
  final response = await repository.getAppSettings();
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message ?? 'Failed to load settings');
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _locationServices = true;
  bool _biometricLogin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications_enabled') ?? true;
      _locationServices = prefs.getBool('location_services_enabled') ?? true;
      _biometricLogin = prefs.getBool('biometric_login_enabled') ?? false;
    });
  }

  Future<void> _saveLocalPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          _pushNotifications = settings['push_notifications_enabled'] as bool? ?? _pushNotifications;
          _locationServices = settings['location_services_enabled'] as bool? ?? _locationServices;
          _biometricLogin = settings['biometric_login_enabled'] as bool? ?? _biometricLogin;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'App Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        value: _pushNotifications,
                        onChanged: (value) async {
                          setState(() {
                            _pushNotifications = value;
                          });
                          await _saveLocalPreference('push_notifications_enabled', value);
                          // Note: This is a local preference. Server-side push notification settings
                          // are controlled by admin via the backend settings.
                        },
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Receive push notifications for important updates'),
                        secondary: const Icon(Icons.notifications),
                      ),
                      const Divider(),
                      SwitchListTile(
                        value: _locationServices,
                        onChanged: (value) async {
                          setState(() {
                            _locationServices = value;
                          });
                          await _saveLocalPreference('location_services_enabled', value);
                          // Note: This is a local preference for allowing location access.
                          // The actual location requirement is controlled by admin via backend settings.
                        },
                        title: const Text('Location Services'),
                        subtitle: const Text('Allow location tracking for check-in/out'),
                        secondary: const Icon(Icons.location_on),
                      ),
                      const Divider(),
                      SwitchListTile(
                        value: _biometricLogin,
                        onChanged: (value) async {
                          if (_isLoading) return;
                          
                          setState(() {
                            _isLoading = true;
                            _biometricLogin = value;
                          });
                          
                          try {
                            final deviceInfo = DeviceInfoPlugin();
                            String deviceId;
                            if (Theme.of(context).platform == TargetPlatform.android) {
                              final androidInfo = await deviceInfo.androidInfo;
                              deviceId = androidInfo.id;
                            } else {
                              final iosInfo = await deviceInfo.iosInfo;
                              deviceId = iosInfo.identifierForVendor ?? 'unknown';
                            }
                            
                            final authRepository = AuthRepository(ref.read(apiClientProvider));
                            final response = await authRepository.updateBiometricSettings(
                              enabled: value,
                              deviceId: deviceId,
                              biometricToken: value ? 'enabled' : null,
                            );
                            
                            if (response.success) {
                              await _saveLocalPreference('biometric_login_enabled', value);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value 
                                        ? 'Biometric login enabled' 
                                        : 'Biometric login disabled'),
                                    backgroundColor: IntraZeroColors.success,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.message ?? 'Failed to update biometric settings'),
                                    backgroundColor: IntraZeroColors.danger,
                                  ),
                                );
                                setState(() {
                                  _biometricLogin = !value;
                                });
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: IntraZeroColors.danger,
                                ),
                              );
                              setState(() {
                                _biometricLogin = !value;
                              });
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                        title: const Text('Biometric Login'),
                        subtitle: const Text('Use fingerprint or face ID to login'),
                        secondary: const Icon(Icons.fingerprint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: IntraZeroColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.info),
                        title: const Text('App Version'),
                        subtitle: const Text('1.0.0'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.bug_report),
                        title: const Text('Report Issue'),
                        onTap: () async {
                          final email = 'support@intrazero.com';
                          final subject = 'Mobile App Issue Report';
                          final body = 'Please describe the issue you encountered:';
                          final uri = Uri(
                            scheme: 'mailto',
                            path: email,
                            query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open email client')),
                            );
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip),
                        title: const Text('Privacy Policy'),
                        onTap: () async {
                          final uri = Uri.parse('https://intrazero.com/privacy-policy');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open privacy policy')),
                            );
                          }
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.description),
                        title: const Text('Terms of Service'),
                        onTap: () async {
                          final uri = Uri.parse('https://intrazero.com/terms-of-service');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open terms of service')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.refresh(appSettingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
