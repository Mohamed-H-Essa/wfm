# Getting Started with IntraZero Employee Flutter App

## 📦 Installation

1. **Install Flutter** (if not already installed)
   ```bash
   # Check Flutter version (requires >=3.0.0)
   flutter --version
   ```

2. **Navigate to project**
   ```bash
   cd /var/www/newcrm/mobile
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### API Base URL
The app is configured to use:
- **Production:** `https://crm.intrazero.com/api/v1/mobile`

This is set in `lib/core/constants/api_constants.dart`

### Environment Variables
No environment variables needed - all configuration is in code.

## 📱 Features Implemented

### ✅ Fully Functional
1. **Authentication** - Login with email/password, token management
2. **Attendance** - Check-in/out (location optional), status, forgot check-in
3. **Timesheet** - Start/stop timer (works without task_id), status
4. **Daily Standup** - Morning plan, evening summary, project selector with "Other"

### 📋 Ready for API Connection
1. **Leave Management** - Repository ready, UI placeholder
2. **Excuse Requests** - Repository ready, UI placeholder
3. **Notifications** - Repository ready, UI placeholder
4. **Profile** - Repository ready, basic UI
5. **Settings** - Repository ready, basic UI

## 🎨 Design System

The app uses the **IntraZero 2026 Design System** matching the standup features:
- Glassmorphism effects
- Gradient headers (morning, evening, progress, complete, urgent)
- Modern color palette
- Consistent typography

## 🏗️ Architecture

- **State Management:** Riverpod
- **Network:** Dio with interceptors
- **Storage:** Flutter Secure Storage (tokens), Hive (ready for offline)
- **Architecture:** Clean Architecture (data/domain/presentation)

## 📡 API Integration

All API endpoints are documented in:
`/var/www/newcrm/modules/leave_attendance_wfh_2026/MOBILE_APP_PLAN.md`

### Working Endpoints
- ✅ POST `/login`
- ✅ POST `/refresh`
- ✅ POST `/logout`
- ✅ GET `/attendance/status`
- ✅ POST `/attendance/check-in`
- ✅ POST `/attendance/check-out`
- ✅ POST `/attendance/forgot-checkin`
- ✅ GET `/timesheet/status`
- ✅ POST `/timesheet/start`
- ✅ POST `/timesheet/stop`
- ✅ GET `/standup/status`
- ✅ GET `/standup/projects`
- ✅ POST `/standup/morning`
- ✅ POST `/standup/evening`

## 🐛 Troubleshooting

### Common Issues

1. **"Package not found"**
   ```bash
   flutter pub get
   ```

2. **"API connection failed"**
   - Check internet connection
   - Verify API base URL is correct
   - Check if backend is running

3. **"Token expired"**
   - App automatically refreshes tokens
   - If refresh fails, user will be logged out

## 📝 Next Steps

1. Complete placeholder screens (history, entries)
2. Add offline support
3. Implement push notifications
4. Add animations and polish
5. Testing

## 📚 Documentation

- **API Documentation:** `MOBILE_APP_PLAN.md`
- **Implementation Status:** `IMPLEMENTATION_STATUS.md`
- **Complete Summary:** `COMPLETE_IMPLEMENTATION_SUMMARY.md`
- **TODO List:** `TODO.md`

---

**App is ready to run!** 🚀

