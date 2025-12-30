#!/bin/bash

# API Test Script
# Tests all new API endpoints

BASE_URL="https://crm.intrazero.com/api/v1/mobile"
EMAIL="TEST@sdfsdf.com"
PASSWORD="rprQ30rhT1MQ"

echo "🚀 Starting API Tests..."
echo "============================================================"

# Login
echo ""
echo "🔐 Testing Login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed!"
  echo "$LOGIN_RESPONSE" | jq '.' 2>/dev/null || echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful!"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Test function
test_api() {
  local name=$1
  local endpoint=$2
  local method=${3:-GET}
  local data=$4
  
  echo "📡 Testing: $name"
  echo "   Endpoint: $endpoint"
  
  if [ "$method" = "GET" ]; then
    RESPONSE=$(curl -s -X GET "$BASE_URL$endpoint" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json")
  elif [ "$method" = "POST" ]; then
    RESPONSE=$(curl -s -X POST "$BASE_URL$endpoint" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data")
  elif [ "$method" = "PUT" ]; then
    RESPONSE=$(curl -s -X PUT "$BASE_URL$endpoint" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json" \
      -d "$data")
  elif [ "$method" = "DELETE" ]; then
    RESPONSE=$(curl -s -X DELETE "$BASE_URL$endpoint" \
      -H "Authorization: Bearer $TOKEN" \
      -H "Content-Type: application/json")
  fi
  
  SUCCESS=$(echo $RESPONSE | grep -o '"success":[^,}]*' | cut -d':' -f2 | tr -d ' ')
  
  if [ "$SUCCESS" = "true" ]; then
    echo "   ✅ Success"
    echo "$RESPONSE" | jq '.data | keys' 2>/dev/null || echo "   Response received"
  else
    echo "   ⚠️  API returned success=false"
    MESSAGE=$(echo $RESPONSE | grep -o '"message":"[^"]*' | cut -d'"' -f4)
    echo "   Message: $MESSAGE"
  fi
  echo ""
}

# Feature 1: Morning/Evening Reminders
echo "============================================================"
echo "📋 FEATURE 1: Morning/Evening Reminders"
echo "============================================================"
test_api "Reminder Status" "/standup/reminder-status" "GET"
test_api "Request Reminder (Morning)" "/standup/request-reminder" "POST" '{"type":"MORNING"}'

# Feature 2: Check-in/Check-out Flow
echo "============================================================"
echo "📋 FEATURE 2: Check-in/Check-out Flow"
echo "============================================================"
test_api "Checkout Status" "/attendance/checkout-status" "GET"
test_api "Check In" "/attendance/check-in" "POST" '{"method":"GPS"}'
test_api "Checkout Status (after check-in)" "/attendance/checkout-status" "GET"

# Feature 3: Timesheet Integration
echo "============================================================"
echo "📋 FEATURE 3: Timesheet Integration"
echo "============================================================"
test_api "Morning Plan Tasks" "/timesheet/morning-plan-tasks" "GET"
test_api "Timesheet Entries with Plan" "/timesheet/entries-with-plan" "GET"

# Feature 4: Enhanced Forgot Check-in/out
echo "============================================================"
echo "📋 FEATURE 4: Enhanced Forgot Check-in/out"
echo "============================================================"
test_api "Forgot Requests List" "/attendance/forgot-requests" "GET"
test_api "Forgot Requests (Pending)" "/attendance/forgot-requests?status=PENDING" "GET"

# Feature 5: Edit Morning Plan
echo "============================================================"
echo "📋 FEATURE 5: Edit Morning Plan"
echo "============================================================"
test_api "Today Editable Status" "/standup/today-editable" "GET"

# Additional existing APIs
echo "============================================================"
echo "📋 EXISTING APIs (Verification)"
echo "============================================================"
test_api "Standup Status" "/standup/status" "GET"
test_api "Standup Today" "/standup/today" "GET"
test_api "Attendance Status" "/attendance/status" "GET"
test_api "Timesheet Status" "/timesheet/status" "GET"
test_api "Timesheet Entries" "/timesheet/entries" "GET"

echo "============================================================"
echo "✅ All API tests completed!"
echo "============================================================"

