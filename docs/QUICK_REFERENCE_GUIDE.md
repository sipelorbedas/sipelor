# SIPELOR BEDAS - Quick Reference Guide

> **Quick reference untuk developer dan administrator**

---

## 🚀 Quick Start Commands

### Development
```bash
# Run development build
flutter run

# Run with hot reload
flutter run --hot

# Run on specific device
flutter run -d <device-id>

# List devices
flutter devices
```

### Building
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

### Testing
```bash
# All tests
flutter test

# Specific test
flutter test test/services/booking_service_test.dart

# With coverage
flutter test --coverage
```

### Maintenance
```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check outdated packages
flutter pub outdated

# Analyze code
flutter analyze
```

---

## 📁 File Locations

### Configuration Files
- Environment: `.env`
- Dependencies: `pubspec.yaml`
- Build Config: `lib/config/build_config.dart`
- SSL Config: `lib/config/ssl_config.dart`
- Android Build: `android/app/build.gradle.kts`
- iOS Build: `ios/Runner.xcodeproj`

### Key Services
- Supabase: `lib/services/supabase_service.dart`
- Auth: `lib/services/auth_service.dart`
- Booking: `lib/services/booking_service.dart`
- Payment: `lib/services/payment_service.dart`
- Chat: `lib/services/chat_service.dart`
- Analytics: `lib/services/revenue_analytics_service.dart`
- Error Tracking: `lib/services/error_tracking_service.dart`

### Main Screens
- Home: `lib/screens/home_screen.dart`
- Venue List: `lib/screens/venue_list_screen.dart`
- Booking: `lib/screens/booking_confirmation_screen.dart`
- E-Ticket: `lib/screens/e_ticket_screen.dart`
- Profile: `lib/screens/profile_screen.dart`
- Admin Dashboard: `lib/screens/admin_dashboard_screen.dart`

---

## 🔑 Environment Variables

### Required
```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
```

### Optional
```env
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
```

### Production Build
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=SENTRY_DSN=your_dsn
```

---

## 🗄️ Database Quick Reference

### Main Tables
- `auth.users` - User accounts (Supabase Auth)
- `venues` - Sports venues
- `fields` - Individual fields/courts
- `bookings` - User bookings
- `reviews` - Venue reviews
- `staff` - Admin/operator accounts
- `maintenance_schedules` - Maintenance tracking
- `chat_messages` - User-admin messaging
- `report_configs` - Automated report settings

### Common Queries

#### Get User Bookings
```dart
final bookings = await Supabase.instance.client
  .from('bookings')
  .select('*, fields(*), venues(*)')
  .eq('user_id', userId)
  .order('created_at', ascending: false);
```

#### Get Venue with Fields
```dart
final venue = await Supabase.instance.client
  .from('venues')
  .select('*, fields(*)')
  .eq('id', venueId)
  .single();
```

#### Create Booking
```dart
await Supabase.instance.client
  .from('bookings')
  .insert({
    'user_id': userId,
    'field_id': fieldId,
    'booking_date': date,
    'start_time': startTime,
    'end_time': endTime,
    'total_price': price,
    'status': 'pending',
  });
```

---

## 🔐 User Roles & Permissions

### Admin
- Full access to all features
- User management
- System configuration
- Revenue analytics
- Report generation

### Manager
- Assigned venue management
- Booking approval
- Staff oversight
- Venue analytics

### Operator
- Field status updates
- Booking verification
- User support (chat)
- Maintenance logging

### User (Regular)
- Browse venues
- Create bookings
- Upload payments
- Chat with admin
- View history

---

## 🎨 Color Scheme

### Admin Colors (`lib/constants/admin_colors.dart`)
```dart
AdminColors.primary = Color(0xFF4880FF)      // Primary Blue
AdminColors.successGreen = Color(0xFF00B69B) // Success
AdminColors.errorRed = Color(0xFFF93C65)     // Error
AdminColors.warningOrange = Color(0xFFFFA500) // Warning
```

### App Colors (`lib/constants/app_colors.dart`)
```dart
AppColors.primary                // Main brand color
AppColors.secondary              // Secondary color
AppColors.background             // Background
AppColors.surface                // Surface color
AppColors.error                  // Error state
```

---

## 📱 Common Screens Navigation

### User Flow
```dart
// Home → Venue List
Navigator.push(context, MaterialPageRoute(
  builder: (_) => VenueListScreen()
));

// Venue Detail → Booking
Navigator.push(context, MaterialPageRoute(
  builder: (_) => BookingConfirmationScreen(
    venue: venue,
    field: field,
  )
));

// Payment → E-Ticket
Navigator.pushReplacement(context, MaterialPageRoute(
  builder: (_) => ETicketScreen(bookingId: bookingId)
));
```

### Admin Flow
```dart
// Dashboard → Analytics
Navigator.push(context, MaterialPageRoute(
  builder: (_) => AdminRevenueAnalyticsScreen()
));

// Dashboard → Staff Management
Navigator.push(context, MaterialPageRoute(
  builder: (_) => AdminStaffManagementScreen()
));

