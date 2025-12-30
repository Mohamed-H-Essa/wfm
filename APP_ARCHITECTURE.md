# IntraZero Employee Mobile App - Architecture & Implementation Guide

**Version:** 1.0.0  
**Last Updated:** December 2024  
**Purpose:** This document explains how the Flutter mobile app works, its architecture, patterns, and implementation details. Use this to understand the app structure when identifying missing features or providing implementation guidance.

---

## 📱 App Overview

**IntraZero Employee** is a Flutter mobile application (iOS/Android) for employee self-service, including:
- Attendance tracking (check-in/out)
- Timesheet management
- Daily standup (morning plan, evening summary)
- Leave management
- Excuse requests
- Notifications
- Profile & Settings

**API Base URL:** `https://crm.intrazero.com/api/v1/mobile`

---

## 🏗️ Architecture

### Clean Architecture Pattern

The app follows **feature-based clean architecture**:

```
lib/
├── main.dart                    # App entry point
├── app/                         # App configuration
│   ├── app.dart                # MaterialApp setup
│   ├── routes/                  # Navigation routes
│   └── themes/                  # Design system
├── core/                        # Core infrastructure
│   ├── constants/              # API endpoints, constants
│   ├── network/                # API client, interceptors
│   ├── storage/                # Secure storage
│   └── utils/                  # Utilities (location, notifications)
├── features/                    # Feature modules
│   ├── auth/
│   ├── attendance/
│   ├── timesheet/
│   ├── daily_standup/
│   ├── leave/
│   ├── excuse/
│   ├── notifications/
│   ├── profile/
│   └── settings/
└── shared/                      # Shared components
    ├── models/                 # Shared data models
    └── widgets/                # Reusable UI widgets
```

### Feature Module Structure

Each feature follows this structure:

```
feature_name/
├── data/
│   ├── models/                # Data models (fromJson/toJson)
│   └── repositories/         # API repository classes
├── presentation/
│   ├── screens/               # UI screens
│   └── providers/            # Riverpod state management
└── domain/                    # (Optional) Business logic
```

---

## 🔑 Key Components

### 1. API Client (`lib/core/network/api_client.dart`)

**Purpose:** Centralized HTTP client using Dio

**Features:**
- Base URL: `https://crm.intrazero.com/api/v1/mobile`
- Automatic token injection via `AuthInterceptor`
- Error handling via `ErrorInterceptor`
- Request/response logging
- 30-second timeouts

**Usage:**
```dart
final apiClient = ApiClient();
final response = await apiClient.dio.get('/endpoint');
```

### 2. Authentication System

**Token Storage:** Flutter Secure Storage (encrypted)

**Flow:**
1. User logs in → receives `access_token` and `refresh_token`
2. Tokens stored in secure storage
3. `AuthInterceptor` automatically adds `Authorization: Bearer {token}` to all requests
4. On 401 error → automatically refreshes token using `refresh_token`
5. If refresh fails → user redirected to login

**Key Files:**
- `lib/core/network/interceptors/auth_interceptor.dart` - Token injection & refresh
- `lib/features/auth/data/repositories/auth_repository.dart` - Login/logout
- `lib/features/auth/presentation/providers/auth_provider.dart` - User state

### 3. State Management (Riverpod)

**Pattern:** Provider-based state management

**Provider Types Used:**
- `Provider` - Singleton services (ApiClient, Repositories)
- `StateNotifierProvider` - Mutable state (user, standup status)
- `FutureProvider` - Async data fetching (history, lists)
- `FutureProvider.family` - Parameterized async data

**Example:**
```dart
// Provider definition
final standupHistoryProvider = FutureProvider.family<StandupHistoryModel, StandupHistoryParams>((ref, params) async {
  final repository = StandupRepository(ref.read(apiClientProvider));
  final response = await repository.getHistory(...);
  return StandupHistoryModel.fromJson(response.data!);
});

// Usage in widget
final historyAsync = ref.watch(standupHistoryProvider(params));
historyAsync.when(
  data: (history) => Text('Data loaded'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

**⚠️ CRITICAL:** Family providers MUST use typed parameter classes (not Maps) to prevent infinite rebuilds:
```dart
// ✅ CORRECT - Typed params class
@immutable
class StandupHistoryParams {
  final int month;
  final int year;
  final int page;
  // ... with proper == and hashCode
}

