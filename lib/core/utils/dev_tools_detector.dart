import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DevToolsDetector {
  static Future<bool> isDevToolsOpen() async {
    // Check for debugger attached
    if (kDebugMode) return true;
    
    // Check for root/jailbreak
    try {
      bool isRooted = await FlutterJailbreakDetection.jailbroken;
      bool isDeveloperMode = await FlutterJailbreakDetection.developerMode;
      
      return isRooted || isDeveloperMode;
    } catch (e) {
      return false;
    }
  }
  
  static void enforceSecurityCheck() {
    // This will be called on app startup
    // If dev tools are detected, show blocking screen
  }
}

