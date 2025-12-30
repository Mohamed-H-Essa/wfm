import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/utils/notification_service.dart';
import 'core/utils/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (if not already initialized by native code)
  // On iOS, Firebase is initialized in AppDelegate.swift before Flutter plugins
  // On Android, Firebase is auto-initialized if google-services.json exists
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      print('✅ Firebase initialized from Flutter');
    } else {
      print('ℹ️ Firebase already initialized (likely by native code)');
    }
  } catch (e) {
    // Firebase might not be configured, continue anyway
    print('⚠️ Firebase initialization error: $e');
  }
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize notifications (permissions will be requested in splash screen)
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification initialization error: $e');
  }
  
  // Request location permissions proactively
  try {
    await LocationService.requestPermissions();
  } catch (e) {
    print('Location permission request error: $e');
  }
  
  runApp(
    const ProviderScope(
      child: IntraZeroEmployeeApp(),
    ),
  );
}

