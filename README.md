# IntraZero Employee - Flutter Mobile App

Flutter mobile application for IntraZero Employee self-service, including attendance, timesheet, and daily work tracking.

## Project Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes/
│   │   └── app_routes.dart
│   └── themes/
│       ├── colors.dart
│       ├── typography.dart
│       └── intrazero_2026_theme.dart
├── core/
│   ├── constants/
│   ├── utils/
│   ├── network/
│   └── storage/
├── features/
│   ├── auth/
│   ├── attendance/
│   ├── timesheet/
│   ├── daily_standup/
│   ├── leave/
│   ├── excuse/
│   ├── notifications/
│   ├── profile/
│   ├── settings/
│   └── main/
└── shared/
    ├── widgets/
    └── models/
```

## Features

- ✅ Authentication (Login, Biometric)
- ✅ Attendance (Check-in/out, History, Forgot check-in)
- ✅ Timesheet (Timer, Entries, Projects)
- ✅ Daily Standup (Morning Plan, Evening Summary, History)
- ✅ Leave Management
- ✅ Excuse Requests
- ✅ Notifications
- ✅ Profile & Settings

## Design System

The app follows the IntraZero 2026 design system matching the standup features:
- Glassmorphism effects
- Gradient headers
- Modern color palette
- Consistent typography

## Getting Started

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Run the app:
```bash
flutter run
```

## API Integration

All APIs are documented in `/var/www/newcrm/modules/leave_attendance_wfh_2026/MOBILE_APP_PLAN.md`

**API Base URL:** `https://crm.intrazero.com/api/v1/mobile`

Configured in: `lib/core/constants/api_constants.dart`

## ✅ Implementation Status

**Status: 100% Complete**

- ✅ All 20 screens fully implemented
- ✅ All 36 API endpoints integrated
- ✅ No placeholders or missing functions
- ✅ All features fully functional
- ✅ Complete error handling
- ✅ Full state management

See `FINAL_VERIFICATION.md` for complete verification report.
