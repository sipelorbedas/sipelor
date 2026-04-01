# SIPELOR BEDAS

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.3-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.3-0175C2?logo=dart)
![Supabase](https://img.shields.io/badge/Supabase-2.6.0-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-Proprietary-red)

**Sistem Pemesanan Lapangan Olahraga DISPORA Kabupaten Bandung**

Complete Sports Field Booking Management System

[Features](#-key-features) • [Installation](#-installation) • [Documentation](#-documentation) • [Security](#-security)

</div>

---

## 📱 About

SIPELOR BEDAS adalah aplikasi mobile dan web untuk manajemen pemesanan lapangan olahraga di Kabupaten Bandung, dikembangkan untuk DISPORA (Dinas Pemuda dan Olahraga).

### 🎯 Tujuan Aplikasi

- Mempermudah masyarakat melakukan booking lapangan secara online
- Meningkatkan efisiensi pengelolaan venue dan lapangan
- Menyediakan data analytics untuk pengambilan keputusan
- Meningkatkan transparansi melalui sistem payment verification
- Memfasilitasi komunikasi real-time antara pengguna dan admin

---

## ✨ Key Features

### For Users
- 🏟️ Browse dan booking lapangan olahraga (Futsal, Badminton, Basket, dll)
- 📅 Real-time availability checking
- 💳 Payment verification dengan upload bukti transfer
- 🎫 E-ticket generation dengan QR code
- 💬 Real-time chat dengan admin
- ⭐ Review dan rating system
- 🔔 Push notifications untuk status booking
- 🔒 Biometric authentication (fingerprint/face ID)

### For Admin
- 📊 Dashboard dengan analytics lengkap
- 💰 Revenue analytics dan automated reports
- 👥 Staff management dengan role-based access
- 🔧 Maintenance scheduling
- 📦 Bulk operations (approve, reject, export)
- 💬 Chat management dengan users
- 🏢 Venue dan field management
- 📈 Performance metrics per venue

---

## 🛠️ Technology Stack

### Frontend
- **Flutter** (SDK ^3.10.3) - Cross-platform UI framework
- **Dart** (^3.10.3) - Programming language
- **Google Fonts** - Typography
- **FL Chart** - Analytics charts

### Backend
- **Supabase** - Backend-as-a-Service
  - PostgreSQL Database
  - Realtime subscriptions
  - Authentication
  - Storage
- **Sentry** - Error tracking & monitoring

### Security
- SSL Certificate Pinning
- Data encryption (AES-256)
- Secure local storage
- Biometric authentication
- Rate limiting & audit logging

## 📋 Prerequisites

- Flutter SDK ≥ 3.10.3
- Dart SDK ≥ 3.10.3
- Android Studio / VS Code
- Supabase account
- Git

---

## 🚀 Installation

### 1. Clone Repository

```bash
git clone https://github.com/your-org/sipelor-bedas.git
cd sipelor-bedas
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Environment

Create `.env` file in root directory:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Configure Supabase

1. Create Supabase project at [supabase.com](https://supabase.com)
2. Run SQL scripts from `docs/DATABASE_SETUP_ADMIN_FEATURES.sql`
3. Create storage buckets:
   - `profile-avatars` (public)
   - `venue-photos` (public)
   - `payment-proofs` (private)
4. Enable Realtime for `chat_messages` table

### 5. Run Application

```bash
# Development
flutter run

# Production build (Android)
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key

# Production build (iOS)
flutter build ios --release \
  --dart-define=SUPABASE_URL=your_url \
  --dart-define=SUPABASE_ANON_KEY=your_key
```

---

## 📚 Documentation

### Main Documentation
- **[Complete Project Documentation](docs/PROJECT_DOCUMENTATION.md)** - Full technical documentation
- **[Quick Reference Guide](docs/QUICK_REFERENCE_GUIDE.md)** - Quick lookup reference
- **[Features Implementation Status](docs/FEATURES_IMPLEMENTATION_STATUS.md)** - Feature completion status
- **[Admin Features Summary](docs/ADMIN_FEATURES_IMPLEMENTATION_SUMMARY.md)** - Admin features guide

### Setup Guides
- **[Database Setup](docs/DATABASE_SETUP_ADMIN_FEATURES.sql)** - SQL scripts for database
- **[Sentry Setup](docs/SENTRY_SETUP_GUIDE.md)** - Error tracking setup
- **[Push Notifications](docs/PUSH_NOTIFICATIONS_IMPLEMENTATION.md)** - Notification setup
- **[Google OAuth](docs/GOOGLE_OAUTH_SETUP.md)** - Social authentication

### Security Documentation
- **[Data Encryption](docs/DATA_ENCRYPTION_IMPLEMENTATION.md)** - Encryption implementation
- **[SSL Pinning](docs/SSL_CERTIFICATE_PINNING.md)** - Certificate pinning guide
- **[Security Events](docs/SECURITY_EVENT_NOTIFICATIONS.md)** - Security monitoring

---

## 🔒 Security

This application implements multiple layers of security:

### Authentication & Authorization
- Email verification enforcement
- Strong password requirements
- Biometric authentication (fingerprint/face ID)
- Rate limiting (3 failed attempts = 1 hour lockout)
- Auto-logout after 15 minutes of inactivity
- Role-based access control (Admin, Manager, Operator)

### Data Protection
- **Encryption at Rest**: AES-256 encryption for sensitive data
- **Encryption in Transit**: SSL/TLS with certificate pinning
- **Secure Storage**: flutter_secure_storage for credentials
- **File Encryption**: Payment proofs and documents encrypted
- **Password Hashing**: Bcrypt via Supabase Auth

### Network Security
- SSL certificate pinning (prevents MITM attacks)
- HTTPS-only communication
- Certificate validation
- Secure API endpoints

### Monitoring & Auditing
- Comprehensive audit logging
- Security event notifications
- Error tracking with Sentry
- Failed login attempt tracking
- Real-time security alerts

---

## 📦 Project Structure

```
sipelor/
├── android/              # Android configuration
├── ios/                  # iOS configuration
├── lib/                  # Main application code
│   ├── config/          # App configuration
│   ├── constants/       # Constants and colors
│   ├── models/          # Data models (15 models)
│   ├── screens/         # UI screens (36 screens)
│   ├── services/        # Business logic (25 services)
│   ├── widgets/         # Reusable widgets
│   └── main.dart        # App entry point
├── assets/              # Static assets
├── docs/                # Documentation (17+ files)
├── scripts/             # Build and deployment scripts
├── .env                 # Environment variables (not committed)
├── pubspec.yaml         # Dependencies
└── README.md            # This file
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Check outdated packages
flutter pub outdated
```

---

## 🚢 Deployment

### Android

```bash
# Generate release APK
flutter build apk --release \
  --dart-define=SUPABASE_URL=production_url \
  --dart-define=SUPABASE_ANON_KEY=production_key \
  --dart-define=SENTRY_DSN=sentry_dsn

# Generate App Bundle (for Google Play)
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=production_url \
  --dart-define=SUPABASE_ANON_KEY=production_key
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS

```bash
flutter build ios --release \
  --dart-define=SUPABASE_URL=production_url \
  --dart-define=SUPABASE_ANON_KEY=production_key
```

Then archive and upload via Xcode.

### Web

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=production_url \
  --dart-define=SUPABASE_ANON_KEY=production_key
```

Deploy `build/web` to Firebase Hosting, Netlify, or Vercel.

---

## 📊 Project Statistics

- **Total Screens**: 36
- **Total Services**: 25
- **Total Models**: 15
- **Database Tables**: 10+
- **Dependencies**: 30+
- **Lines of Code**: 15,000+
- **Documentation Pages**: 17+

---

## 🗺️ Roadmap

### Phase 1 (Current) ✅
- [x] User authentication & profiles
- [x] Venue browsing & booking
- [x] Payment verification
- [x] E-ticket generation
- [x] Admin dashboard
- [x] Revenue analytics
- [x] Staff management
- [x] Real-time chat
- [x] Security features

### Phase 2 (Planned)
- [ ] Mobile app for iOS
- [ ] Web admin dashboard
- [ ] QR code scanner for venue staff
- [ ] Automated refund processing
- [ ] Integration with payment gateways
- [ ] Advanced analytics & reporting
- [ ] Multi-language support
- [ ] Dark mode

### Phase 3 (Future)
- [ ] Mobile app for staff/operators
- [ ] IoT integration for field sensors
- [ ] AI-based booking recommendations
- [ ] Dynamic pricing algorithms
- [ ] Loyalty program
- [ ] Advanced user analytics

---

## 🤝 Contributing

This is a proprietary project developed for DISPORA Kabupaten Bandung.

For internal contributors:

1. Create feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -m "feat: add feature"`
3. Push branch: `git push origin feature/your-feature`
4. Create Pull Request

### Commit Message Format

Follow conventional commits:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Formatting
- `refactor:` Code refactoring
- `test:` Tests
- `chore:` Maintenance

---

## 🐛 Troubleshooting

### Common Issues

**1. Supabase Connection Error**
- Check internet connection
- Verify SUPABASE_URL in .env
- Check Supabase project status

**2. Build Errors**
```bash
flutter clean
flutter pub get
flutter build apk
```

## 📞 Support

### Technical Support
- **Issues**: Create issue on GitHub
- **Email**: dev-team@sipelor-bedas.com
- **Documentation**: See `docs/` directory

### Business Support
- **DISPORA**: dispora@bandungkab.go.id
- **Admin**: admin@sipelor-bedas.com

---

## 📄 License

This project is proprietary software developed for DISPORA Kabupaten Bandung.

**All rights reserved © 2026 DISPORA Kabupaten Bandung**

---

## 🙏 Acknowledgments

- **DISPORA Kabupaten Bandung** for project sponsorship
- **Flutter Team** for the amazing framework
- **Supabase** for backend infrastructure
- **Open Source Community** for valuable packages

---

## 📸 Screenshots

*(Add screenshots here when available)*

---

<div align="center">

**Built with ❤️ by Development Team for DISPORA Kabupaten Bandung**

Version 1.0.0+1 • Last Updated: 26 Januari 2026

</div>
# sipelorbedas
# sipelorbedas
