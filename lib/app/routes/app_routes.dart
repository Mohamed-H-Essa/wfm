import 'package:flutter/material.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/attendance/presentation/screens/attendance_home_screen.dart';
import '../../features/timesheet/presentation/screens/timesheet_home_screen.dart';
import '../../features/daily_standup/presentation/screens/standup_home_screen.dart';
import '../../features/leave/presentation/screens/leave_home_screen.dart';
import '../../features/excuse/presentation/screens/excuse_home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/main/presentation/screens/main_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String main = '/main';
  static const String attendance = '/attendance';
  static const String timesheet = '/timesheet';
  static const String standup = '/standup';
  static const String leave = '/leave';
  static const String excuse = '/excuse';
  static const String notifications = '/notifications';
  static const String profile = '/profile';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case attendance:
        return MaterialPageRoute(builder: (_) => const AttendanceHomeScreen());
      case timesheet:
        return MaterialPageRoute(builder: (_) => const TimesheetHomeScreen());
      case standup:
        return MaterialPageRoute(builder: (_) => const StandupHomeScreen());
      case leave:
        return MaterialPageRoute(builder: (_) => const LeaveHomeScreen());
      case excuse:
        return MaterialPageRoute(builder: (_) => const ExcuseHomeScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}