// ❌ WRONG - Map causes infinite rebuilds
FutureProvider.family<Model, Map<String, int?>>  // DON'T USE
```

### 4. Repository Pattern

**Purpose:** Abstraction layer between UI and API

**Standard Structure:**
```dart
class FeatureRepository {
  final ApiClient _apiClient;
  
  FeatureRepository(this._apiClient);
  
  Future<ApiResponse<Model>> getData() async {
    try {
      final response = await _apiClient.dio.get('/endpoint');
      
      // Handle API response structure
      if (response.data is Map<String, dynamic>) {
        final responseMap = response.data as Map<String, dynamic>;
        final success = responseMap['success'] as bool? ?? true;
        
        if (success && responseMap['data'] != null) {
          return ApiResponse(
            success: true,
            data: Model.fromJson(responseMap['data']),
            statusCode: response.statusCode,
          );
        }
      }
      
      return ApiResponse(success: false, ...);
    } on DioException catch (e) {
      // Extract error message
      String? errorMessage;
      if (e.response?.data is Map<String, dynamic>) {
        errorMessage = e.response?.data['message']?.toString();
      }
      return ApiResponse(
        success: false,
        message: errorMessage ?? e.error?.toString(),
        statusCode: e.response?.statusCode,
      );
    }
  }
}
```

**API Response Format Expected:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

### 5. Data Models

**Pattern:** Manual JSON serialization (no code generation)

**Structure:**
```dart
class Model {
  final String field1;
  final int? field2;  // Nullable fields
  
  Model({required this.field1, this.field2});
  
  factory Model.fromJson(Map<String, dynamic> json) {
    // Handle type conversions (String to int, etc.)
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }
    
    return Model(
      field1: json['field1']?.toString() ?? '',
      field2: parseNullableInt(json['field2']),
    );
  }
}
```

**Common Patterns:**
- API may return numbers as strings → always parse safely
- Nullable fields → use `?` and provide defaults
- Nested objects → create separate model classes
- Lists → handle empty/null lists gracefully

---

## 🔄 Data Flow

### Typical Feature Flow

1. **User Action** → Widget triggers provider
2. **Provider** → Calls repository method
3. **Repository** → Makes API call via ApiClient
4. **ApiClient** → Adds auth token, sends request
5. **API Response** → Repository parses response
6. **Model Creation** → Repository creates model from JSON
7. **Provider Update** → Provider updates state
8. **UI Rebuild** → Widget rebuilds with new data

### Example: Loading Standup History

```
User navigates to Standup History Screen
  ↓
Widget: ref.watch(standupHistoryProvider(params))
  ↓
Provider: Calls StandupRepository.getHistory()
  ↓
Repository: apiClient.dio.get('/standup/history', queryParams)
  ↓
AuthInterceptor: Adds Authorization header
  ↓
API: Returns JSON response
  ↓
Repository: Parses response, creates StandupHistoryModel
  ↓
Provider: Returns model (or error)
  ↓
