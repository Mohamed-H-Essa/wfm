import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/themes/colors.dart';
import '../../../attendance/presentation/screens/attendance_home_screen.dart';
import '../../../timesheet/presentation/screens/timesheet_home_screen.dart';
import '../../../daily_standup/presentation/screens/standup_home_screen.dart';
import '../../../notifications/presentation/screens/notifications_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AttendanceHomeScreen(),
    const TimesheetHomeScreen(),
    const StandupHomeScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: IntraZeroColors.primaryGradient.colors.first,
          unselectedItemColor: IntraZeroColors.textSecondary,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.access_time),
              label: 'Attendance',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.timer),
              label: 'Timesheet',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Standup',
            ),
            BottomNavigationBarItem(
              icon: _buildNotificationIcon(ref),
              label: 'Notifications',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationIcon(WidgetRef ref) {
    // Watch notifications to get unread count
    final notificationsAsync = ref.watch(
      notificationsProvider(
        NotificationsParams(unreadOnly: false, page: 1),
      ),
    );
    
    return notificationsAsync.when(
      data: (notificationList) {
        final unreadCount = notificationList.unreadCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications),
            if (unreadCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: IntraZeroColors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Icon(Icons.notifications),
      error: (_, __) => const Icon(Icons.notifications),
    );
  }
}

