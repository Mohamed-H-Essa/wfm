import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/themes/colors.dart';
import '../../../../core/utils/notification_service.dart';
import '../../../../core/utils/location_service.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request all required permissions on app open
    await _requestPermissions();
    
    // Then check auth
    await _checkAuth();
  }

  Future<void> _requestPermissions() async {
    try {
      // Initialize and request notification permissions
      await NotificationService.initialize();
      
      // Request location permissions
      await LocationService.requestPermissions();
    } catch (e) {
      // Silently fail - permissions might already be granted or user can grant later
      print('Permission request error: $e');
    }
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final apiClient = ref.read(apiClientProvider);
      final token = await apiClient.getAccessToken();
      
      if (token != null) {
        // User is authenticated, navigate to main
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      } else {
        // User not authenticated, navigate to login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.business,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'IntraZero Employee',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