Widget: Displays data using historyAsync.when()
```

---

## 📋 Feature Implementation Details

### 1. Authentication

**Screens:**
- `SplashScreen` - Checks auth status on app start
- `LoginScreen` - Email/password login

**Key Features:**
- Biometric login support
- Automatic token refresh
- Device ID registration
- FCM token registration

**API Endpoints:**
- `POST /login` - Login with email/password
- `POST /refresh` - Refresh access token
- `POST /logout` - Logout (optional device_id)
- `POST /biometric` - Biometric authentication

### 2. Attendance

**Screens:**
- `AttendanceHomeScreen` - Check-in/out buttons, status
- `AttendanceHistoryScreen` - Monthly history with summary
- `ForgotCheckinScreen` - Request forgot check-in

**Key Features:**
- Location optional (can check-in without location)
- Real-time status updates
- Monthly history with pagination
- Summary stats (present/absent/late days, work hours)

**API Endpoints:**
- `GET /attendance/status` - Current attendance status
- `POST /attendance/check-in` - Check in (location optional)
- `POST /attendance/check-out` - Check out
- `GET /attendance/history` - Monthly history (month, year, page)
- `POST /attendance/forgot-checkin` - Request forgot check-in

**Data Models:**
- `AttendanceStatusModel` - Current status
- `AttendanceHistoryModel` - History with records, summary, pagination
- `AttendanceRecordModel` - Individual record

### 3. Timesheet

**Screens:**
- `TimesheetHomeScreen` - Timer with start/stop
- `TimesheetEntriesScreen` - List of entries with date range filter

**Key Features:**
- Start/stop timer functionality
- "Still working" reminder
- Project/task selection (task optional)
- Entry history with date range filtering
- Summary (total duration)

**API Endpoints:**
- `GET /timesheet/status` - Current timer status
- `POST /timesheet/start` - Start timer (project_id, task_id optional)
- `POST /timesheet/stop` - Stop timer
- `POST /timesheet/still-working` - Remind still working
- `GET /timesheet/entries` - Get entries (start_date, end_date, project_id)
- `GET /timesheet/projects` - List of projects

**Data Models:**
- `TimesheetStatusModel` - Current timer state
- `TimesheetEntriesModel` - List of entries with summary
- `TimesheetEntryItemModel` - Individual entry

### 4. Daily Standup

**Screens:**
- `StandupHomeScreen` - Status, task stats
- `MorningPlanScreen` - Submit morning plan
- `EveningSummaryScreen` - Submit evening summary
- `StandupHistoryScreen` - Monthly history
- `StandupViewScreen` - View standup details

**Key Features:**
- Morning plan with goals, work type, tasks
- Evening summary with productivity rating
- Project selector with "Other" custom option
- Task management (add, update completion)
- History with summary stats
- Status tracking (IN_PROGRESS, COMPLETE)

**API Endpoints:**
- `GET /standup/status` - Current standup status
- `GET /standup/today` - Today's standup
- `GET /standup/projects` - List of projects
- `POST /standup/morning` - Submit morning plan
- `POST /standup/evening` - Submit evening summary
- `GET /standup/history` - Monthly history (month, year, page)
- `GET /standup/view/{id}` - View standup details
- `POST /standup/task/update` - Update task completion

**Data Models:**
- `StandupStatusModel` - Current status with tasks
- `StandupHistoryModel` - History with standups, summary, pagination
- `Project` - Project model

### 5. Leave Management

**Screens:**
- `LeaveHomeScreen` - Balance display, requests list
- `LeaveRequestScreen` - Submit new leave request

**Key Features:**
- Leave balance display (annual, accidental, marriage)
- Leave requests list with status
- Submit new request (type, dates, reason)

**API Endpoints:**
- `GET /leave/balance` - Leave balance
- `GET /leave/requests` - List of requests
- `POST /leave/request` - Submit new request

### 6. Excuse Requests

**Screens:**
- `ExcuseHomeScreen` - Requests list
- `ExcuseRequestScreen` - Submit new excuse

**Key Features:**
- Excuse requests list
- Submit new excuse request

**API Endpoints:**
- `GET /excuse/requests` - List of requests
- `POST /excuse/request` - Submit new request

### 7. Notifications

**Screens:**
- `NotificationsScreen` - List of notifications

**Key Features:**
- Notifications list with pagination
- Unread count display
- Mark as read (swipe or tap)
- Filter unread only
- Push notification registration

**API Endpoints:**
- `GET /notifications` - List (unread_only, page, per_page)
- `POST /notifications/read` - Mark as read
- `POST /notifications/register-device` - Register FCM token

### 8. Profile & Settings

**Screens:**
- `ProfileScreen` - User profile display
- `SettingsScreen` - App settings

**API Endpoints:**
- `GET /profile` - User profile
- `PUT /profile/update` - Update profile
- `GET /settings/app` - App settings

---

## 🎨 UI Patterns

### Design System

**Theme:** IntraZero 2026 Design System
- Glassmorphism effects
- Gradient headers (morning, evening, progress, complete, urgent)
- Modern color palette
- Consistent typography

**Shared Widgets:**
- `GlassmorphismCard` - Glass effect cards
- `GradientButton` - Buttons with gradients
- `GradientHeader` - Headers with gradients
- `ProgressBar` - Progress indicators

### Loading States

**Pattern:** Use `AsyncValue.when()` for loading/error/data states

```dart
historyAsync.when(
  data: (history) => _buildContent(history),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => _buildError(error),
);
```

### Error Handling

**Pattern:** Show user-friendly messages, return empty models on error

```dart
try {
  final response = await repository.getData();
  if (response.success && response.data != null) {
    return response.data!;
  }
} catch (e) {
  // Log error, return empty model
  return EmptyModel();
}
```

---

## 🔧 Common Patterns & Best Practices

### 1. Caching

**Pattern:** In-memory cache with timestamp

```dart
final _cache = <String, _CacheEntry>{};
const _cacheDuration = Duration(minutes: 5);

