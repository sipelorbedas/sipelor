# SIPELOR BEDAS - Project Documentation

> **Sistem Pemesanan Lapangan Olahraga DISPORA Kabupaten Bandung**
> 
> Complete Sports Field Booking Management System

**Version**: 1.0.0+1  
**Last Updated**: 26 Januari 2026  
**Platform**: Flutter (Android, iOS, Web, Desktop)  
**Backend**: Supabase (PostgreSQL + Realtime + Auth + Storage)

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Technology Stack](#technology-stack)
4. [Project Architecture](#project-architecture)
5. [Project Structure](#project-structure)
6. [Getting Started](#getting-started)
7. [Configuration](#configuration)
8. [User Features](#user-features)
9. [Admin Features](#admin-features)
10. [Security Features](#security-features)
11. [Development Guide](#development-guide)
12. [Testing Guide](#testing-guide)
13. [Deployment Guide](#deployment-guide)
14. [API Documentation](#api-documentation)
15. [Troubleshooting](#troubleshooting)
16. [Contributing](#contributing)

---

## 🎯 Project Overview

SIPELOR BEDAS adalah aplikasi mobile dan web untuk manajemen pemesanan lapangan olahraga di Kabupaten Bandung. Aplikasi ini dikembangkan untuk DISPORA (Dinas Pemuda dan Olahraga) dengan tujuan:

- **Mempermudah masyarakat** melakukan booking lapangan olahraga secara online
- **Meningkatkan efisiensi** pengelolaan venue dan lapangan olahraga
- **Menyediakan data analytics** untuk pengambilan keputusan
- **Meningkatkan transparansi** melalui sistem payment verification
- **Memfasilitasi komunikasi** antara pengguna dan admin

### Target Users

1. **Masyarakat Umum**: Pengguna yang ingin booking lapangan olahraga
2. **Admin DISPORA**: Mengelola venue, lapangan, booking, dan staff
3. **Staff Operator**: Mengelola operasional lapangan tertentu
4. **Manager**: Mengawasi performa venue yang ditugaskan

---

## ✨ Key Features

### For Users (Masyarakat)

#### 🏟️ Venue & Field Management
- Browse available venues (Futsal, Badminton, Basket, Tennis, Volley, etc.)
- View venue details, photos, facilities, and ratings
- Filter venues by type, location, price range
- Check field availability in real-time
- View time slots and pricing

#### 📅 Booking System
- Easy booking flow with date and time selection
- Multiple payment methods support
- E-ticket generation with QR code
- Booking history and status tracking
- Download and share e-tickets
- Push notifications for booking updates

#### 💳 Payment Verification
- Upload payment proof
- Track payment status (pending, verified, rejected)
- Secure payment data handling
- Payment confirmation notifications

#### 🎫 E-Ticket System
- Auto-generated QR code
- Booking details and venue information
- Download as image or share
- Venue staff can scan for verification

#### 👤 Profile Management
- Personal information management
- Profile photo upload
- Email and phone verification
- Password management (change, reset)
- Biometric authentication setup
- Security settings

#### 💬 Customer Support
- Real-time chat with admin
- Booking-specific conversations
- Image attachments support
- Chat history

#### ⭐ Review System
- Rate and review venues
- View other users' reviews
- Filter reviews by rating
- Admin moderation

#### 🔒 Security Features
- Email verification enforcement
- Two-factor authentication (Biometric)
- Secure data encryption
- SSL certificate pinning
- Auto-logout on inactivity
- Security tips and education

### For Admin

#### 📊 Dashboard & Analytics
- Overview statistics (bookings, revenue, users)
- Revenue analytics with charts
- Booking trends analysis
- Venue performance metrics
- Export data to CSV
- Automated email reports (daily/weekly/monthly)

#### 🏢 Venue Management
- Create, edit, delete venues
- Upload venue photos
- Manage facilities and amenities
- Set operating hours
- Assign staff to venues

#### 🏃 Field Management
- Create multiple fields per venue
- Set field types and sizes
- Dynamic pricing by time slot
- Field availability status
- Maintenance mode

#### 📆 Booking Management
- View all bookings (pending, confirmed, cancelled)
- Approve/reject bookings
- Manual booking creation
- Bulk operations (approve, reject, delete)
- Booking notifications

#### 💰 Payment Management
- Verify payment proofs
- Approve/reject payments
- Payment history
- Revenue reports by venue/type/period

#### 👥 Staff Management
- Create staff accounts (Admin, Manager, Operator)
- Assign venues to staff
- Role-based access control
- Staff activity tracking
- Enable/disable staff accounts

#### 🔧 Maintenance Scheduling
- Schedule venue/field maintenance
- Set maintenance duration
- Assign staff to maintenance tasks
- Track maintenance status
- Automatic field status updates

#### 💬 Chat Management
- View all user conversations
- Real-time messaging
- Unread message indicators
- Booking context in chats

#### 📝 Audit Logs
- User activity tracking
- Security event logging
- Login/logout history
- Failed authentication attempts
- Data modification logs

#### 🔍 Review Moderation
- View all reviews
- Approve/reject reviews
- Delete inappropriate reviews
- Respond to reviews

---

## 🛠️ Technology yang digunakan

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| **Flutter** | SDK ^3.10.3 | Cross-platform UI framework |
| **Dart** | ^3.10.3 | Programming language |
| **Google Fonts** | ^7.0.2 | Typography |
| **Flutter SVG** | ^2.2.3 | SVG rendering |

### Backend & Services

| Technology | Version | Purpose |
|------------|---------|---------|
| **Supabase** | ^2.5.0 | Backend-as-a-Service |
| ↳ PostgreSQL | Latest | Database |
| ↳ Realtime | Latest | WebSocket connections |
| ↳ Auth | Latest | Authentication |
| ↳ Storage | Latest | File storage |
| **Sentry** | ^8.11.0 | Error tracking & monitoring |

### Security

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_secure_storage** | ^9.2.2 | Encrypted local storage |
| **local_auth** | ^2.3.0 | Biometric authentication |
| **crypto** | ^3.0.5 | Cryptographic operations |
| **encrypt** | ^5.0.3 | Data encryption |
| **http_certificate_pinning** | ^2.1.2 | SSL pinning |

### UI & UX

| Package | Version | Purpose |
|---------|---------|---------|
| **qr_flutter** | ^4.1.0 | QR code generation |
| **fl_chart** | ^0.69.0 | Charts & graphs |
| **file_picker** | ^8.1.6 | File selection |
| **screenshot** | ^3.0.0 | Screenshot capture |
| **intl** | ^0.19.0 | Internationalization |

### Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| **shared_preferences** | ^2.3.5 | Simple local storage |
| **path_provider** | ^2.1.5 | Path utilities |
| **url_launcher** | ^6.3.2 | Launch URLs |
| **permission_handler** | ^11.3.1 | Device permissions |
| **flutter_dotenv** | ^6.0.0 | Environment variables |
| **csv** | ^6.0.0 | CSV export |

### Notifications

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_local_notifications** | ^18.0.1 | Local notifications |
| **flutter_ringtone_player** | ^4.0.0+3 | Notification sounds |
| **vibration** | ^2.0.0 | Haptic feedback |

### HTTP & API

| Package | Version | Purpose |
|---------|---------|---------|
| **dio** | ^5.4.1 | HTTP client |
| **supabase_flutter** | ^2.5.0 | Supabase SDK |

---

## 🏗️ Project Architecture

### Clean Architecture Pattern

```
┌─────────────────────────────────────────────┐
│          Presentation Layer                 │
│  (Screens, Widgets, State Management)       │
├─────────────────────────────────────────────┤
│          Business Logic Layer               │
│         (Services, Use Cases)               │
├─────────────────────────────────────────────┤
│          Data Layer                         │
│  (Models, Repositories, Data Sources)       │
├─────────────────────────────────────────────┤
│          External Services                  │
│  (Supabase, Sentry, Storage, etc.)          │
└─────────────────────────────────────────────┘
```

### Database Schema (Simplified)

```
Users (Supabase Auth)
  ↓
Bookings ← Reviews
  ↓
Fields → Venues
  ↓
Time Slots

Staff → Assigned Venues
  ↓
Maintenance Schedules → Fields

Chat Messages → Bookings
```

### Data Flow

```
User Action
    ↓
Screen/Widget
    ↓
Service Layer (Business Logic)
    ↓
Supabase Client (API)
    ↓
PostgreSQL Database
    ↓
Real-time Subscriptions (if applicable)
    ↓
UI Update
```

---

## 📁 Project Structure

```
sipelor/
├── android/              # Android-specific configuration
│   ├── app/
│   │   └── build.gradle.kts  # Android build config
│   └── gradle.properties
├── ios/                  # iOS-specific configuration
├── web/                  # Web-specific configuration
├── lib/                  # Main application code
│   ├── config/          # App configuration
│   │   ├── build_config.dart
│   │   └── ssl_config.dart
│   ├── constants/       # Constants and colors
│   │   ├── admin_colors.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── models/          # Data models
│   │   ├── booking.dart
│   │   ├── venue.dart
│   │   ├── field.dart
│   │   ├── user_role.dart
│   │   ├── staff.dart
│   │   ├── chat_message.dart
│   │   ├── maintenance_schedule.dart
│   │   ├── revenue_analytics.dart
│   │   └── ...
│   ├── screens/         # UI screens (36 screens)
│   │   ├── splash_screen.dart
│   │   ├── sign_in_screen.dart
│   │   ├── sign_up_screen.dart
│   │   ├── home_screen.dart
│   │   ├── venue_list_screen.dart
│   │   ├── venue_detail_screen.dart
│   │   ├── booking_confirmation_screen.dart
│   │   ├── payment_confirmation_screen.dart
│   │   ├── e_ticket_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_revenue_analytics_screen.dart
│   │   ├── admin_staff_management_screen.dart
│   │   ├── admin_maintenance_screen.dart
│   │   ├── admin_chat_screen.dart
│   │   └── ...
│   ├── services/        # Business logic services (25 services)
│   │   ├── supabase_service.dart
│   │   ├── auth_service.dart
│   │   ├── booking_service.dart
│   │   ├── payment_service.dart
│   │   ├── venue_service.dart
│   │   ├── field_service.dart
│   │   ├── staff_service.dart
│   │   ├── chat_service.dart
│   │   ├── maintenance_service.dart
│   │   ├── revenue_analytics_service.dart
│   │   ├── automated_reports_service.dart
│   │   ├── bulk_operations_service.dart
│   │   ├── notification_service.dart
│   │   ├── push_notification_service.dart
│   │   ├── email_verification_service.dart
│   │   ├── password_service.dart
│   │   ├── biometric_auth_service.dart
│   │   ├── secure_storage_service.dart
│   │   ├── encrypted_preferences_service.dart
│   │   ├── file_encryption_service.dart
│   │   ├── pinned_http_client.dart
│   │   ├── error_tracking_service.dart
│   │   ├── audit_service.dart
│   │   ├── rate_limiter_service.dart
│   │   ├── security_event_notification_service.dart
│   │   └── auto_logout_service.dart
│   ├── widgets/         # Reusable widgets
│   │   ├── auto_logout_wrapper.dart
│   │   ├── email_verification_banner.dart
│   │   └── ...
│   ├── utils/           # Utility functions
│   └── main.dart        # App entry point
├── assets/              # Static assets
│   ├── icons/
│   └── images/
├── docs/                # Documentation (17 files)
│   ├── PROJECT_DOCUMENTATION.md
│   ├── FEATURES_IMPLEMENTATION_STATUS.md
│   ├── ADMIN_FEATURES_IMPLEMENTATION_SUMMARY.md
│   ├── DATABASE_SETUP_ADMIN_FEATURES.sql
│   ├── SENTRY_SETUP_GUIDE.md
│   ├── SSL_CERTIFICATE_PINNING.md
│   ├── SECURITY_EVENT_NOTIFICATIONS.md
│   ├── PUSH_NOTIFICATIONS_IMPLEMENTATION.md
│   ├── DATA_ENCRYPTION_IMPLEMENTATION.md
│   ├── GOOGLE_OAUTH_SETUP.md
│   └── ...
├── scripts/             # Build and deployment scripts
│   ├── build_production.ps1
│   ├── build_production.sh
│   ├── test_security.sh
│   └── verify_security.sh
├── .env                 # Environment variables (not committed)
├── pubspec.yaml         # Dependencies
└── README.md            # Basic readme
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: ^3.10.3 or higher
- **Dart SDK**: ^3.10.3 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Git**
- **Supabase Account** (free tier available)

### Installation Steps

#### 1. Clone the Repository

```bash
git clone https://github.com/your-org/sipelor-bedas.git
cd sipelor-bedas
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Setup Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Go to **Project Settings** → **API**
3. Copy your **Project URL** and **anon public** key

#### 4. Configure Environment Variables

Create a `.env` file in the root directory:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

#### 5. Setup Database

1. Go to Supabase Dashboard → **SQL Editor**
2. Run the SQL scripts from `docs/DATABASE_SETUP_ADMIN_FEATURES.sql`
3. Create required tables for bookings, venues, fields, etc.

#### 6. Configure Supabase Storage

1. Go to **Storage** section in Supabase
2. Create buckets:
   - `profile-avatars` (public)
   - `venue-photos` (public)
   - `payment-proofs` (private)

#### 7. Run the Application

**Development mode:**
```bash
flutter run
```

**Production build:**
```bash
# Android
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key

# iOS
flutter build ios --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## ⚙️ Configuration

### Environment Variables

The app supports two configuration methods:

#### Development (using .env file)
```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=eyJxxx...
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx
```

#### Production (using --dart-define)
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key \
  --dart-define=SENTRY_DSN=your_sentry_dsn
```

### Build Configurations

Edit `lib/config/build_config.dart` for:
- API endpoints
- Feature flags
- Build-specific settings

### Security Configurations

Edit `lib/config/ssl_config.dart` for:
- SSL certificate pins
- Allowed hosts
- Certificate fingerprints

---

## 👤 User Features

### Authentication Flow

```
Sign Up → Email Verification → Profile Setup → Home
                                      ↓
                              Enable Biometric (Optional)
```

### Booking Flow

```
Browse Venues → Select Venue → View Fields → Choose Time Slot
     ↓
Select Field → Confirm Booking → Upload Payment → Get E-Ticket
     ↓
Receive Notifications → Chat with Admin (if issues) → Complete
```

### Profile Management

Users can:
- Update personal information
- Change password
- Enable biometric authentication
- View booking history
- Download e-tickets
- Manage notification settings
- View security logs

---

## 👨‍💼 Admin Features

### Dashboard Overview

The admin dashboard provides:
- Total bookings (today, this week, this month)
- Revenue statistics
- Pending payment verifications
- Recent bookings list
- Quick actions

### Revenue Analytics

Detailed analytics including:
- Total revenue breakdown (confirmed vs pending)
- Revenue by venue type
- Revenue by venue
- Daily revenue trends (chart)
- Average booking value
- Conversion rates
- Top performing venues

### Staff Management

Admins can:
- Create staff accounts with roles:
  - **Admin**: Full access
  - **Manager**: Venue management
  - **Operator**: Field operations
- Assign venues to staff
- Enable/disable staff accounts
- Track staff login activity

### Maintenance Scheduling

Features:
- Schedule maintenance for venues/fields
- Set start and end dates
- Assign staff to maintenance tasks
- Track maintenance status
- Auto-update field availability

### Chat Management

Admins can:
- View all active conversations
- See unread message counts
- Respond to user queries
- Send images (if needed)
- View chat history per booking

### Bulk Operations

Efficient bulk actions for:
- Approve multiple bookings
- Reject multiple bookings
- Update field prices
- Update field status
- Export data to CSV

### Automated Reports

Configure automated email reports:
- **Daily reports** (sent at 8 AM)
- **Weekly reports** (sent every Monday)
- **Monthly reports** (sent on 1st of month)
- Customizable recipients
- Revenue, booking, and performance reports

---

## 🔒 Security Features

### Authentication Security

- **Email Verification**: Required before booking
- **Password Requirements**: Min 8 chars, uppercase, lowercase, number
- **Rate Limiting**: 3 failed login attempts = 1 hour lockout
- **Session Management**: Auto-logout after 15 minutes of inactivity
- **Biometric Authentication**: Optional fingerprint/face ID

### Data Security

- **Encryption at Rest**: Sensitive data encrypted using AES-256
- **Encryption in Transit**: SSL/TLS with certificate pinning
- **Secure Storage**: flutter_secure_storage for sensitive data
- **File Encryption**: Payment proofs and documents encrypted
- **Password Hashing**: Handled by Supabase Auth (bcrypt)

### Network Security

- **SSL Pinning**: Prevents man-in-the-middle attacks
- **Certificate Validation**: Only trusted certificates allowed
- **Secure HTTP**: All API calls over HTTPS only

### Monitoring & Logging

- **Audit Logs**: All user actions tracked
- **Security Events**: Login attempts, password changes logged
- **Error Tracking**: Sentry integration for crash reports
- **Real-time Alerts**: Security event notifications

### Privacy & Compliance

- **Data Minimization**: Only collect necessary data
- **User Consent**: Terms and Privacy Policy acceptance
- **Data Portability**: Users can export their data
- **Right to Delete**: Users can request data deletion
- **Secure Deletion**: Proper data cleanup on account deletion

---

## 💻 Development Guide

### Code Organization

Follow this structure:
```dart
// 1. Imports (grouped)
import 'package:flutter/material.dart';        // Flutter
import 'package:provider/provider.dart';       // Third-party
import '../models/booking.dart';               // Local

// 2. Class definition
class MyScreen extends StatefulWidget {
  final String requiredParam;
  
  const MyScreen({
    super.key,
    required this.requiredParam,
  });
  
  @override
  State<MyScreen> createState() => _MyScreenState();
}

// 3. State class
class _MyScreenState extends State<MyScreen> {
  // State variables
  
  @override
  void initState() {
    super.initState();
    // Initialize
  }
  
  // Private methods
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI
    );
  }
}
```

### Naming Conventions

- **Files**: snake_case (e.g., `booking_service.dart`)
- **Classes**: PascalCase (e.g., `BookingService`)
- **Variables**: camelCase (e.g., `totalBookings`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_RETRIES`)
- **Private**: prefix with `_` (e.g., `_privateMethod()`)

### State Management

Currently using **StatefulWidget** with basic state management.

Future enhancement: Consider **Provider**, **Riverpod**, or **Bloc**.

### API Service Pattern

```dart
class MyService {
  static final SupabaseClient _client = Supabase.instance.client;
  
  static Future<List<MyModel>> fetchAll() async {
    try {
      final response = await _client
          .from('my_table')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => MyModel.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error: $e');
      }
      rethrow;
    }
  }
}
```

### Error Handling

```dart
try {
  // Risky operation
  await someAsyncOperation();
} on PostgrestException catch (e) {
  // Supabase specific error
  ErrorTrackingService.logError(e, context: 'PostgrestError');
  _showError('Database error occurred');
} on AuthException catch (e) {
  // Auth specific error
  _showError('Authentication failed: ${e.message}');
} catch (e, stackTrace) {
  // Generic error
  ErrorTrackingService.logError(e, stackTrace: stackTrace);
  _showError('An error occurred');
}
```

### Testing

Write tests for:
- Models (serialization/deserialization)
- Services (business logic)
- Widgets (UI components)

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/booking_test.dart

# Run with coverage
flutter test --coverage
```

---

## 🧪 Testing Guide

### Unit Testing

Test business logic and services:

```dart
// test/services/booking_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/booking_service.dart';

void main() {
  group('BookingService', () {
    test('should calculate correct price', () {
      final result = BookingService.calculatePrice(
        hours: 2,
        pricePerHour: 50000,
      );
      expect(result, 100000);
    });
  });
}
```

### Widget Testing

Test UI components:

```dart
// test/widgets/email_verification_banner_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/widgets/email_verification_banner.dart';

void main() {
  testWidgets('should show banner when email not verified', 
    (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EmailVerificationBanner(isVerified: false),
      ),
    );
    
    expect(find.text('Email belum terverifikasi'), findsOneWidget);
  });
}
```

### Integration Testing

Test complete user flows:

```dart
// integration_test/booking_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('complete booking flow', (WidgetTester tester) async {
    // Launch app
    // Navigate to venue
    // Select field
    // Confirm booking
    // Verify success
  });
}
```

### Manual Testing Checklist

#### User Flow Testing
- [ ] Sign up with new account
- [ ] Verify email
- [ ] Browse venues
- [ ] Create booking
- [ ] Upload payment proof
- [ ] Receive e-ticket
- [ ] View booking history
- [ ] Chat with admin
- [ ] Leave review

#### Admin Flow Testing
- [ ] Login as admin
- [ ] View dashboard
- [ ] Verify payment
- [ ] Approve booking
- [ ] View analytics
- [ ] Create staff
- [ ] Schedule maintenance
- [ ] Respond to chat
- [ ] Generate reports

#### Security Testing
- [ ] Test rate limiting
- [ ] Test auto-logout
- [ ] Test biometric auth
- [ ] Test SSL pinning
- [ ] Test data encryption
- [ ] Test audit logging

---

## 🚀 Deployment Guide

### Android Deployment

#### 1. Generate Signing Key

```bash
keytool -genkey -v -keystore sipelor-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sipelor
```

#### 2. Configure Signing

Edit `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=sipelor
storeFile=../sipelor-release-key.jks
```

#### 3. Build Release APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_production_url \
  --dart-define=SUPABASE_ANON_KEY=your_production_key \
  --dart-define=SENTRY_DSN=your_sentry_dsn
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### 4. Build App Bundle (for Google Play)

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=your_production_url \
  --dart-define=SUPABASE_ANON_KEY=your_production_key
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS Deployment

#### 1. Configure Xcode

- Open `ios/Runner.xcworkspace` in Xcode
- Update Bundle Identifier
- Configure signing team
- Add required capabilities

#### 2. Build Release IPA

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=your_production_url \
  --dart-define=SUPABASE_ANON_KEY=your_production_key
```

#### 3. Archive and Upload to App Store

- Use Xcode to archive
- Upload to App Store Connect

### Web Deployment

#### 1. Build Web App

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=your_production_url \
  --dart-define=SUPABASE_ANON_KEY=your_production_key
```

#### 2. Deploy to Hosting

Deploy `build/web` to:
- Firebase Hosting
- Netlify
- Vercel
- GitHub Pages

### Production Checklist

- [ ] Update version number in `pubspec.yaml`
- [ ] Update app icons and splash screen
- [ ] Configure production environment variables
- [ ] Setup Sentry for production
- [ ] Configure SSL pinning with production certificates
- [ ] Test all critical flows
- [ ] Setup automated reports
- [ ] Configure push notifications
- [ ] Setup analytics
- [ ] Prepare release notes
- [ ] Create app store listings
- [ ] Submit for review

---

## 📚 API Documentation

### Supabase Tables

#### Users
Managed by Supabase Auth
```sql
auth.users (
  id uuid PRIMARY KEY,
  email text,
  phone text,
  created_at timestamp,
  ...
)
```

#### Venues
```sql
venues (
  id uuid PRIMARY KEY,
  name text,
  type text, -- 'Futsal', 'Badminton', etc.
  address text,
  photos text[],
  facilities text[],
  operating_hours jsonb,
  rating numeric,
  created_at timestamp
)
```

#### Fields
```sql
fields (
  id uuid PRIMARY KEY,
  venue_id uuid REFERENCES venues(id),
  name text,
  type text,
  area text, -- e.g., '20x40m'
  price_per_hour numeric,
  status text, -- 'available', 'booked', 'maintenance'
  created_at timestamp
)
```

#### Bookings
```sql
bookings (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  field_id uuid REFERENCES fields(id),
  booking_date date,
  start_time time,
  end_time time,
  total_price numeric,
  status text, -- 'pending', 'confirmed', 'cancelled'
  payment_status text, -- 'pending', 'paid', 'failed'
  payment_proof_url text,
  notes text,
  created_at timestamp
)
```

#### Staff
```sql
staff (
  id uuid PRIMARY KEY,
  user_id uuid REFERENCES auth.users(id),
  name text,
  email text,
  role text, -- 'admin', 'manager', 'operator'
  assigned_venues uuid[],
  is_active boolean,
  last_login timestamp,
  created_at timestamp
)
```

#### Maintenance Schedules
```sql
maintenance_schedules (
  id uuid PRIMARY KEY,
  venue_id uuid REFERENCES venues(id),
  field_id uuid REFERENCES fields(id),
  title text,
  description text,
  start_date timestamp,
  end_date timestamp,
  status text, -- 'scheduled', 'in_progress', 'completed', 'cancelled'
  assigned_to uuid REFERENCES staff(id),
  notes text,
  created_at timestamp
)
```

#### Chat Messages
```sql
chat_messages (
  id uuid PRIMARY KEY,
  booking_id uuid REFERENCES bookings(id),
  sender_id uuid REFERENCES auth.users(id),
  sender_name text,
  is_admin boolean,
  type text, -- 'text', 'image', 'system'
  message text,
  image_url text,
  read boolean,
  created_at timestamp
)
```

### Row Level Security (RLS)

All tables have RLS enabled with policies for:
- Users can read their own data
- Users can create bookings
- Admins can manage all data
- Staff can manage assigned venues

Example policy:
```sql
CREATE POLICY "Users can view own bookings"
  ON bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all bookings"
  ON bookings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM staff
      WHERE user_id = auth.uid()
      AND role = 'admin'
      AND is_active = true
    )
  );
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. Supabase Connection Error

**Error**: `SocketException: Failed to connect`

**Solution**:
- Check internet connection
- Verify SUPABASE_URL in .env
- Check Supabase project status
- Verify firewall/proxy settings

#### 2. Email Verification Not Sending

**Error**: Email verification link not received

**Solution**:
- Check spam folder
- Verify email in Supabase Auth settings
- Check SMTP configuration in Supabase
- Test with different email provider

#### 3. Build Errors

**Error**: `Gradle build failed`

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

#### 4. SSL Pinning Issues

**Error**: `Certificate verification failed`

**Solution**:
- Update certificate fingerprints in `ssl_config.dart`
- Ensure certificates haven't expired
- Test with SSL pinning disabled first (dev only)

#### 5. Permission Denied Errors

**Error**: `Permission denied` on Android

**Solution**:
- Check `AndroidManifest.xml` for required permissions
- Request runtime permissions in code
- Check app settings on device

### Debug Mode

Enable debug logging:

```dart
// In main.dart
void main() {
  if (kDebugMode) {
    print('🐛 Debug mode enabled');
  }
  runApp(MyApp());
}
```

### Performance Issues

If app is slow:
- Check database indexes
- Optimize queries (use `select` with specific columns)
- Implement pagination for large lists
- Use cached data where possible
- Profile with Flutter DevTools

---

## 🤝 Contributing

### Development Workflow

1. Create a new branch for your feature
```bash
git checkout -b feature/your-feature-name
```

2. Make your changes with clear commits
```bash
git commit -m "feat: add venue search functionality"
```

3. Push and create pull request
```bash
git push origin feature/your-feature-name
```

### Commit Message Format

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting)
- `refactor:` Code refactoring
- `test:` Adding tests
- `chore:` Maintenance tasks

### Code Review Checklist

- [ ] Code follows project style guide
- [ ] All tests pass
- [ ] No console errors or warnings
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] No hardcoded credentials
- [ ] Error handling implemented
- [ ] Security considerations reviewed

---

## 📞 Support & Contact

### Documentation

- **Main README**: `README.md`
- **Project Documentation**: `docs/PROJECT_DOCUMENTATION.md` (this file)
- **Features Status**: `docs/FEATURES_IMPLEMENTATION_STATUS.md`
- **Admin Features**: `docs/ADMIN_FEATURES_IMPLEMENTATION_SUMMARY.md`
- **Security Guides**: See `docs/` directory

### Issues

Report bugs or request features:
- GitHub Issues: [Create Issue](https://github.com/your-org/sipelor-bedas/issues)
- Email: support@sipelor-bedas.com

### Team

- **Development Team**: dev-team@sipelor-bedas.com
- **DISPORA Contact**: dispora@bandungkab.go.id

---

## 📄 License

This project is proprietary software developed for DISPORA Kabupaten Bandung.

All rights reserved © 2026 DISPORA Kabupaten Bandung

---

## 🙏 Acknowledgments

- **DISPORA Kabupaten Bandung** for project sponsorship
- **Flutter Team** for the amazing framework
- **Supabase** for backend infrastructure
- **Open Source Community** for valuable packages

---

**Last Updated**: 26 Januari 2026  
**Document Version**: 1.0  
**Maintained by**: Development Team
