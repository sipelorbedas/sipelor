# 📧 Email Testing Guide - SIPELOR BEDAS

> **Panduan lengkap untuk test semua email functionality**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026

---

## ⚠️ PENTING: Auth Emails Tidak Bisa Di-trigger dari SQL

Supabase Auth emails (verification, password reset) **TIDAK BISA** dikirim langsung dari SQL Editor.

**Cara yang benar:**
1. ✅ Flutter Client SDK (Recommended)
2. ✅ Supabase Dashboard UI
3. ✅ Management API via HTTP

---

## 🧪 Test 1: Email Verification

### Method A: Via Flutter Client SDK (Recommended)

```dart
// lib/utils/email_test_helper.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class EmailTestHelper {
  static final supabase = Supabase.instance.client;

  /// Test verification email (resend)
  static Future<void> testVerificationEmail(String email) async {
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      
      print('✅ Verification email sent to: $email');
      print('📧 Check your inbox!');
    } catch (e) {
      print('❌ Error sending verification email: $e');
    }
  }

  /// Test signup (triggers automatic verification email)
  static Future<void> testSignupWithVerification(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        print('✅ User created: ${response.user!.id}');
        print('📧 Verification email sent automatically to: $email');
        print('📬 Check your inbox and click verification link');
      }
    } catch (e) {
      print('❌ Error during signup: $e');
    }
  }
}
```

**Usage in your app:**

```dart
// Test resend verification
await EmailTestHelper.testVerificationEmail('test@example.com');

// Or test full signup flow
await EmailTestHelper.testSignupWithVerification(
  'newuser@example.com',
  'SecurePass123!',
);
```

---

### Method B: Via Supabase Dashboard

