# Push Notification Testing Guide

## 🧪 End-to-End Notification Testing

This guide explains how to test the complete notification flow from admin approval to user receiving push notification.

---

## Prerequisites

✅ All requirements should already be met:

1. **Database Setup**: ✅ Notifications table created in Supabase
2. **Platform Config**: ✅ Android & iOS configured
3. **Service Implementation**: ✅ PushNotificationService initialized
4. **Integration**: ✅ NotificationHelper integrated with admin booking flow

---

## Test Scenario 1: Booking Approved Notification

### Step 1: Create a Test Booking (User App)

1. Open the user app (non-admin account)
2. Browse venues and select a field
3. Create a new booking:
   - Select date and time
   - Fill in booking details
   - Submit booking
4. Note the booking ID (e.g., "BOOK001")
5. **Keep the app open** or running in background

### Step 2: Approve Booking (Admin App)

1. Open the admin dashboard (admin account)
2. Navigate to the bookings list/dashboard
3. Find the test booking created in Step 1
4. Change status from **"Pending"** → **"Confirmed"**
5. Click/tap to save the status change

### Step 3: Verify Notification Received (User App)

**User should receive:**

- 📱 **Local Notification** appears on device:
  - Title: "Booking Disetujui! ✅"
  - Body: "Booking Anda untuk [Venue Name] telah disetujui. Silakan lakukan pembayaran."
  - Sound: ✅ (if enabled in settings)
  - Vibration: ✅ (if enabled in settings)

**Console logs to check (Debug mode):**

```
Admin Side:
📝 [UpdateBookingStatus] Updating booking UUID: xxx-xxx-xxx
✅ [UpdateBookingStatus] Booking status updated to: confirmed
✅ [Notification] Booking approved notification sent

User Side:
📡 [PushNotification] New notification received
🔔 [PushNotification] Displaying notification: Booking Disetujui! ✅
🔔 [PushNotification] Sound: true, Vibration: true
```

---

## Test Scenario 2: Booking Rejected Notification

### Step 1: Create Another Test Booking (User App)

1. Create a new booking (same as Test Scenario 1, Step 1)
2. **Keep the app open** or running in background

### Step 2: Reject Booking (Admin App)

1. Open the admin dashboard
2. Find the test booking
3. Change status from **"Pending"** → **"Cancelled"**
4. Click/tap to save

### Step 3: Verify Notification Received (User App)

**User should receive:**

- 📱 **Local Notification**:
  - Title: "Booking Ditolak ❌"
  - Body: "Booking Anda untuk [Venue Name] ditolak."
  - Sound & vibration based on settings

---

## Test Scenario 3: Test with App Closed/Background

### Background Mode Test