// Check cache before API call
final cached = _cache[cacheKey];
if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheDuration) {
  return cached.data;
}

// After API call, cache result
_cache[cacheKey] = _CacheEntry(data, DateTime.now());
```

### 2. Timeout Handling

**Pattern:** Wrap async operations in timeout

```dart
return (() async {
  // API call
})().timeout(
  const Duration(seconds: 12),
  onTimeout: () => emptyModel,
);
```

### 3. Parameter Classes for Family Providers

**CRITICAL:** Always use typed parameter classes, never Maps

```dart
@immutable
class Params {
  final int month;
  final int year;
  
  const Params({required this.month, required this.year});
  
  @override
  bool operator ==(Object other) => ...;
  @override
  int get hashCode => Object.hash(month, year);
}
```

### 4. Safe Type Parsing

**Pattern:** Handle API returning strings as numbers

```dart
int parseInt(dynamic value, int defaultValue) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
```

### 5. Empty Model Fallback

**Pattern:** Always return empty model instead of throwing

```dart
final emptyModel = Model(
  items: [],
  summary: SummaryModel(...),
  pagination: PaginationModel(...),
);

// On error or empty response
return emptyModel;
```

---

## 📡 API Integration Standards

### Request Format

**Headers:**
- `Authorization: Bearer {access_token}` (auto-added by interceptor)
- `Content-Type: application/json`
- `Accept: application/json`

**Query Parameters:**
- Pagination: `page`, `per_page`
- Filters: `month`, `year`, `unread_only`, etc.

### Response Format

**Expected Structure:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Optional message"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Error message",
  "data": null
}
```

### Error Handling

**HTTP Status Codes:**
- `200` - Success
- `401` - Unauthorized (triggers token refresh)
- `400` - Bad Request
- `404` - Not Found
- `500` - Server Error

**Error Message Extraction:**
```dart
String? errorMessage;
if (e.response?.data is Map<String, dynamic>) {
  errorMessage = e.response?.data['message']?.toString();
}
```

---

## 🚀 Adding New Features

### Step-by-Step Guide

1. **Create Feature Directory**
   ```
   lib/features/new_feature/
   ├── data/
   │   ├── models/
   │   └── repositories/
   └── presentation/
       ├── screens/
       └── providers/
   ```

2. **Define API Endpoints**
   - Add to `lib/core/constants/api_constants.dart`

3. **Create Data Models**
   - Create model classes with `fromJson` methods
   - Handle nullable fields and type conversions

4. **Create Repository**
   - Implement API calls
   - Handle response parsing
   - Return `ApiResponse<T>`

5. **Create Provider**
   - Use appropriate provider type (FutureProvider, StateNotifierProvider)
   - For family providers, use typed params class