1. Login ke [Supabase Dashboard](https://app.supabase.com)
2. Go to **Authentication** → **Users**
3. Click user yang ingin ditest
4. Click **[...]** (three dots)
5. Select **"Send verification email"**

---

## 🔐 Test 2: Password Reset Email

### Method A: Via Flutter Client SDK (Recommended)

```dart
// Add to EmailTestHelper class

/// Test password reset email
static Future<void> testPasswordResetEmail(String email) async {
  try {
    await supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: 'sipelor://reset-password', // Deep link
    );
    
    print('✅ Password reset email sent to: $email');
    print('📧 Check your inbox!');
    print('🔗 Link will redirect to: sipelor://reset-password');
  } catch (e) {
    print('❌ Error sending password reset: $e');
  }
}
```

**Usage:**

```dart
await EmailTestHelper.testPasswordResetEmail('test@example.com');
```

---

### Method B: Via Supabase Dashboard

1. Go to **Authentication** → **Users**
2. Find user by email
3. Click **[...]** (three dots)
4. Select **"Send password reset email"**

---

## 🎫 Test 3: Booking Approved Email (Custom Trigger)

### Via SQL Editor

```sql
-- 1. Create test booking or find existing pending booking
INSERT INTO bookings (
  id,
  user_id,
  venue_id,
  field_id,
  booking_date,
  start_time,
  end_time,
  total_price,
  status
) VALUES (
  gen_random_uuid(),
  'YOUR_USER_ID_HERE',
  'YOUR_VENUE_ID_HERE',
  'YOUR_FIELD_ID_HERE',
  CURRENT_DATE + INTERVAL '1 day',
  '09:00:00',
  '11:00:00',
  150000,
  'pending'
);

-- 2. Approve booking (triggers email notification)
UPDATE bookings
SET status = 'confirmed'
WHERE id = 'BOOKING_ID_FROM_STEP_1'
  AND status = 'pending';

-- 3. Check email notification log
SELECT 
  id,
  email_type,
  recipient_email,
  status,
  metadata,
  created_at
FROM email_notifications
WHERE email_type = 'booking_approved'
ORDER BY created_at DESC
LIMIT 1;
```

**Expected Result:**
```
✓ New row inserted in email_notifications table
✓ status = 'pending'
✓ metadata contains booking details
```

---

## 📊 Test 4: Weekly Revenue Report

### Via SQL Editor

```sql
-- Generate and view report data
SELECT * FROM generate_weekly_revenue_report();
```

**Expected Result:**
```
total_bookings    | 15
confirmed_bookings| 12
total_revenue     | 2450000
avg_booking_value | 204166.67
top_venue         | Lapangan Futsal A
report_period     | 21 Jan - 28 Jan 2026
```

---

## ✅ Complete Test Script for Flutter

Create a test screen in your Flutter app:

```dart
// lib/screens/admin/email_test_screen.dart

import 'package:flutter/material.dart';
import '../../utils/email_test_helper.dart';

class EmailTestScreen extends StatefulWidget {
  const EmailTestScreen({Key? key}) : super(key: key);

  @override
  State<EmailTestScreen> createState() => _EmailTestScreenState();
}

class _EmailTestScreenState extends State<EmailTestScreen> {
  final _emailController = TextEditingController();
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Testing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Test Email',
                hintText: 'your.email@example.com',
              ),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () async {
                setState(() => _result = 'Sending...');
                await EmailTestHelper.testVerificationEmail(
                  _emailController.text,
                );
                setState(() => _result = 'Verification email sent!');
              },
              child: const Text('Test Verification Email'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                setState(() => _result = 'Sending...');
                await EmailTestHelper.testPasswordResetEmail(
                  _emailController.text,
                );
                setState(() => _result = 'Password reset email sent!');
              },
              child: const Text('Test Password Reset'),
            ),
            
            const SizedBox(height: 20),
            
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
```

---

## 📱 Test via Flutter DevTools Console

Quick test without UI:

```dart
// Run in Flutter DevTools console or main.dart (for debugging)

import 'package:supabase_flutter/supabase_flutter.dart';

void testEmails() async {
  final supabase = Supabase.instance.client;
  
  // Test 1: Verification
  await supabase.auth.resend(
    type: OtpType.signup,
    email: 'test@example.com',
  );
  print('✅ Verification email sent');
  
  // Test 2: Password Reset
  await supabase.auth.resetPasswordForEmail('test@example.com');
  print('✅ Password reset email sent');
}
```

---

## 🔍 Verify Email Delivery

### Check Email Logs in Supabase Dashboard

1. Go to **Authentication** → **Logs**
2. Filter by email events
3. Look for:
   - `user.signup` → verification email sent
   - `user.recovery` → password reset sent

### Check Custom Email Notifications Table

```sql
-- View all email notifications
SELECT 
  email_type,
  recipient_email,
  status,
  created_at,
  sent_at,
  error_message
FROM email_notifications
ORDER BY created_at DESC
LIMIT 20;

-- Count by status
SELECT 
  status,
  COUNT(*) as count
FROM email_notifications
GROUP BY status;
```

---

## ⚠️ Troubleshooting

### Email Not Received

1. **Check Spam/Junk folder**
2. **Verify SMTP settings** (if using custom SMTP)
3. **Check rate limits** - Supabase free tier has limits
4. **Verify user exists**:
   ```sql
   SELECT email, confirmed_at 
   FROM auth.users 
   WHERE email = 'test@example.com';
   ```

### Verification Email Says "Already Verified"

```sql
-- Reset user confirmation status (for testing only)
UPDATE auth.users
SET confirmed_at = NULL
WHERE email = 'test@example.com';
```

### Custom Emails Not Sending

1. Check trigger is enabled:
   ```sql
   SELECT * FROM pg_trigger 
   WHERE tgname LIKE '%booking%';
   ```

2. Check function exists:
   ```sql
   SELECT proname FROM pg_proc 
   WHERE proname LIKE '%notify_booking%';
   ```

3. Manually test trigger:
   ```sql
   -- Approve a booking
   UPDATE bookings SET status = 'confirmed' 
   WHERE id = 'xxx' AND status = 'pending';
   
   -- Check log
   SELECT * FROM email_notifications 
   ORDER BY created_at DESC LIMIT 1;
   ```

---

## 📋 Testing Checklist

- [ ] **Verification Email**
  - [ ] Sent via Flutter SDK
  - [ ] Email received in inbox
  - [ ] Link opens app correctly
  - [ ] User becomes verified after click
  
- [ ] **Password Reset Email**
  - [ ] Sent via Flutter SDK
  - [ ] Email received in inbox
  - [ ] Link opens reset password screen
  - [ ] Password updates successfully
  
- [ ] **Booking Approved Email**
  - [ ] Trigger fires on status change
  - [ ] Email log created in database
  - [ ] Contains correct booking details
  
- [ ] **Email Templates**
  - [ ] Renders correctly on Gmail
  - [ ] Renders correctly on mobile
  - [ ] All links work
  - [ ] Images load (if any)

---

## 🚀 Production Checklist

Before going live:

- [ ] Custom SMTP configured (recommended)
- [ ] Email templates finalized
- [ ] Deep links tested on Android & iOS
- [ ] Rate limits understood
- [ ] Email notification preferences setup
- [ ] Monitoring/logging in place

---

**Last Updated**: 28 Januari 2026  
**Maintained By**: Development Team