1. **User**: Create booking, then **minimize app** (don't close)
2. **Admin**: Approve/reject the booking
3. **Verify**: Notification should still appear via system notification tray

### App Closed Test

1. **User**: Create booking, then **completely close the app** (swipe away)
2. **Admin**: Approve/reject the booking
3. **Verify**: 
   - Notification **will NOT appear** when app is completely closed
   - When user reopens the app, they should see the notification in-app
   - This is expected behavior for Supabase Realtime (requires active connection)

> **Note**: True background push notifications (when app is closed) require Firebase Cloud Messaging (FCM) which is in Phase 2 roadmap.

---

## Test Scenario 4: Notification Preferences

### Test Sound & Vibration Toggle

1. **User**: Go to Settings → Notifikasi
2. **Disable** "Suara Notifikasi"
3. **Admin**: Approve a booking
4. **Verify**: Notification appears but **no sound**

5. **User**: Disable "Getar"
6. **Admin**: Approve another booking
7. **Verify**: Notification appears but **no vibration**

### Test Notification Type Toggle

1. **User**: Go to Settings → Notifikasi
2. **Disable** "Update Booking"
3. **Admin**: Approve a booking
4. **Verify**: **No notification** should appear
5. **User**: Re-enable "Update Booking"
6. **Admin**: Approve another booking
7. **Verify**: Notification appears normally

---

## Test Scenario 5: Multiple Users

1. Create bookings from **2 different user accounts**
2. Approve both bookings from admin
3. **Verify**: Each user receives **only their own** notification

---

## Troubleshooting

### ❌ Notification Not Appearing

**Check:**

1. **User has the app open or in background** (not closed)
2. **Notification permission granted** (Android 13+):
   ```dart
   // Check logs for:
   [PushNotification] Notification permission granted: true/false
   ```
3. **Notification type enabled** in Settings → Notifikasi
4. **Database connection active**:
   ```
   ✅ [Realtime] Subscribed to channel: notifications
   ```

### ❌ Notification Appears But No Sound

**Check:**

1. "Suara Notifikasi" is **enabled** in Settings
2. Device is not in **silent mode**
3. Device volume is **not zero**

### ❌ Wrong Notification Received

**Check:**

1. Verify `userId` in notification matches the logged-in user
2. Check notification type filter in settings

---

## Debugging Commands

### Check Notifications in Database

Run in Supabase SQL Editor:

```sql
-- View all notifications
SELECT * FROM notifications 
ORDER BY created_at DESC 
LIMIT 10;

-- View notifications for specific user
SELECT * FROM notifications 
WHERE user_id = 'your-user-uuid-here'
ORDER BY created_at DESC;

-- Count unread notifications
SELECT COUNT(*) FROM notifications 
WHERE user_id = 'your-user-uuid-here' 
AND read = false;
```

### Clear Test Notifications

```sql
-- Delete all test notifications
DELETE FROM notifications 
WHERE body LIKE '%Test%';

-- Delete all notifications for a user
DELETE FROM notifications 
WHERE user_id = 'your-user-uuid-here';
```

---

## Manual Notification Testing (SQL)

You can manually insert notifications for testing:

```sql
-- Insert test notification
INSERT INTO notifications (user_id, type, title, body, data)
VALUES (
  'your-user-uuid-here',
  'booking_approved',
  'Test Notification 🧪',
  'This is a manual test notification from SQL!',
  '{"test": true, "booking_id": "test-booking-123"}'::jsonb
);
```

User should receive this notification **immediately** if app is open!

---

## Expected Behavior Summary

| Action | Expected Notification | Sound | Vibration |
|--------|----------------------|-------|-----------|
| Admin approves booking | ✅ "Booking Disetujui! ✅" | ✅ (if enabled) | ✅ (if enabled) |
| Admin rejects booking | ✅ "Booking Ditolak ❌" | ✅ (if enabled) | ✅ (if enabled) |
| Admin changes to completed | ❌ No notification | - | - |
| User disables notification type | ❌ No notification | - | - |
| App completely closed | ❌ No notification* | - | - |

\* Requires FCM for true background notifications (Phase 2)

---

## Next Steps After Testing

Once basic notifications are working:

1. ✅ Integrate payment reminder notifications (15 min before expiry)
2. ✅ Integrate review reminder notifications (after booking completed)
3. ✅ Add maintenance schedule notifications
4. ⏳ Implement FCM for true background push (Phase 2)
5. ⏳ Add notification history screen (Phase 2)

---

## Code Flow Reference

### Admin Side (Status Update):

```
Admin changes status
  ↓
RecentBookingTable._updateBookingStatus()
  ↓
SupabaseService.updateBookingStatus()
  ↓
1. Fetch booking details (userId, venueName)
2. Update status in database
3. _sendBookingStatusNotification()
  ↓
NotificationHelper.notifyBookingApproved/Rejected()
  ↓
Insert into notifications table
  ↓
Supabase Realtime broadcasts to clients
```

### User Side (Receive):

```
Supabase Realtime event received
  ↓
PushNotificationService._handleNewNotification()
  ↓
1. Check if notification type is enabled
2. Check sound/vibration preferences
  ↓
FlutterLocalNotifications.show()
  ↓
User sees notification! 🎉
```

---

**Happy Testing! 🚀**

If you encounter any issues, check the console logs for detailed debug information.