// Dashboard → Maintenance
Navigator.push(context, MaterialPageRoute(
  builder: (_) => AdminMaintenanceScreen()
));
```

---

## 🛠️ Common Service Calls

### Authentication
```dart
// Sign In
await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);

// Sign Out
await Supabase.instance.client.auth.signOut();

// Get Current User
final user = Supabase.instance.client.auth.currentUser;
```

### File Upload
```dart
// Upload to Storage
final path = await Supabase.instance.client.storage
  .from('bucket-name')
  .upload('file-path', file);

// Get Public URL
final url = Supabase.instance.client.storage
  .from('bucket-name')
  .getPublicUrl('file-path');
```

### Realtime Subscription
```dart
// Subscribe to changes
final subscription = Supabase.instance.client
  .from('chat_messages')
  .stream(primaryKey: ['id'])
  .eq('booking_id', bookingId)
  .listen((data) {
    // Handle new data
  });

// Unsubscribe
subscription.cancel();
```

---

## 🐛 Debugging Tips

### Enable Debug Logging
```dart
if (kDebugMode) {
  print('🐛 Debug message');
  print('✅ Success message');
  print('❌ Error message');
}
```

### Common Debug Commands
```bash
# View logs
flutter logs

# Clear app data (Android)
adb shell pm clear com.bedas.sipelor

# Restart app
flutter run --hot

# Check device info
flutter doctor -v
```

### Performance Profiling
```bash
# Start profiling
flutter run --profile

# Open DevTools
flutter pub global run devtools
```

---

## 📊 Analytics Events

### Track User Events
```dart
// Log to Sentry
ErrorTrackingService.addBreadcrumb(
  message: 'User created booking',
  category: 'user_action',
  data: {'booking_id': bookingId},
);
```

### Track Errors
```dart
// Log error
ErrorTrackingService.logError(
  error,
  stackTrace: stackTrace,
  context: 'Additional context',
);
```

---

## 🔔 Push Notifications

### Send Notification
```dart
await PushNotificationService.showNotification(
  title: 'Booking Confirmed',
  body: 'Your booking has been confirmed',
  payload: bookingId,
);
```

### Schedule Notification
```dart
await PushNotificationService.scheduleNotification(
  title: 'Reminder',
  body: 'Your booking is tomorrow',
  scheduledDate: DateTime.now().add(Duration(hours: 24)),
);
```

---

## 🧪 Testing Checklist

### Before Release
- [ ] Run all tests: `flutter test`
- [ ] Check code quality: `flutter analyze`
- [ ] Test on physical devices (Android & iOS)
- [ ] Test all user flows
- [ ] Test admin features
- [ ] Verify email notifications
- [ ] Test payment flow
- [ ] Check error handling
- [ ] Verify security features
- [ ] Test offline scenarios
- [ ] Check performance
- [ ] Review logs for errors

### Security Checklist
- [ ] SSL pinning enabled
- [ ] Sensitive data encrypted
- [ ] Rate limiting active
- [ ] Audit logging working
- [ ] Auto-logout functional
- [ ] Biometric auth tested
- [ ] Email verification enforced
- [ ] Password requirements met

---

## 🚨 Emergency Procedures

### App Crashes in Production
1. Check Sentry dashboard for crash reports
2. Identify affected users and versions
3. Reproduce the crash in dev environment
4. Fix and test thoroughly
5. Release hotfix update

### Database Issues
1. Check Supabase status page
2. Review database logs
3. Check RLS policies
4. Verify connection settings
5. Contact Supabase support if needed

### Payment Issues
1. Check payment proof uploads
2. Verify storage bucket permissions
3. Check booking status in database
4. Manual verification if needed
5. Notify user of status

---

## 📞 Support Contacts

### Technical Support
- **Developer Team**: dev-team@sipelor-bedas.com
- **Sentry Dashboard**: https://sentry.io/organizations/your-org
- **Supabase Dashboard**: https://app.supabase.com

### Business Support
- **DISPORA**: dispora@bandungkab.go.id
- **Admin Help**: admin@sipelor-bedas.com

---

## 📚 Documentation Links

- [Main Documentation](./PROJECT_DOCUMENTATION.md)
- [Features Status](./FEATURES_IMPLEMENTATION_STATUS.md)
- [Admin Features](./ADMIN_FEATURES_IMPLEMENTATION_SUMMARY.md)
- [Security Guide](./DATA_ENCRYPTION_IMPLEMENTATION.md)
- [Sentry Setup](./SENTRY_SETUP_GUIDE.md)
- [Push Notifications](./PUSH_NOTIFICATIONS_IMPLEMENTATION.md)
- [Database Setup](./DATABASE_SETUP_ADMIN_FEATURES.sql)

---

## 🔄 Version History

### v1.0.0+1 (Current)
- Initial release
- User booking system
- Admin dashboard
- Payment verification
- E-ticket generation
- Real-time chat
- Revenue analytics
- Staff management
- Maintenance scheduling
- Security features

---

**Last Updated**: 26 Januari 2026  
**Quick Reference Version**: 1.0
