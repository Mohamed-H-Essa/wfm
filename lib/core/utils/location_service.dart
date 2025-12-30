import 'package:geolocator/geolocator.dart';

class LocationService {
  static bool _permissionRequested = false;
  
  /// Request location permissions proactively (call this on app startup)
  static Future<bool> requestPermissions() async {
    if (_permissionRequested) return true;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        _permissionRequested = true;
        return permission != LocationPermission.denied && 
               permission != LocationPermission.deniedForever;
      }
      
      _permissionRequested = true;
      return permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }
  
  static Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }
}