6. **Create UI Screen**
   - Use `ConsumerWidget` or `ConsumerStatefulWidget`
   - Use `ref.watch()` to access providers
   - Handle loading/error/data states

7. **Add Route**
   - Add route to `lib/app/routes/app_routes.dart`

---

## 🐛 Common Issues & Solutions

### Issue: Infinite Loading Spinner

**Cause:** Using `Map` as family provider parameter

**Solution:** Use typed parameter class with proper equality

### Issue: Token Refresh Loop

**Cause:** Refresh token expired or invalid

**Solution:** Clear tokens and redirect to login

### Issue: API Response Parsing Fails

**Cause:** Type mismatches (string vs int), null values

**Solution:** Use safe parsing functions, handle nulls

### Issue: Provider Not Updating

**Cause:** Using `ref.read()` instead of `ref.watch()`

**Solution:** Use `ref.watch()` for reactive updates

---

## 📊 Current Implementation Status

**✅ Fully Implemented:**
- All 9 features (auth, attendance, timesheet, standup, leave, excuse, notifications, profile, settings)
- All 36 API endpoints integrated
- Complete error handling
- Token management
- State management
- UI screens (20+ screens)

**🔧 Recent Fixes:**
- Fixed infinite loading issue in listing screens (Riverpod family provider params)
- Removed billable/non-billable badges from timesheet entries
- Improved error handling and logging

---

## 🔗 Related Documentation

- API Documentation: `/var/www/newcrm/modules/leave_attendance_wfh_2026/MOBILE_APP_PLAN.md`
- API Base URL: `https://crm.intrazero.com/api/v1/mobile`
- Project Structure: See `README.md`

---

## 📝 Notes for Web Team

When identifying missing features or providing implementation guidance:

1. **Check API Response Format:** Ensure responses match expected structure (`success`, `data`, `message`)
2. **Type Safety:** API may return numbers as strings - app handles this, but consistent types help
3. **Pagination:** All list endpoints should support pagination (`page`, `per_page`)
4. **Error Messages:** Include clear `message` field in error responses
5. **Null Handling:** Document which fields are nullable
6. **Token Refresh:** Ensure `/refresh` endpoint works correctly for 401 handling

---

## 🚀 Upcoming Features & Implementation Plan

### Backend Implementation Required

**See:** `BACKEND_IMPLEMENTATION_PLAN.md` (in web project) for complete backend API details.

**Summary of Backend Work:**
1. **Morning/Evening Form Reminders APIs**
   - `GET /api/v1/mobile/standup/reminder-status` - Get reminder status
   - `POST /api/v1/mobile/standup/request-reminder` - Request reminder manually

2. **Check-in/Check-out Flow Integration**
   - Update `POST /api/v1/mobile/attendance/check-in` - Add morning plan status in response
   - Update `POST /api/v1/mobile/attendance/check-out` - Add evening summary blocking
   - New `GET /api/v1/mobile/attendance/checkout-status` - Check if checkout allowed

3. **Timesheet Integration with Morning Plan**
   - New `GET /api/v1/mobile/timesheet/morning-plan-tasks` - Get today's plan tasks
   - New `POST /api/v1/mobile/timesheet/start-from-plan` - Start timer from plan task
   - New `GET /api/v1/mobile/timesheet/entries-with-plan` - Get entries with plan info
   - New `POST /api/v1/mobile/timesheet/link-to-plan-task` - Link entry to plan task
   - **Database:** Create linking table `tblleave_attendance_wfh_2026_timesheet_standup_links`

4. **Enhanced Forgot Check-in/out**
   - New `GET /api/v1/mobile/attendance/forgot-requests` - List requests
   - New `GET /api/v1/mobile/attendance/forgot-request/{id}` - Get request details
   - New `DELETE /api/v1/mobile/attendance/forgot-request/{id}` - Cancel request

5. **Edit Morning Plan**
   - New `GET /api/v1/mobile/standup/today-editable` - Check editability
   - New `PUT /api/v1/mobile/standup/morning/{standup_id}` - Update morning plan

