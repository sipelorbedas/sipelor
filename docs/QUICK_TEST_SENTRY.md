# 🧪 Quick Test Sentry - 5 Menit!

**Goal**: Verify Sentry error tracking is working  
**Time**: 5-10 minutes  
**Status**: Ready to test

---

## 🚀 Quick Test (5 Menit)

### Method 1: Automated Test Script

```cmd
scripts\test_sentry.bat
```

**What it does**:
1. Launches app with Sentry enabled
2. Waits for you to trigger test error
3. Provides instructions

**Follow the prompts!**

---

### Method 2: Manual Test

#### Step 1: Run with Sentry (2 min)

```cmd
scripts\run_with_sentry.bat
```

Or manual:
```cmd
flutter run --dart-define=SENTRY_DSN="https://62e4b6de7057c52e2b68937146034489@o4510788305289216.ingest.us.sentry.io/4510788306468864"
```

#### Step 2: Trigger Test Error (1 min)

1. Open app on device/emulator
2. Open drawer menu
3. Go to **"Debug Menu"**
4. Tap **"Test Sentry Error"** button

#### Step 3: Check Sentry Dashboard (2 min)

1. Open browser
2. Go to: [https://sentry.io](https://sentry.io)
3. Login to your account
4. Select project: **SIPELOR BEDAS**
5. Go to **Issues** tab
6. Look for: **"Test Sentry Error Triggered"**

**Expected**: Error should appear within 1 minute!

---

## ✅ Success Criteria

If you see the error in Sentry dashboard:
- ✅ Title: "Test Sentry Error Triggered"
- ✅ Environment: "development"
- ✅ Platform: "Flutter"
- ✅ Device info visible
- ✅ Breadcrumbs showing user actions

**Then Sentry is working!** 🎉

---

## 🔍 What to Check in Error Details

Click on the error in Sentry to see:

### 1. Error Information
- Error message
- Stack trace
- Exception type

### 2. Context
- User ID (if logged in)
- Device info (model, OS)
- App version (1.0.0+1)

### 3. Breadcrumbs
- User actions leading to error
- Navigation history
- API calls (if any)

### 4. Environment
- Should show: "development"
- Platform: "Flutter"

---

## 🎯 Production Test

To test in production build:

```cmd
# Build production APK
scripts\build_production.bat

# Install on device
adb install build\app\outputs\flutter-apk\app-release.apk

# Trigger test error
# Check Sentry - environment should be "production"
```

---

## ❌ Troubleshooting

### Error Not Appearing?

**Check 1**: DSN configured?
```cmd
# Should see Sentry DSN in output
flutter run --dart-define=SENTRY_DSN="..." --verbose
```

**Check 2**: Network connection?
- Ensure device/emulator has internet
- Check firewall settings

**Check 3**: Debug mode filter?
In `lib/services/error_tracking_service.dart`:
```dart
// Temporarily disable this filter for testing
options.beforeSend = (event, hint) {
  // if (kDebugMode) {
  //   return null;  // COMMENT THIS OUT FOR TESTING
  // }
  return event;
};
```

**Check 4**: Sentry quota?
- Login to Sentry
- Check plan limits
- Verify events not being dropped

---

## 📊 Next Steps After Successful Test

1. ✅ Sentry is working!
2. [ ] Configure alert rules
3. [ ] Set up team access
4. [ ] Customize error filtering
5. [ ] Configure release tracking

---

## 🎉 All Done!

Sentry error tracking is now **ACTIVE** and ready for production monitoring!

**Dashboard**: [https://sentry.io](https://sentry.io)  
**Documentation**: `docs/SENTRY_DSN_CONFIGURED.md`

---

**Test Date**: _______________  
**Tester**: _______________  
**Result**: ⬜ Pass ⬜ Fail  
**Notes**: _____________________________________
