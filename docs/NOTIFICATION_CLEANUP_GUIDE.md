# Notification Auto-Cleanup Service

## Overview

Service untuk otomatis menghapus notifikasi lama dari database agar tidak memenuhi storage. Notifikasi yang sudah lebih dari 24 jam akan dihapus secara otomatis.

## Features

✅ Auto-delete notifications older than 24 hours  
✅ Periodic cleanup every 6 hours  
✅ Manual cleanup on-demand  
✅ Statistics and monitoring  
✅ Debug logging for tracking  

## Configuration

### Default Settings

```dart
NotificationCleanupService.initialize(
  hoursOld: 24,              // Delete notifications older than 24 hours
  checkIntervalHours: 6,     // Run cleanup every 6 hours
);
```

### Custom Settings

```dart
// Delete notifications older than 48 hours, check every 12 hours
NotificationCleanupService.initialize(
  hoursOld: 48,
  checkIntervalHours: 12,
);
```

## How It Works

### Auto-Cleanup Flow

```
App Start
   ↓
Initialize Service
   ↓
Run Immediate Cleanup ← Deletes old notifications immediately
   ↓
Schedule Periodic Cleanup
   ↓
Every 6 hours → Run Cleanup
   ↓
Count old notifications
   ↓
Delete from database
   ↓
Log results
```

### Timeline Example

```
Time 0:00  → App starts, cleanup runs (deletes notifications > 24h old)
Time 6:00  → Cleanup runs again
Time 12:00 → Cleanup runs again
Time 18:00 → Cleanup runs again
Time 24:00 → Cleanup runs again (full day cycle)
```

## Usage

### Automatic Cleanup (Default)

Already initialized in `main.dart`:

```dart
// Runs automatically in background
NotificationCleanupService.initialize(
  hoursOld: 24, 
  checkIntervalHours: 6
);
```

### Manual Cleanup

Trigger cleanup manually (useful for testing or admin tools):

```dart
// Delete notifications older than 24 hours
final deletedCount = await NotificationCleanupService.manualCleanup(
  hoursOld: 24,
);
print('Deleted $deletedCount notifications');
```

### Get Statistics

Check notification statistics:

```dart
final stats = await NotificationCleanupService.getStatistics();

print('Total notifications: ${stats['total']}');
print('Unread: ${stats['unread']}');
print('Read: ${stats['read']}');
print('Recent (24h): ${stats['recent_24h']}');
print('Old (>24h): ${stats['older_than_24h']}');
```

### Stop Service

Stop auto-cleanup (usually not needed):

```dart
NotificationCleanupService.dispose();
```

## Database Impact

### Storage Savings

**Scenario: 1000 active users**
- Average: 5 notifications per user per day
- Total: 5,000 notifications/day

**Without cleanup:**
- 1 week: 35,000 notifications
- 1 month: 150,000 notifications
- 1 year: 1,825,000 notifications

**With 24-hour cleanup:**
- Max: ~5,000 notifications (1 day worth)
- Storage saved: **97% reduction**

### RLS Policy Required

Make sure your database has delete policy:

```sql
-- Allow system to delete old notifications
CREATE POLICY "System can delete old notifications"
ON notifications FOR DELETE
USING (
  -- Only allow deletion of notifications older than 23 hours
  -- (1 hour buffer to ensure 24-hour cleanup doesn't fail)
  created_at < NOW() - INTERVAL '23 hours'
);

-- Or allow users to delete their own notifications
CREATE POLICY "Users can delete own notifications"
ON notifications FOR DELETE
USING (auth.uid() = user_id);
```

## Console Logs

### Initialization
```
🧹 [NotificationCleanup] Initializing auto-cleanup service
🧹 [NotificationCleanup] Will delete notifications older than 24 hours
🧹 [NotificationCleanup] Check interval: every 6 hours
🧹 [NotificationCleanup] Starting cleanup...
🧹 [NotificationCleanup] Cutoff time: 2026-02-01T10:00:00.000Z
🧹 [NotificationCleanup] Found 234 notifications to delete
✅ [NotificationCleanup] Successfully deleted 234 old notifications
✅ [NotificationCleanup] Auto-cleanup service initialized
```

### Periodic Cleanup
```
🧹 [NotificationCleanup] Starting cleanup...
🧹 [NotificationCleanup] Cutoff time: 2026-02-01T16:00:00.000Z
🧹 [NotificationCleanup] Found 87 notifications to delete
✅ [NotificationCleanup] Successfully deleted 87 old notifications
```

### No Cleanup Needed
```
🧹 [NotificationCleanup] Starting cleanup...
🧹 [NotificationCleanup] Cutoff time: 2026-02-01T22:00:00.000Z
✅ [NotificationCleanup] No old notifications to delete
```

### Manual Cleanup
```
🧹 [NotificationCleanup] Manual cleanup triggered
🧹 [NotificationCleanup] Deleting notifications older than 24 hours
✅ [NotificationCleanup] Deleted 156 notifications
```

### Statistics
```
📊 [NotificationCleanup] Statistics:
   Total: 3,452
   Unread: 1,234
   Read: 2,218
   Recent (24h): 3,452
   Old (>24h): 0
```

