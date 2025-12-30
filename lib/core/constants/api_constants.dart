class ApiConstants {
  static const String baseUrl = 'https://crm.intrazero.com/api/v1/mobile';
  
  // Authentication
  static const String login = '/login';
  static const String refresh = '/refresh';
  static const String logout = '/logout';
  static const String biometric = '/biometric';
  
  // Attendance
  static const String attendanceStatus = '/attendance/status';
  static const String checkIn = '/attendance/check-in';
  static const String checkOut = '/attendance/check-out';
  static const String attendanceHistory = '/attendance/history';
  static const String forgotCheckin = '/attendance/forgot-checkin';
  static const String forgotRequests = '/attendance/forgot-requests';
  static const String forgotRequest = '/attendance/forgot-request';
  static const String forgotCheckinSettings = '/attendance/forgot-checkin-settings'; // Get system settings
  static const String checkoutStatus = '/attendance/checkout-status';
  static const String officeLocations = '/attendance/office-locations';
  
  // Timesheet
  static const String timesheetStatus = '/timesheet/status';
  static const String timesheetStart = '/timesheet/start';
  static const String timesheetStop = '/timesheet/stop';
  static const String timesheetStillWorking = '/timesheet/still-working';
  static const String timesheetEntries = '/timesheet/entries';
  static const String timesheetProjects = '/timesheet/projects';
  static const String timesheetMorningPlanTasks = '/timesheet/morning-plan-tasks';
  static const String timesheetStartFromPlan = '/timesheet/start-from-plan';
  static const String timesheetEntriesWithPlan = '/timesheet/entries-with-plan';
  static const String timesheetLinkToPlanTask = '/timesheet/link-to-plan-task';
  
  // Standup
  static const String standupStatus = '/standup/status';
  static const String standupToday = '/standup/today';
  static const String standupProjects = '/standup/projects';
  static const String standupMorning = '/standup/morning';
  static const String standupEvening = '/standup/evening';
  static const String standupHistory = '/standup/history';
  static const String standupView = '/standup/view';
  static const String standupTaskUpdate = '/standup/task/update';
  static const String standupReminderStatus = '/standup/reminder-status';
  static const String standupRequestReminder = '/standup/request-reminder';
  static const String standupTodayEditable = '/standup/today-editable';
  
  // Leave
  static const String leaveBalance = '/leave/balance';
  static const String leaveRequests = '/leave/requests';
  static const String leaveRequest = '/leave/request';
  
  // Excuse
  static const String excuseRequests = '/excuse/requests';
  static const String excuseRequest = '/excuse/request';
  
  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsRead = '/notifications/read';
  static const String notificationsRegisterDevice = '/notifications/register-device';
  
  // Profile
  static const String profile = '/profile';
  static const String profileUpdate = '/profile/update';
  
  // Settings
  static const String settingsApp = '/settings/app';
}

