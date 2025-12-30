# Mobile App Implementation Plan - Missing Features

**Date:** December 30, 2024  
**Status:** In Progress

## 📋 Overview

This document tracks the implementation of 5 major features:
1. Morning/Evening Form Reminders
2. Check-in/Check-out Flow Integration
3. Timesheet Integration with Morning Plan
4. Enhanced Forgot Check-in/out
5. Edit Morning Plan

---

## 🎯 Implementation Order

### Phase 1: Foundation (API Constants & Models)
- [x] Add all new API endpoints to `api_constants.dart`
- [ ] Create all required data models
- [ ] Update existing models with new fields

### Phase 2: Feature 2 - Check-in/Check-out Flow (HIGH PRIORITY)
- [ ] Update AttendanceStatusModel with morning plan & evening summary fields
- [ ] Create CheckoutStatusModel
- [ ] Update AttendanceRepository methods
- [ ] Update AttendanceHomeScreen with redirect/blocking logic

### Phase 3: Feature 1 - Reminders
- [ ] Create StandupReminderStatusModel
- [ ] Add reminder methods to StandupRepository
- [ ] Create reminder provider
- [ ] Update StandupHomeScreen UI

### Phase 4: Feature 5 - Edit Morning Plan
- [ ] Create StandupEditabilityModel
- [ ] Add editability methods to StandupRepository
- [ ] Update MorningPlanScreen with edit mode

### Phase 5: Feature 3 - Timesheet Integration
- [ ] Create MorningPlanTaskModel
- [ ] Add timesheet-plan methods to TimesheetRepository
- [ ] Update TimesheetHomeScreen
- [ ] Update TimesheetEntriesModel and screen

### Phase 6: Feature 4 - Enhanced Forgot Check-in/out
- [ ] Create ForgotRequestModel
- [ ] Add forgot request methods to AttendanceRepository
- [ ] Create ForgotRequestsScreen
- [ ] Update ForgotCheckinScreen

---

## 📝 Detailed Checklist

### ✅ Phase 1: Foundation

#### API Constants
- [x] Add standup reminder endpoints
- [x] Add checkout-status endpoint
- [x] Add timesheet-plan endpoints
- [x] Add forgot-request endpoints
- [x] Add editability endpoints

#### Data Models to Create
- [ ] StandupReminderStatusModel
- [ ] CheckoutStatusModel
- [ ] MorningPlanTaskModel
- [ ] ForgotRequestModel
- [ ] StandupEditabilityModel

#### Models to Update
- [ ] AttendanceStatusModel (add morning plan & evening summary fields)

---

## 🚀 Starting Implementation

**Current Step:** Phase 1 - Adding API constants and creating foundation models