**Critical Backend Prerequisites:**
- **MUST DO FIRST:** Create timesheet-standup linking table
- Add validation in web timesheet system to require morning plan (when setting enabled)
- See `WEB_SYSTEM_BACKEND_PLAN.md` for web system changes

### Mobile App Changes Required

**See:** `MOBILE_APP_CHANGES_REQUIRED.md` (in web project) for complete mobile implementation details.

**Summary of Mobile Work:**

#### 1. Morning/Evening Reminders
- Add reminder status provider and UI
- Show reminder indicators on standup home screen
- Schedule local notifications for deadlines
- Add "Request Reminder" button

#### 2. Check-in/Check-out Flow
- **Check-in:** After successful check-in, check morning plan status from API response
  - If `morning_plan_required == true` AND `morning_plan_submitted == false`:
    - **Automatically redirect** to morning plan screen
    - Show message: "Please submit your morning plan"
    - Prevent navigation back until plan submitted
- **Check-out:** Before check-out, call `checkout-status` API
  - If blocked by evening summary:
    - Disable check-out button
    - Show blocking message
    - Add "Complete Evening Summary" button
    - Navigate to evening summary screen

#### 3. Timesheet Integration
- Add "Start from Plan" option in timesheet home screen
- Fetch and display morning plan tasks
- Start timer with selected plan task
- Show plan task info in entries
- Add "Link to Plan" action for existing entries

#### 4. Enhanced Forgot Check-in/out
- Create forgot requests list screen
- Show request status (pending/approved/rejected)
- Add cancel functionality for pending requests
- Add request details view

#### 5. Edit Morning Plan
- Check editability status on load
- Add "Edit" button if editable
- Pre-fill form with existing data
- Use PUT request for updates
- Show edit deadline

### Integration Points

**Check-in Flow:**
```
User taps "Check In"
  ↓
API: POST /attendance/check-in
  ↓
Response includes: morning_plan_required, morning_plan_submitted
  ↓
If required but not submitted:
  → Auto-navigate to Morning Plan Screen
  → Show blocking message
  → Prevent back navigation
```

**Check-out Flow:**
```
User taps "Check Out"
  ↓
API: GET /attendance/checkout-status
  ↓
If blocked:
  → Disable check-out button
  → Show blocking message
  → Navigate to Evening Summary
  ↓
After evening summary submitted:
  → Re-enable check-out
  → Allow check-out
```

**Timesheet-Plan Integration:**
```
User starts timer
  ↓
Option 1: "Start New Timer" (existing)
Option 2: "Start from Morning Plan" (new)
  ↓
If "Start from Plan":
  → Fetch morning plan tasks
  → Show task selector
  → Start timer with selected task
  → Link timer to plan task
```

### Implementation Priority

**Phase 1 (High Priority):**
1. Check-in/Check-out flow integration
2. Morning/Evening reminder status
3. Edit morning plan

**Phase 2 (Medium Priority):**
4. Timesheet integration with morning plan
5. Enhanced forgot check-in/out

**Phase 3 (Low Priority):**
6. Request reminder manually
7. Manual link timesheet to plan task

### Key Implementation Notes

**Riverpod Patterns:**
- Use typed parameter classes for family providers (never Maps)
- Use `FutureProvider` for async data
- Use `StateNotifierProvider` for mutable state
- Handle loading/error/data states with `.when()`

**API Response Format:**
- All APIs return: `{"success": true, "data": {...}, "message": "..."}`
- Handle nullable fields safely
- Parse types carefully (API may return numbers as strings)

**Error Handling:**
- Return empty models instead of throwing
- Show user-friendly error messages
- Handle network errors gracefully
- Retry failed requests where appropriate

**UI/UX:**
- Show loading states for all async operations
- Provide clear feedback for user actions
- Use consistent design patterns
- Follow IntraZero 2026 design system

---

**Last Updated:** December 30, 2024  
**Maintained By:** Mobile Development Team