## Testing

### Test Auto-Cleanup

1. **Create test notifications**
   ```dart
   // Create notifications with old timestamps (for testing)
   await supabase.from('notifications').insert({
     'user_id': userId,
     'type': 'general',
     'title': 'Old Test Notification',
     'body': 'This should be deleted',
     'is_read': true,
     'created_at': DateTime.now()
         .subtract(Duration(hours: 25))
         .toIso8601String(),
   });
   ```

2. **Trigger manual cleanup**
   ```dart
   final deleted = await NotificationCleanupService.manualCleanup();
   print('Deleted $deleted old notifications');
   ```

3. **Check results**
   ```dart
   final stats = await NotificationCleanupService.getStatistics();
   print('Old notifications remaining: ${stats['older_than_24h']}');
   // Should be 0
   ```

### Test Periodic Cleanup

Change interval to 1 minute for testing:

```dart
// TESTING ONLY - Don't use in production
NotificationCleanupService.initialize(
  hoursOld: 24,
  checkIntervalHours: 0, // Will use minimum interval
);
```

Then modify the service to use minutes:

```dart
// In notification_cleanup_service.dart (for testing only)
_cleanupTimer = Timer.periodic(
  Duration(minutes: 1), // Changed from hours
  (_) => _performCleanup(hoursOld),
);
```

## Admin Tools Integration

### Add Cleanup Button to Admin Dashboard

```dart
ElevatedButton(
  onPressed: () async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    final deleted = await NotificationCleanupService.manualCleanup();
    
    Navigator.pop(context); // Close loading
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🧹 Deleted $deleted old notifications'),
        backgroundColor: Colors.green,
      ),
    );
  },
  child: const Text('Clean Old Notifications'),
),
```

### Add Statistics Widget

```dart
FutureBuilder<Map<String, dynamic>>(
  future: NotificationCleanupService.getStatistics(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }
    
    final stats = snapshot.data!;
    
    return Column(
      children: [
        Text('Total: ${stats['total']}'),
        Text('Unread: ${stats['unread']}'),
        Text('Recent (24h): ${stats['recent_24h']}'),
        Text('Old (>24h): ${stats['older_than_24h']}'),
      ],
    );
  },
),
```

## Troubleshooting

### Cleanup Not Running

**Check 1: Is service initialized?**
```dart
print('Service running: ${NotificationCleanupService.isInitialized}');
```

**Check 2: Check logs**
Look for initialization message in console:
```
✅ [NotificationCleanup] Auto-cleanup service initialized
```

**Check 3: RLS Policy**
Make sure database allows delete operations.

### Notifications Not Being Deleted

**Check 1: Timestamp format**
Ensure `created_at` uses ISO 8601 format:
```
2026-02-01T10:30:00.000Z ✅
2026-02-01 10:30:00 ❌
```

**Check 2: Timezone issues**
Service uses UTC. Ensure database timestamps are UTC.

**Check 3: Database permissions**
Test manual delete in SQL:
```sql
DELETE FROM notifications 
WHERE created_at < NOW() - INTERVAL '24 hours';
```

### Performance Issues

**If cleanup takes too long:**

1. **Add index on created_at**
   ```sql
   CREATE INDEX idx_notifications_created_at 
   ON notifications(created_at);
   ```

2. **Batch delete**
   Modify service to delete in batches of 1000:
   ```dart
   // In _performCleanup
   await _supabase
       .from('notifications')
       .delete()
       .lt('created_at', cutoffString)
       .limit(1000);
   ```

## Customization

### Different Cleanup Rules

**Keep important notifications longer:**

```dart
// Only cleanup read notifications older than 24 hours
// Keep unread notifications for 7 days
await _supabase
    .from('notifications')
    .delete()
    .lt('created_at', cutoffString)
    .eq('is_read', true);  // Only delete read ones
```

**Keep certain notification types:**

```dart
// Don't delete booking-related notifications
await _supabase
    .from('notifications')
    .delete()
    .lt('created_at', cutoffString)
    .not('type', 'in', '(booking_approved,booking_rejected)');
```

## Best Practices

1. ✅ **Monitor cleanup logs** - Check periodically to ensure cleanup is working
2. ✅ **Backup before major changes** - Backup database before modifying cleanup logic
3. ✅ **Test in development first** - Test cleanup behavior in dev environment
4. ✅ **Set appropriate intervals** - 6 hours is good balance between storage and performance
5. ✅ **Add database indexes** - Index `created_at` column for faster cleanup
6. ✅ **Monitor database size** - Track database growth over time
7. ✅ **Document retention policy** - Make it clear to users how long notifications are kept

## Files Modified

- ✅ `lib/services/notification_cleanup_service.dart` (NEW)
- ✅ `lib/main.dart` (Added initialization)
- ✅ `NOTIFICATION_CLEANUP_GUIDE.md` (NEW)

## Summary

Auto-cleanup service ensures your database stays efficient by:
- Automatically deleting notifications older than 24 hours
- Running cleanup every 6 hours
- Saving 97% database storage compared to no cleanup
- Providing manual cleanup and statistics for monitoring

No action needed from users - it runs automatically in background! 🚀
