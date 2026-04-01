# SIPELOR BEDAS — Technical Reference

> **Sistem Pemesanan Lapangan Olahraga DISPORA Kabupaten Bandung**  
> Version: `1.0.0+2` · Platform: Android, iOS, Web, Windows, Linux  
> Last Updated: 17 Maret 2026

---

## Daftar Isi

1. [Gambaran Umum](#1-gambaran-umum)
2. [Arsitektur Sistem](#2-arsitektur-sistem)
3. [Tech Stack](#3-tech-stack)
4. [Struktur Direktori](#4-struktur-direktori)
5. [Konfigurasi & Environment](#5-konfigurasi--environment)
6. [Alur Inisialisasi Aplikasi](#6-alur-inisialisasi-aplikasi)
7. [Navigasi & Routing](#7-navigasi--routing)
8. [State Management](#8-state-management)
9. [Dependency Injection](#9-dependency-injection)
10. [Data Models](#10-data-models)
11. [Repositories](#11-repositories)
12. [Services](#12-services)
13. [Screens](#13-screens)
14. [Widgets](#14-widgets)
15. [Security Layer](#15-security-layer)
16. [Design Tokens](#16-design-tokens)
17. [Build & Deployment](#17-build--deployment)
18. [Testing](#18-testing)
19. [Admin Panel (Web)](#19-admin-panel-web)
20. [Roadmap & Known Issues](#20-roadmap--known-issues)

---

## 1. Gambaran Umum

SIPELOR BEDAS adalah aplikasi manajemen pemesanan lapangan olahraga milik DISPORA (Dinas Pemuda dan Olahraga) Kabupaten Bandung. Sistem ini menghubungkan masyarakat umum dengan pengelola venue secara digital, menggantikan proses booking manual.

### Fitur Utama

| Pengguna | Admin / Super Admin |
|---|---|
| Browse & booking lapangan | Dashboard analytics lengkap |
| Cek ketersediaan real-time | Revenue analytics & laporan otomatis |
| Upload bukti pembayaran | Verifikasi pembayaran |
| E-ticket + QR Code | Scan QR Code (check-in) |
| Chat real-time dengan admin | Chat management |
| Review & rating | Staff & role management |
| Push notification | Maintenance scheduling |
| Biometric authentication | Bulk operations |
| Booking OPD / Pimpinan | Field & venue management |

---

## 2. Arsitektur Sistem

```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App (Client)                       │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ Screens  │  │ Widgets  │  │Providers │  │  Services  │  │
│  │  (UI)    │  │(Reusable)│  │(Riverpod)│  │(Biz Logic) │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
│       │              │             │               │          │
│  ┌────▼──────────────▼─────────────▼───────────────▼──────┐  │
│  │              Repository Layer (GetIt DI)               │  │
│  └────────────────────────┬───────────────────────────────┘  │
│                            │                                  │
│  ┌─────────────────────────▼───────────────────────────────┐  │
│  │               Security Layer (RASP / SSL)               │  │
│  └─────────────────────────┬───────────────────────────────┘  │
└─────────────────────────────┼────────────────────────────────┘
                              │ HTTPS + SSL Pinning
┌─────────────────────────────▼────────────────────────────────┐
│                     Supabase (Backend)                        │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │PostgreSQL│  │Realtime  │  │   Auth   │  │  Storage   │  │
│  │  (DB)    │  │(WebSocket│  │  (PKCE)  │  │  (Files)   │  │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Pola Arsitektur

- **MVVM-ish**: Screen (View) → Provider (ViewModel) → Repository/Service (Model)
- **Repository Pattern**: Hanya `Booking` yang sudah diimplementasikan dengan interface
- **Service Locator**: GetIt untuk DI di luar widget tree
- **Riverpod**: State management reaktif untuk auth dan booking state

---

## 3. Tech Stack

### Core

| Komponen | Teknologi | Versi |
|---|---|---|
| Framework | Flutter | ^3.10.3 |
| Language | Dart | ^3.10.3 |
| Backend | Supabase | ^2.6.0 |
| State Management | Riverpod | ^2.6.1 |
| DI Container | GetIt | ^8.0.2 |
| Error Tracking | Sentry | ^9.10.0 |

### UI & Fonts

| Komponen | Package |
|---|---|
| Typography | `google_fonts ^8.0.0` (Poppins + Mulish) |
| SVG Rendering | `flutter_svg ^2.2.3` |
| Image Cache | `cached_network_image ^3.3.0` |
| Skeleton Loading | `shimmer ^3.0.0` |
| Charts | `fl_chart ^1.1.1` |
| Maps | `google_maps_flutter ^2.10.0` |
| Intro/Onboarding | `intro_slider ^4.2.1` |
| Tutorial | `tutorial_coach_mark ^1.2.11` |

### Features

| Fitur | Package |
|---|---|
| QR Code | `qr_flutter ^4.1.0` |
| PDF & Print | `pdf ^3.11.1`, `printing ^5.13.4` |
| File Picker | `file_picker ^10.3.8` |
| Screenshot | `screenshot ^3.0.0` |
| Push Notification | `flutter_local_notifications ^20.0.0` |
| Deep Link | `app_links ^6.3.4` |
| Biometric Auth | `local_auth ^3.0.0` |
| Speech to Text | `speech_to_text ^7.3.0` |
| CSV Export | `csv ^6.0.0` |

### Security

| Fitur | Package |
|---|---|
| Secure Storage | `flutter_secure_storage ^10.0.0` |
| Encryption | `encrypt ^5.0.3`, `crypto ^3.0.5` |
| HTTP Client | `dio ^5.4.1` |
| SSL Pinning | `http_certificate_pinning ^3.0.1` |
| Device Info | `device_info_plus ^11.1.0` |
| Package Info | `package_info_plus ^8.1.0` |

### Offline & Network

| Fitur | Package |
|---|---|
| Connectivity | `connectivity_plus ^6.1.1` |
| Local Prefs | `shared_preferences ^2.3.5` |
| Environment | `flutter_dotenv ^6.0.0` |
| Path Utils | `path ^1.9.0`, `path_provider ^2.1.5` |

---

## 4. Struktur Direktori

```
sipelor/
├── android/                    # Android build config, keystore
├── ios/                        # iOS build config
├── linux/                      # Linux desktop build
├── windows/                    # Windows desktop build
├── web/                        # Flutter Web (PWA) + auth callback
├── website/
│   ├── admin/                  # Web admin panel (HTML/JS, standalone)
│   └── public/                 # Public web pages
├── assets/
│   ├── images/                 # App images (logo, splash, admin imgs)
│   ├── icons/                  # App icons (termasuk admin/)
│   └── sounds/                 # Sound assets
├── docs/                       # Dokumentasi (105+ files)
├── scripts/                    # Build & deployment scripts
├── test/                       # Unit & widget tests
├── database/                   # DB utilities/scripts
├── lib/
│   ├── config/                 # Build, Security, SSL config
│   ├── constants/              # AppColors, AppTextStyles
│   ├── core/                   # AppRouter, ServiceLocator
│   ├── models/                 # 15 data models
│   ├── providers/              # Riverpod providers (auth, booking)
│   ├── repositories/           # Repository layer + interfaces
│   ├── screens/                # 38 UI screens (nested by feature)
│   ├── security/               # 8 security modules
│   ├── services/               # 37 business logic services
│   ├── utils/                  # 17 utilities & helpers
│   ├── widgets/                # 20+ reusable widgets
│   └── main.dart               # App entry point
├── pubspec.yaml                # Dependencies
└── .env                        # Credentials (DEV only, tidak di-commit)
```

---

## 5. Konfigurasi & Environment

### Variabel Environment

| Variabel | Keterangan | Cara Set |
|---|---|---|
| `SUPABASE_URL` | Supabase project URL | `--dart-define` atau `.env` |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | `--dart-define` atau `.env` |
| `SENTRY_DSN` | Sentry error tracking DSN | `--dart-define` |
| `EMAIL_REDIRECT_URL` | URL callback email verification | `--dart-define` |
| `ENVIRONMENT` | `development` / `staging` / `production` | `--dart-define` |
| `ENABLE_SSL_PINNING` | `true` / `false` (dev only) | `--dart-define` |
| `VERBOSE_LOGGING` | `true` / `false` (dev only) | `--dart-define` |

### Prioritas Credentials (Tier System)

```
Tier 1: --dart-define flags       ← Wajib untuk production build
Tier 2: .env file di root project ← Digunakan untuk development
Tier 3: Exception / Error screen  ← Jika keduanya tidak ada
```

> ⚠️ **PENTING**: File `.env` terdaftar sebagai Flutter asset (pubspec.yaml). Harus **dikomentari** di `pubspec.yaml` sebelum production build agar tidak ikut ter-bundle ke dalam APK.

### BuildConfig — Feature Flags

| Flag | Default Dev | Default Prod |
|---|---|---|
| `sslPinningEnabled` | `false` | `true` |
| `verboseLogging` | `true` | `false` |
| `debugToolsEnabled` | `true` | `false` |
| `autoLogoutEnabled` | `true` | `true` |
| `autoLogoutMinutes` | `15` | `15` |
| `maxUploadSizeMB` | `10` | `10` |
| `imageCompressionQuality` | `80` | `80` |
| `cacheExpiryMinutes` | `30` | `30` |
| `offlineModeEnabled` | `true` | `true` |

---

## 6. Alur Inisialisasi Aplikasi

```
main()
  │
  ├─ [SECURITY LAYER — mobile only]
  │    ├─ AppSecurityManager.initialize()
  │    ├─ AntiTamperGuard.runAllChecks()
  │    │    └─ if critical + release → show SecurityBlockScreen → return
  │    ├─ NetworkSecurityManager.assess()
  │    ├─ RASPSecurity.performSecurityCheck()
  │    │    └─ if critical + release → show SecurityBlockScreen → return
  │    └─ RASPSecurity.startRuntimeMonitoring()
  │
  ├─ [PHASE 2 — Parallel Services] Future.wait([...])
  │    ├─ initializeDateFormatting('id_ID')
  │    ├─ ErrorTrackingService.initialize()     (Sentry)
  │    ├─ HttpCacheService().initialize()
  │    ├─ ConnectivityService().initialize()
  │    └─ OfflineCacheService().initialize()
  │
  ├─ [SYNC — Fire and forget]
  │    ├─ PerformanceMonitor.initialize()
  │    └─ ImageCacheOptimizer.configure()
  │
  ├─ [SUPABASE INIT]
  │    ├─ Load credentials (dart-define → .env → exception)
  │    ├─ Supabase.initialize() with PKCE auth flow
  │    ├─ setupServiceLocator() (GetIt DI)
  │    ├─ PinnedHttpClient.instance (SSL Pinning)
  │    ├─ SSLConfig.validate()
  │    │
  │    ├─ [POST-SUPABASE — Parallel] Future.wait([...])
  │    │    ├─ BookingExpirationService.initialize()
  │    │    └─ PushNotificationService().initialize() [mobile only]
  │    │
  │    └─ [BACKGROUND — Fire and forget]
  │         ├─ EncryptedPreferencesService().initialize()
  │         ├─ FileEncryptionService().initialize()
  │         └─ SecurityEventNotificationService.initialize()
  │
  ├─ ChatService.initializeAutoCleanup(24h, every 6h)
  ├─ NotificationCleanupService.initialize(24h, every 6h)
  │
  └─ runApp(ProviderScope(child: MyApp()))
```

### MyApp — Auth State Listener

`MyApp` listen ke `Supabase.auth.onAuthStateChange`:

| Event | Aksi |
|---|---|
| `signedIn` | Query `profiles.role` → navigate to `/home` |
| `passwordRecovery` | Navigate to `/reset-password` |

---

## 7. Navigasi & Routing

### Named Routes

```dart
// main.dart routes map
'/home'           → HomeScreen
'/login'          → AuthScreen
'/reset-password' → ResetPasswordScreen
'/debug'          → DebugMenuScreen (debug/staging only, admin only)
```

### AppRouter Helper

```dart
// Navigate dan clear stack
AppRouter.pushAndRemoveUntil('/home');

// Navigate dengan push biasa
AppRouter.pushNamed('/login');

// Navigate dengan Widget (untuk screen yang butuh object)
AppRouter.push(VenueDetailScreen(venue: venue));

// Pop
AppRouter.pop();
```

### Global Navigator Key

```dart
// Dapat diakses dari static methods (mis. PushNotificationService)
AppRouter.navigatorKey   // GlobalKey<NavigatorState>
AppRouter.navigator      // NavigatorState?
```

---

## 8. State Management

### Riverpod Providers (`lib/providers/`)

#### Auth Providers (`auth_providers.dart`)

```dart
// Stream user saat ini (null jika tidak login)
final currentUserProvider = StreamProvider<User?>(...)

// ID user saat ini (throws jika tidak login)
final currentUserIdProvider = Provider<String>(...)

// Status autentikasi
final isAuthenticatedProvider = Provider<bool>(...)

// Email user
final userEmailProvider = Provider<String?>(...)

// Metadata user (role, display_name, dll)
final userMetadataProvider = Provider<Map<String, dynamic>?>(...)

// Sign out action
final signOutProvider = Provider<Future<void> Function()>(...)
```

#### Booking Providers (`booking_providers.dart`)

> Lihat file untuk detail provider booking state.

### Pola Penggunaan di Screen

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);
    // ...
  }
}
```

---

## 9. Dependency Injection

### Service Locator (`lib/core/service_locator.dart`)

Menggunakan `GetIt` sebagai DI container. Dipanggil via `setupServiceLocator()` di `main.dart` setelah Supabase siap.

#### Registered Services

| Interface / Type | Implementation | Scope |
|---|---|---|
| `SupabaseClient` | `Supabase.instance.client` | LazySingleton |
| `IBookingRepository` | `SupabaseBookingRepository` | LazySingleton |
| `ChatService` | `ChatService()` | LazySingleton |
| `EncryptedPreferencesService` | `EncryptedPreferencesService()` | LazySingleton |
| `FileEncryptionService` | `FileEncryptionService()` | LazySingleton |
| `HttpCacheService` | `HttpCacheService()` | LazySingleton |
| `QueryCacheService` | `QueryCacheService()` | LazySingleton |
| `DependencyMonitorService` | `DependencyMonitorService()` | LazySingleton |

#### Cara Menggunakan

```dart
import '../core/service_locator.dart';

// Ambil dependency
final repo = getIt<IBookingRepository>();
final chat = getIt<ChatService>();
```

#### Testing

```dart
// Reset semua registrations (di setUp())
resetServiceLocator();
```

---

## 10. Data Models

Semua model berada di `lib/models/` dengan pola `fromJson()`, `toJson()`, dan `copyWith()`.

### Booking

```dart
class Booking {
  final String id, bookingId, userId, fieldId, venueId;
  final DateTime bookingDate;
  final String startTime, endTime;   // "08:00", "10:00"
  final int durationHours, totalAmount;
  final BookingStatus status;        // pending | confirmed | completed | cancelled
  final PaymentStatus paymentStatus; // pending | verified | rejected
  final BookingType bookingType;     // regular | opd | pimpinan
  final String? notes, venueName, fieldArea, venueType;
  final bool hasPaymentProof;
  final String? opdId, bookedForLabel, opdName;
  // ...
}
```

#### Enums Booking

| Enum | Values |
|---|---|
| `BookingStatus` | `pending`, `confirmed`, `completed`, `cancelled` |
| `PaymentStatus` | `pending`, `verified`, `rejected` |
| `BookingType` | `regular`, `opd`, `pimpinan` |

### Field (Lapangan)

```dart
class Field {
  final String id, venueName, venueType, area;
  final String? venueId, satuan, description;
  final int pricePerHour;
  final FieldStatus status;          // available | booked | maintenance
  final List<String>? imageUrls;
  final double? latitude, longitude;
  final String? ukuranLapangan, kapasitas;
  final bool? tempatParkir, mushola, cctv, ruangTunggu, ruangGanti;
  // ...
}
```

#### BookingMode (Derived dari `satuan`)

| Mode | Trigger |
|---|---|
| `perJam` | Default (per jam) |
| `perSesi` | satuan mengandung "sesi" atau "2 jam" |
| `harian` | satuan "hari"/"pertandingan"/"resepsi" |
| `perOrang` | satuan mengandung "orang" |

### Venue

```dart
class Venue {
  final String id, name, address, city;
  final String? venueType, description, imageUrl;
  final double rating;
  final int totalReviews;
  final bool isActive;
  // ...
}
```

### UserRole

```dart
enum UserRole {
  user,       // Pengguna biasa
  admin,      // Administrator venue
  superadmin; // Super administrator (akses penuh)

  bool get isAdmin     => this == admin || this == superadmin;
  bool get isSuperadmin => this == superadmin;
}
```

### Model Lainnya

| Model | Keterangan |
|---|---|
| `ChatMessage` | Pesan chat user ↔ admin |
| `Review` | Review dan rating venue |
| `Staff` | Data staf / pengelola |
| `MaintenanceSchedule` | Jadwal perawatan lapangan |
| `RevenueAnalytics` | Data analytics pendapatan |
| `PushNotification` | Data push notification |
| `ETicketData` | Data e-ticket booking |
| `PaymentConfirmationData` | Data konfirmasi pembayaran |
| `PaymentSuccessData` | Data setelah pembayaran berhasil |
| `TimeSlot` | Slot waktu tersedia |
| `CarouselBanner` | Data banner promo carousel |
| `Tournament` | Data turnamen (Bupati Cup, dll) |

---

## 11. Repositories

### IBookingRepository (Interface)

```dart
abstract class IBookingRepository {
  Future<List<Booking>> getUserBookings(String userId);
  Future<Booking?> getBookingById(String id);
  Future<Booking> createBooking(Booking booking);
  Future<Booking> updateBooking(String id, Map<String, dynamic> updates);
  Future<void> cancelBooking(String id);
  Future<void> deleteBooking(String id);
  Future<List<Booking>> getBookingsByStatus(String userId, String status);
  Future<List<Booking>> getBookingsByDateRange(String userId, DateTime start, DateTime end);
}
```

**Implementation**: `SupabaseBookingRepository` — mengimplementasikan interface di atas menggunakan Supabase client.

**Exception**: `RepositoryException(message, [originalError])` — dilempar saat operasi gagal.

> ℹ️ Repository pattern baru diimplementasikan untuk **Booking**. Service lain (Field, Venue, Chat, dll) masih menggunakan direct Supabase calls di dalam service class masing-masing.

---

## 12. Services

### Core Services

| Service | Fungsi |
|---|---|
| `SupabaseService` | Wrapper Supabase operations |
| `FieldService` | CRUD lapangan, cek ketersediaan, slot waktu |
| `BookingExpirationService` | Auto-cancel booking yang kedaluwarsa |
| `NotificationService` | Kelola notifikasi in-app |
| `NotificationCleanupService` | Auto-delete notifikasi > 24 jam (setiap 6 jam) |

### Auth Services

| Service | Fungsi |
|---|---|
| `BiometricAuthService` | Fingerprint / Face ID authentication |
| `EmailVerificationService` | Kelola email verification flow |
| `PasswordService` | Validasi kekuatan password |
| `SocialAuthService` | Google / Apple OAuth login |
| `AutoLogoutService` | Deteksi inaktivitas → auto logout (15 menit) |

### Chat Services

| Service | Fungsi |
|---|---|
| `ChatService` | Real-time chat via Supabase Realtime; auto-cleanup pesan > 24 jam setiap 6 jam |

### Security Services

| Service | Fungsi |
|---|---|
| `AuditService` | Comprehensive audit logging |
| `OWASPSecurityChecks` | OWASP Mobile Top 10 checks |
| `RateLimiterService` | Client-side rate limiting |
| `ServerRateLimiterService` | Server-side rate limiting via Supabase |
| `ContentModerationService` | Filter konten berbahaya |
| `SecureStorageService` | Enkripsi data sensitif di local storage |
| `SecurityEducationService` | Tips keamanan untuk pengguna |
| `SecurityEventNotificationService` | Notifikasi saat terjadi security event |

### Analytics & Reporting

| Service | Fungsi |
|---|---|
| `RevenueAnalyticsService` | Kalkulasi dan query data pendapatan |
| `AutomatedReportsService` | Generate laporan otomatis (PDF/CSV) |

### Performance Services

| Service | Fungsi |
|---|---|
| `HttpCacheService` | Cache HTTP responses |
| `ImageCacheOptimizer` | Konfigurasi cache gambar |
| `QueryCacheService` | Cache hasil query database |
| `OfflineCacheService` | Cache untuk mode offline |

### Notification Services

| Service | Fungsi |
|---|---|
| `PushNotificationService` | FCM push notifications (mobile) |
| `NotificationDebugHelper` | Debugging helper untuk notifikasi |
| `NotificationHelper` | Utility untuk format & tampil notif |
| `PopupService` | Popup banner / promo management |

### Infra Services

| Service | Fungsi |
|---|---|
| `ConnectivityService` | Monitor status koneksi internet |
| `DeepLinkHandler` / `DeepLinkService` | Handle deep link (email verification, dll) |
| `PinnedHttpClient` | HTTP client dengan SSL pinning |
| `CertificateRotationService` | Rotasi SSL certificate |
| `OnboardingService` | Kelola status onboarding user |
| `BookingTutorialService` | Tutorial interaktif flow booking |
| `DependencyMonitorService` | Monitor versi dependencies (debug) |
| `CarouselService` | Ambil data banner carousel dari Supabase |
| `TournamentService` | Data turnamen olahraga |

### Admin Services

| Service | Fungsi |
|---|---|
| `StaffService` | CRUD data staf |
| `MaintenanceService` | CRUD jadwal perawatan |
| `BulkOperationsService` | Operasi bulk (approve/reject/export) |
| `ReviewService` | Query & moderasi review pengguna |

---

## 13. Screens

### Navigasi Screen

```
SplashScreen → [cek auth]
    ├── AuthScreen
    │     ├── SignInScreen
    │     ├── SignUpScreen
    │     ├── ResetPasswordScreen
    │     └── OnboardingScreen
    │
    └── HomeScreen (BottomNavigationBar)
          ├── VenueListScreen → VenueDetailScreen
          │                         └── BookingConfirmationScreen
          │                               └── PaymentConfirmationScreen
          │                                     └── PaymentSuccessScreen
          │                                           └── ETicketScreen
          │
          ├── UserBookingsScreen → BookingDetailScreen → ETicketScreen
          │
          ├── UserChatScreen (↔ AdminChatConversationScreen)
          │
          └── ProfileScreen
                ├── EditProfileScreen
                ├── OrderScreen
                ├── NotificationSettingsScreen
                ├── SecuritySettingsScreen
                ├── AboutAppScreen
                ├── HelpFAQScreen
                ├── PrivacyPolicyScreen
                ├── TermsOfServiceScreen
                └── SecurityTipsScreen
```

### Admin Screens

```
AdminChatListScreen → AdminChatConversationScreen
```

> ℹ️ Dashboard Admin tersedia di `website/admin/` (web panel terpisah, berbasis HTML/JS).

### Tournament Screens

```
BupatiCupScreen → TournamentDetailScreen → TeamRegistrationScreen
```

### Debug Screens (dev/staging only)

```
DebugMenuScreen
    ├── DatabaseOptimizerScreen
    ├── MemoryLeakDetectorScreen
    └── PerformanceMonitorScreen
```

---

## 14. Widgets

### Reusable Widgets (`lib/widgets/`)

| Widget | Fungsi |
|---|---|
| `AnimatedGradientButton` | Tombol dengan animasi gradient |
| `AutoLogoutWrapper` | Wrapper deteksi inaktivitas |
| `BookingDateTimeSheet` | Bottom sheet pilih tanggal & waktu booking |
| `BookingExpirationTimer` | Timer countdown kedaluwarsa booking |
| `CountdownTimer` | Timer countdown generic |
| `CustomInputField` | Input field dengan validasi styling |
| `EmailVerificationBanner` | Banner notif verifikasi email |
| `GuestLoginBanner` | Banner untuk tamu (belum login) |
| `LegalDocumentTemplate` | Template tampilan dokumen legal |
| `OfflineBanner` | Banner status offline |
| `PaymentMethodSheet` | Bottom sheet metode pembayaran |
| `PopupBannerDialog` | Dialog popup promo/banner |
| `QrCodeDialog` | Dialog tampil QR code |
| `ReviewDialog` | Dialog input review & rating |
| `SecurityWarningDialog` | Dialog peringatan keamanan |
| `SkeletonLoading` | Loading skeleton placeholder |
| `SocialButton` | Tombol login Google/Apple/Facebook |
| `TopNotificationBanner` | Banner notifikasi di atas layar |
| `UploadProofSection` | Section upload bukti pembayaran |

### Home Sub-Widgets (`lib/widgets/home/`)

| Widget | Fungsi |
|---|---|
| `BottomNavBar` | Bottom navigation bar utama |
| `CategoryGrid` | Grid kategori olahraga |
| `HomeHeader` | Header home screen |
| `PromoCard` | Card promosi |
| `PromoCarousel` | Carousel banner promo |
| `SectionHeader` | Header section dengan "lihat semua" |
| `VenueCard` | Card venue di list |
| `VenueGrid` | Grid tampilan venue |

---

## 15. Security Layer

### Lapisan Keamanan

```
┌──────────────────────────────────────────────────────────────┐
│  Layer 1: AppSecurityManager — Orchestrator semua layer      │
│  Layer 2: AntiTamperGuard    — Deteksi modifikasi APK        │
│  Layer 3: NetworkSecurityManager — Cek keamanan jaringan     │
│  Layer 4: RASPSecurity       — Runtime Application Self-Prot │
│  Layer 5: SSL Certificate Pinning — Cegah MITM              │
│  Layer 6: Data Encryption (AES-256) — Data at rest           │
│  Layer 7: SecureStorage      — Kredensial terenkripsi        │
│  Layer 8: BiometricAuth      — Fingerprint / Face ID         │
│  Layer 9: AutoLogout         — Timeout inaktivitas 15 menit  │
│  Layer 10: RateLimiter       — Batas percobaan login         │
│  Layer 11: AuditLog          — Semua aksi tercatat           │
│  Layer 12: InputSanitizer    — Validasi & sanitasi input     │
│  Layer 13: RequestSigning    — Tanda tangan request API      │
│  Layer 14: OWASP Checks      — Mobile OWASP Top 10          │
└──────────────────────────────────────────────────────────────┘
```

### RASP Security (`lib/security/rasp_security.dart`)

Melakukan pengecekan saat startup dan monitoring berkala (setiap 15 menit di production):

| Pengecekan | Ancaman yang Dideteksi |
|---|---|
| Root / Jailbreak | Su binary, Magisk, Cydia, test-keys build |
| Debug Mode | `kDebugMode` flag |
| Emulator | Fingerprint generic, model SDK, bukan physical device |
| App Integrity | Frida server, Frida port 27042, Xposed/LSPosed, Cydia Substrate |
| Environment | `LD_PRELOAD`, `DYLD_INSERT_LIBRARIES` |

**Security Levels:**

| Level | Kondisi | Aksi |
|---|---|---|
| `safe` | Tidak ada ancaman | Lanjut normal |
| `warning` | Ancaman ringan | Log, lanjut dengan peringatan |
| `danger` | 1 ancaman kritikal | Warning kepada user |
| `critical` | ≥2 ancaman kritikal | **Blokir app (production)** |

### SSL Certificate Pinning

- Diimplementasikan via `PinnedHttpClient` menggunakan `http_certificate_pinning`
- Selalu aktif di production (`BuildConfig.sslPinningEnabled = true`)
- Dapat dinonaktifkan di development via `--dart-define=ENABLE_SSL_PINNING=false`
- Konfigurasi di `lib/config/ssl_config.dart`

### Authentication Security

- **PKCE Flow**: Digunakan untuk email verification deep links
- **Email Verification**: Wajib sebelum bisa menggunakan fitur booking
- **Rate Limiting**: 3 kali gagal login → lockout 1 jam
- **Auto Logout**: Inaktivitas 15 menit → otomatis keluar
- **Biometric**: Fingerprint / Face ID untuk re-authentication

### Data Encryption

- **AES-256** untuk data sensitif tersimpan lokal
- `EncryptedPreferencesService` — enkripsi SharedPreferences
- `FileEncryptionService` — enkripsi file (bukti pembayaran, dokumen)
- `flutter_secure_storage` — penyimpanan kredensial OS-level

---

## 16. Design Tokens

### Color Palette (`lib/constants/app_colors.dart`)

#### Background Colors

| Token | Hex | Penggunaan |
|---|---|---|
| `darkBg` | `#151316` | Dark background utama |
| `whiteBg` | `#FFFFFF` | Light background |
| `inputBg` | `#2A2A2E` | Input field dark |
| `lightInputBg` | `#F5F5F5` | Input field light |
| `screenBg` | `#F5F5F5` | Home screen background |
| `primaryDark` | `#211A2C` | Header & dark primary |
| `secondaryDark` | `#28293F` | Secondary dark element |

#### Text Colors

| Token | Hex | Penggunaan |
|---|---|---|
| `primaryText` | `#EFEFEF` | Teks utama (dark theme) |
| `secondaryText` | `#B6B6B6` | Teks sekunder |
| `labelText` | `#A4A4A4` | Label input |
| `successText` | `#9FDBA1` | Pesan sukses |
| `darkPrimaryText` | `#1A1A1A` | Teks utama (light theme) |

#### UI / Status Colors

| Token | Hex | Penggunaan |
|---|---|---|
| `gradientStart` | `#D946EF` | Gradient awal (tombol, aksen) |
| `gradientEnd` | `#F97316` | Gradient akhir |
| `primaryYellow` | `#FDC300` | Aksen kuning, pending |
| `statusAvailable` | `#4CAF50` | Status lapangan tersedia |
| `statusBooked` | `#FF9800` | Status lapangan dipesan |
| `statusMaintenance` | `#F44336` | Status lapangan maintenance |
| `linkBlue` | `#0068E1` | Link teks |

### Typography (`lib/constants/app_text_styles.dart`)

**Font Families**: Poppins (headings/body), Mulish (global app font)

| Style | Font | Size | Weight |
|---|---|---|---|
| `headingLarge` | Poppins | 40.33 | W600 |
| `headingMedium` | Poppins | 17.92 | W500 |
| `labelText` | Poppins | 14.33 | W500 |
| `subLabelText` | Poppins | 11.33 | W500 |
| `inputText` | Poppins | 14.33 | W500 |
| `buttonText` | Poppins | 17.92 | W500 |
| `dividerText` | Poppins | 11.25 | W500 |

Setiap style di atas memiliki pasangan light theme (`lightHeadingLarge`, `lightLabelText`, dst).

---

## 17. Build & Deployment

### Development

```bash
# Setup
flutter pub get

# Buat file .env di root
echo "SUPABASE_URL=https://xxx.supabase.co" > .env
echo "SUPABASE_ANON_KEY=eyJxxx" >> .env

# Jalankan
flutter run
```

### Production Build — Android

```bash
# APK
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJxxx \
  --dart-define=SENTRY_DSN=https://xxx@sentry.io/xxx \
  --dart-define=ENVIRONMENT=production \
  --obfuscate \
  --split-debug-info=build/debug-info/

# App Bundle (Google Play)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

> Output APK: `build/app/outputs/flutter-apk/app-release.apk`

### Production Build — iOS

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Kemudian archive & upload via Xcode
```

### Production Build — Web

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Deploy folder build/web ke Vercel / Netlify / Firebase Hosting
```

### Build Scripts

| Script | Fungsi |
|---|---|
| `scripts/build_production.sh` | Production APK build (Linux/Mac) |
| `scripts/build_admin.sh` | Build admin panel (Linux/Mac) |
| `scripts/build_admin.bat` | Build admin panel (Windows) |
| `scripts/run_tests.sh` | Jalankan semua tests |
| `scripts/test_security.sh` | Security test suite |
| `scripts/test_security.bat` | Security test suite (Windows) |

### ⚠️ Checklist Sebelum Production Build

1. [ ] Komentari baris `.env` di `pubspec.yaml` assets
2. [ ] Set semua `--dart-define` credentials
3. [ ] Verifikasi SSL certificate masih valid
4. [ ] Cek `BuildConfig.sslPinningEnabled` = `true`
5. [ ] Pastikan `debugToolsEnabled` = `false` di production
6. [ ] Jalankan `flutter analyze` — tidak ada error
7. [ ] Jalankan `flutter test` — semua passing

---

## 18. Testing

### Struktur Test

```
test/
├── coverage_test.dart    # Coverage aggregator
├── test_helper.dart      # Test utilities & mocks
└── widget_test.dart      # Widget tests
```

### Menjalankan Tests

```bash
# Unit & widget tests
flutter test

# Dengan coverage
flutter test --coverage

# Lihat laporan coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Static analysis
flutter analyze

# Cek dependency outdated
flutter pub outdated
```

### Dev Dependencies untuk Testing

| Package | Fungsi |
|---|---|
| `mockito ^5.4.4` | Mocking objects |
| `build_runner ^2.4.8` | Code generation |
| `faker ^2.1.0` | Generate fake test data |
| `patrol ^3.11.2` | E2E testing framework |
| `integration_test` | Flutter integration tests |

### Reset Service Locator (Testing)

```dart
setUp(() {
  resetServiceLocator(); // Dari core/service_locator.dart
});
```

---

## 19. Admin Panel (Web)

Admin panel tersedia sebagai **web application terpisah** di `website/admin/`, berbasis HTML/JS murni (bukan Flutter Web).

```
website/admin/
├── index.html         # Dashboard utama admin
├── login.html         # Login admin
├── main.js            # Entry point JS
├── js/
│   ├── api.js         # API calls ke Supabase
│   ├── app.js         # Logic aplikasi
│   └── config.js      # Konfigurasi URL & keys
└── package.json
```

### Akses Admin Panel

- URL admin panel di-host terpisah dari Flutter app
- Login menggunakan akun Supabase dengan role `admin` atau `superadmin`
- Role tersedia: `user`, `admin`, `superadmin`

### Supabase Storage Buckets

| Bucket | Akses | Isi |
|---|---|---|
| `profile-avatars` | Public | Foto profil pengguna |
| `venue-photos` | Public | Foto venue & lapangan |
| `payment-proofs` | **Private** | Bukti transfer pembayaran |

---

## 20. Roadmap & Known Issues

### Phase 2 (Planned)

- [ ] Automated refund processing
- [ ] Integrasi payment gateway (Midtrans / DOKU)
- [ ] QR code scanner untuk staf venue
- [ ] Advanced analytics & reporting
- [ ] Multi-language support (id / en)
- [ ] Dark mode untuk HomeScreen

### Phase 3 (Future)

- [ ] App mobile terpisah untuk staf/operator
- [ ] IoT integration (sensor lapangan)
- [ ] AI-based booking recommendations
- [ ] Dynamic pricing algorithms
- [ ] Loyalty / poin reward program

### Known Issues & Notes

| Issue | Keterangan |
|---|---|
| `venues` table | Tidak ada tabel `venues` terpisah di DB; semua data venue tersimpan di tabel `fields`. `venue_id` di `Booking` mungkin merujuk ke `field_id`. |
| `.env` di assets | Harus dikomentari sebelum production build (ada warning di kode) |
| Repository pattern | Baru diimplementasikan untuk `Booking`; service lain masih direct Supabase calls |
| Admin Flutter screen | Hanya ada `AdminChatListScreen` & `AdminChatConversationScreen`; dashboard admin di web panel terpisah |
| StatefulWidget dominan | Sebagian besar screen masih `StatefulWidget`; Riverpod belum sepenuhnya diterapkan di semua screen |
| Gmail deep link | Menggunakan HTTPS redirect URL (bukan custom scheme) untuk mengatasi batasan Chrome Custom Tab di Gmail |

---

*Dokumen ini di-generate secara otomatis dari analisis source code. Update dokumen ini setiap ada perubahan arsitektur signifikan.*

---

**© 2026 DISPORA Kabupaten Bandung — All Rights Reserved**
