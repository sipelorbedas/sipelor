# 🧪 Testing & Soft Launch Guide - SIPELOR BEDAS

> **Panduan Lengkap untuk Testing dan Soft Launch**
> 
> **Target**: Soft Launch dalam 2-3 minggu  
> **Tanggal**: 28 Januari 2026  
> **Status**: Ready to Execute

---

## 📋 TABLE OF CONTENTS

1. [Phase 1: Pre-Launch Preparation](#phase-1-pre-launch-preparation-week-1)
2. [Phase 2: Testing Execution](#phase-2-testing-execution-week-2)
3. [Phase 3: Beta Testing](#phase-3-beta-testing-week-3)
4. [Phase 4: Soft Launch](#phase-4-soft-launch-week-4)
5. [Monitoring & Support](#monitoring--support)

---

## 🎯 OVERVIEW

### Timeline Summary

| Phase | Duration | Focus | Team Required |
|-------|----------|-------|---------------|
| **Week 1** | 5 hari | Configuration + Test Planning | 1 Dev + 1 QA |
| **Week 2** | 5 hari | Manual Testing + Bug Fixes | 1 Dev + 1 QA |
| **Week 3** | 5 hari | Beta Testing + Production Setup | 1 Dev + 1 DevOps |
| **Week 4** | 5 hari | Soft Launch + Monitoring | Full Team |

### Success Criteria

- ✅ All critical bugs fixed (P0/P1)
- ✅ 80%+ test cases passed
- ✅ Sentry configured and working
- ✅ Production environment ready
- ✅ 5-10 beta testers successfully onboarded
- ✅ Zero critical errors in first 48 hours soft launch

---

## PHASE 1: Pre-Launch Preparation (Week 1)

### Day 1: Configuration Setup

#### Task 1.1: Setup Sentry Error Tracking (2 jam)

**Steps**:
1. Buat Sentry account di https://sentry.io
2. Create new Flutter project
3. Copy DSN dari Project Settings

**Configure in App**:
```bash
# Build dengan Sentry DSN
flutter build apk --release \
  --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=SENTRY_DSN=your_sentry_dsn
```

**Verify**:
- [ ] Trigger test error dan verify muncul di Sentry dashboard
- [ ] Check breadcrumbs working
- [ ] Verify user context captured
- [ ] Setup alert rules (email/Slack)

**Deliverable**: ✅ Sentry configured & tested

---

#### Task 1.2: Email Templates Configuration (2 jam)

**Supabase Dashboard** → Authentication → Email Templates

**Templates to Customize**:

1. **Confirmation Email** (Email Verification)
```html
Subject: Verifikasi Email SIPELOR BEDAS

<h2>Selamat Datang di SIPELOR BEDAS!</h2>
<p>Terima kasih telah mendaftar. Silakan klik tombol di bawah untuk verifikasi email Anda:</p>
<a href="{{ .ConfirmationURL }}">Verifikasi Email</a>
<p>Link akan expired dalam 24 jam.</p>
```

2. **Reset Password Email**
```html
Subject: Reset Password SIPELOR BEDAS

<h2>Reset Password</h2>
<p>Kami menerima permintaan reset password untuk akun Anda.</p>
<a href="{{ .ConfirmationURL }}">Reset Password</a>
<p>Jika Anda tidak melakukan request ini, abaikan email ini.</p>
```

3. **Magic Link Email**
```html
Subject: Login ke SIPELOR BEDAS

<h2>Login Cepat</h2>
<p>Klik link di bawah untuk login:</p>
<a href="{{ .ConfirmationURL }}">Login Sekarang</a>
```

**Verify**:
- [ ] Test email verification flow
- [ ] Test password reset flow
- [ ] Check email arrives dalam <1 menit
- [ ] Verify links working correctly
- [ ] Check spam folder jika perlu

**Deliverable**: ✅ Email templates customized & tested

---

#### Task 1.3: Deep Links Configuration (3 jam)

**Android Configuration** (`android/app/src/main/AndroidManifest.xml`):

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    
    <!-- Deep Links untuk Password Reset -->
    <data
        android:scheme="https"
        android:host="sipelor.dispora-bandung.id"
        android:pathPrefix="/auth/reset-password" />
    
    <!-- Deep Links untuk Email Verification -->
    <data
        android:scheme="https"
        android:host="sipelor.dispora-bandung.id"
        android:pathPrefix="/auth/verify-email" />
</intent-filter>
```

**Supabase Configuration**:

Supabase Dashboard → Authentication → URL Configuration

Add redirect URLs:
```
https://sipelor.dispora-bandung.id/auth/callback
https://sipelor.dispora-bandung.id/auth/reset-password
https://sipelor.dispora-bandung.id/auth/verify-email
```

**Test Deep Links**:
```bash
# Test di Android (via adb)
adb shell am start -W -a android.intent.action.VIEW \
  -d "https://sipelor.dispora-bandung.id/auth/reset-password?token=test123"
```

**Verify**:
- [ ] Password reset link opens app
- [ ] Email verification link opens app
- [ ] Tokens parsed correctly
- [ ] Fallback ke browser jika app not installed

**Deliverable**: ✅ Deep links configured & tested

---

### Day 2: Test Planning & Environment

#### Task 1.4: Create Manual Test Plan (4 jam)

**Create Spreadsheet**: `SIPELOR_Test_Cases.xlsx`

**Structure**:
```
Sheet 1: User Flow Tests (50+ test cases)
Sheet 2: Admin Flow Tests (30+ test cases)
Sheet 3: Security Tests (20+ test cases)
Sheet 4: Edge Cases (20+ test cases)
Sheet 5: Bug Tracking
```

**Use the detailed test cases from**: `MANUAL_TESTING_CHECKLIST.md` (see below)

**Deliverable**: ✅ Test plan spreadsheet ready

---

#### Task 1.5: Production Environment Setup (3 jam)

**Create Production Supabase Project**:

1. Go to https://supabase.com → New Project
2. Name: `sipelor-production`
3. Region: Southeast Asia (Singapore)
4. Database Password: Generate strong password
5. Pricing: Pro plan (recommended untuk production)

**Run Database Migration**:
```sql
-- Execute all SQL scripts dari docs/
-- 1. DATABASE_SETUP_ADMIN_FEATURES.sql
-- 2. SUPABASE_SQL_SCRIPTS_SAFE.sql
```

**Configure Storage Buckets**:
- Create `profile-avatars` (public)
- Create `venue-photos` (public)
- Create `payment-proofs` (private)

**Setup RLS Policies**:
- Execute RLS scripts
- Verify policies working

**Configure Authentication**:
- Enable email provider
- Configure SMTP (or use Supabase default)
- Set password requirements
- Configure session timeout (15 min)

**Verify**:
- [ ] Database schema complete
- [ ] Storage buckets created
- [ ] RLS policies active
- [ ] Authentication working
- [ ] Test data seeded (optional)

**Deliverable**: ✅ Production Supabase ready

---

### Day 3: Build Production APK

#### Task 1.6: Configure Build Secrets (1 jam)

**Create**: `scripts/build_production_env.bat` (Windows)

```batch
@echo off
echo Building SIPELOR BEDAS Production APK...

REM Set environment variables (NEVER COMMIT THIS FILE)
set SUPABASE_URL=https://your-project.supabase.co
set SUPABASE_ANON_KEY=your-anon-key-here
set SENTRY_DSN=https://your-sentry-dsn

REM Build APK
flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY% ^
  --dart-define=SENTRY_DSN=%SENTRY_DSN% ^
  --dart-define=ENVIRONMENT=production

echo.
echo ===================================
echo Build Complete!
echo APK Location: build\app\outputs\flutter-apk\app-release.apk
echo ===================================
pause
```

**Add to `.gitignore`**:
```
scripts/build_production_env.bat
scripts/build_production_env.sh
.env.production
```

---

#### Task 1.7: Build & Test Production APK (2 jam)

**Build**:
```bash
cd d:\RAMA\PROJECT DISPORA\sipelorbedas\sipelor
.\scripts\build_production_env.bat
```

**Verify APK**:
- [ ] Check APK size (<50 MB recommended)
- [ ] Install on test device
- [ ] Test cold start time (<2 seconds)
- [ ] Verify Supabase connection
- [ ] Test Sentry error reporting
- [ ] Check no debug logs in release

**Deliverable**: ✅ Production APK built & verified

---

### Day 4-5: Documentation & Team Prep

#### Task 1.8: Create User Manual (3 jam)

Create: `docs/USER_MANUAL_SIPELOR.md`

**Contents**:
1. Cara Download & Install
2. Cara Register & Login
3. Cara Browse & Booking Lapangan
4. Cara Upload Bukti Bayar
5. Cara Download E-Ticket
6. Cara Chat dengan Admin
7. Cara Review Lapangan
8. FAQ & Troubleshooting

**Format**: Simple, step-by-step dengan screenshots

**Deliverable**: ✅ User manual ready

---

#### Task 1.9: Admin Training (2 jam)

**Train Admin Team on**:
1. Login ke admin dashboard
2. Approve/reject bookings
3. Verify payment proofs
4. Respond to chat messages
5. View analytics & reports
6. Manage venues & fields
7. Handle common issues

**Create**: Admin quick reference card (1 page PDF)

**Deliverable**: ✅ Admin team trained

---

#### Task 1.10: Support Materials (2 jam)

**Create**:

1. **FAQ Document** (common questions & answers)
2. **Troubleshooting Guide** (for users)
3. **Email Response Templates** (for support)
4. **Social Media Response Templates**

**Deliverable**: ✅ Support materials ready

---

### ✅ Week 1 Deliverables Checklist

- [ ] Sentry configured & tested
- [ ] Email templates customized
- [ ] Deep links configured
- [ ] Test plan spreadsheet ready
- [ ] Production Supabase setup
- [ ] Production APK built
- [ ] User manual complete
- [ ] Admin team trained
- [ ] Support materials ready

**Status Check**: Ready for testing phase? ✅

---

## PHASE 2: Testing Execution (Week 2)

### Day 6: User Flow Testing

**Use**: `MANUAL_TESTING_CHECKLIST.md` (see separate document)

**Focus Areas**:
- Authentication flows (8 test cases)
- Venue browsing (6 test cases)
- Booking creation (10 test cases)
- Payment flow (8 test cases)
- Profile management (5 test cases)

**Process**:
1. Execute test case
2. Document result (Pass/Fail)
3. If fail, capture screenshot & details
4. Log bug in tracking sheet
5. Prioritize (P0/P1/P2/P3)

**Target**: Complete 50+ user flow test cases

**Deliverable**: Test results logged

---

### Day 7: Admin Flow Testing

**Focus Areas**:
- Admin login & dashboard (5 test cases)
- Booking management (10 test cases)
- Payment verification (6 test cases)
- Field management (8 test cases)
- Analytics & reports (5 test cases)

**Target**: Complete 30+ admin flow test cases

**Deliverable**: Test results logged

---

### Day 8: Security & Edge Case Testing

**Security Tests**:
- SQL injection attempts
- XSS attempts
- Authentication bypass attempts
- Rate limiting verification
- Session management tests
- Data encryption verification

**Edge Cases**:
- Network interruption during booking
- App backgrounding during payment
- Multiple bookings conflict
- Invalid date/time selections
- Large file uploads
- Memory pressure testing

**Target**: Complete 20+ security & edge case tests

**Deliverable**: Test results logged

---

### Day 9-10: Bug Fixing Sprint

**Process**:

1. **Morning**: Daily standup, review bugs
2. **Work**: Fix bugs by priority
3. **Afternoon**: Test fixes
4. **Evening**: Update bug status

**Priority**:
- **P0 (Blocker)**: Fix immediately - app crashes, data loss
- **P1 (Critical)**: Fix before launch - major features broken
- **P2 (High)**: Fix if time permits - minor features issues
- **P3 (Low)**: Log for future - cosmetic issues

**Target**: 
- 100% P0 bugs fixed
- 90%+ P1 bugs fixed
- 50%+ P2 bugs fixed
- P3 bugs logged for future

**Deliverable**: Critical bugs fixed & verified

---

### ✅ Week 2 Deliverables Checklist

- [ ] 80%+ test cases passed
- [ ] All P0 bugs fixed
- [ ] 90%+ P1 bugs fixed
- [ ] Regression testing done
- [ ] Test report generated
- [ ] APK rebuilt dengan fixes

**Status Check**: Ready for beta testing? ✅

---

## PHASE 3: Beta Testing (Week 3)

### Day 11: Beta Testing Setup

#### Task 3.1: Google Play Console Setup (3 jam)

**Create Google Play Console Account** (if not exists):
1. Go to https://play.google.com/console
2. Pay one-time $25 registration fee
3. Complete developer profile

**Create App**:
1. Create App → SIPELOR BEDAS
2. Fill app details (name, description, category)
3. Upload screenshots, icon, feature graphic
4. Set content rating
5. Fill privacy policy URL

**Setup Internal Testing Track**:
1. Testing → Internal testing → Create release
2. Upload production APK
3. Add release notes
4. Add testers email list (5-10 emails)

**Deliverable**: ✅ Internal testing track ready

---

#### Task 3.2: Recruit Beta Testers (2 jam)

**Target**: 5-10 internal testers

**Criteria**:
- Mix of admin & user roles
- Different Android devices/versions
- Willing to provide feedback
- Available for 1 week testing

**Onboarding**:
1. Send invitation email dengan test link
2. Provide user manual
3. Create WhatsApp group untuk quick feedback
4. Set expectations (test duration, feedback format)

**Deliverable**: ✅ Beta testers recruited & onboarded

---

### Day 12-14: Beta Testing Period

**Daily Activities**:

**Morning**:
- Check Sentry for new errors
- Review feedback dari beta testers
- Prioritize issues

**Afternoon**:
- Fix critical issues
- Push hotfix builds if needed
- Respond to tester questions

**Evening**:
- Collect feedback summary
- Update bug tracking
- Plan next day priorities

**Metrics to Track**:
- App crashes (target: 0)
- Booking completion rate (target: >80%)
- Payment upload success rate (target: >90%)
- User satisfaction (survey: target >4/5)

**Deliverable**: Beta testing feedback collected

---

### Day 15: Beta Review & Final Fixes

**Activities**:
1. Review all beta feedback
2. Fix any critical issues found
3. Regression testing
4. Final APK build
5. Prepare for soft launch

**Go/No-Go Decision**:

**GO if**:
- ✅ Zero P0 bugs
- ✅ <3 P1 bugs (non-blocking)
- ✅ 80%+ tester satisfaction
- ✅ No crashes in 3 days
- ✅ Production environment stable

**NO-GO if**:
- ❌ Any P0 bugs exist
- ❌ >5 P1 bugs
- ❌ <60% tester satisfaction
- ❌ Frequent crashes
- ❌ Production environment issues

**Deliverable**: Go/No-Go decision made

---

### ✅ Week 3 Deliverables Checklist

- [ ] Play Store internal testing live
- [ ] 5-10 beta testers onboarded
- [ ] 3-5 days testing completed
- [ ] Feedback collected & analyzed
- [ ] Critical issues fixed
- [ ] Final production APK ready
- [ ] Go decision approved

**Status Check**: Ready for soft launch? ✅

---

## PHASE 4: Soft Launch (Week 4)

### Day 16: Soft Launch Deployment

#### Task 4.1: Deploy to Play Store Closed Testing (2 jam)

**Steps**:
1. Play Console → Testing → Closed testing
2. Create new release
3. Upload final production APK
4. Write release notes
5. Add testers list (50-100 emails)
6. Review & publish

**Release Notes Template**:
```
SIPELOR BEDAS v1.0.0

🎉 Soft Launch - Limited Release

Fitur Utama:
✅ Booking lapangan olahraga online
✅ Payment verification
✅ E-ticket dengan QR code
✅ Real-time chat dengan admin
✅ Review & rating system

Fitur Admin:
✅ Dashboard analytics
✅ Revenue reporting
✅ Staff management
✅ Automated reports

Keamanan:
🔒 Data encryption
🔒 Biometric authentication
🔒 SSL certificate pinning

Catatan: Ini adalah soft launch. Feedback sangat dihargai!

Kontak Support: support@sipelor.com
```

**Deliverable**: ✅ Closed testing live

---

#### Task 4.2: User Onboarding (2 jam)

**Send Email to 50-100 Testers**:

```
Subject: Selamat! Anda Terpilih sebagai Early User SIPELOR BEDAS

Halo!

Anda terpilih sebagai early user untuk SIPELOR BEDAS - aplikasi booking lapangan olahraga DISPORA Kabupaten Bandung.

📱 Download: [Play Store Link]
📖 User Manual: [Link]
💬 Support Group: [WhatsApp Group Link]

Kami sangat menghargai feedback Anda untuk membantu kami improve aplikasi.

Terima kasih!
Tim SIPELOR BEDAS
```

**Create**:
- WhatsApp group untuk support
- Feedback form (Google Forms)
- Weekly survey

**Deliverable**: ✅ Users onboarded

---

### Day 17-20: Active Monitoring & Support

**Daily Routine**:

**Morning (9:00 - 12:00)**:
- [ ] Check Sentry dashboard (errors/crashes)
- [ ] Review Play Store ratings/reviews
- [ ] Check booking conversion metrics
- [ ] Respond to WhatsApp support messages

**Afternoon (13:00 - 17:00)**:
- [ ] Analyze user behavior (Supabase analytics)
- [ ] Fix critical bugs if any
- [ ] Respond to feedback forms
- [ ] Admin support & training

**Evening (17:00 - 19:00)**:
- [ ] Daily metrics summary
- [ ] Plan next day priorities
- [ ] Update stakeholders

**Metrics Dashboard** (check daily):

| Metric | Target | Status |
|--------|--------|--------|
| DAU (Daily Active Users) | 20+ | 📊 |
| Booking Conversion | >40% | 📊 |
| Payment Upload Success | >85% | 📊 |
| App Crashes | 0 | 📊 |
| Support Tickets | <5/day | 📊 |
| User Satisfaction | >4.0/5 | 📊 |

---

### ✅ Week 4 Deliverables Checklist

- [ ] Closed testing deployed
- [ ] 50-100 users onboarded
- [ ] Support channels active
- [ ] Daily monitoring established
- [ ] Metrics tracked
- [ ] User feedback collected
- [ ] Hotfixes deployed (if needed)

**Status**: Soft launch complete! ✅

---

## MONITORING & SUPPORT

### Monitoring Tools

**1. Sentry Dashboard** (https://sentry.io)
- Error tracking
- Performance monitoring
- User context
- Alert rules

**2. Supabase Dashboard**
- Database metrics
- API usage
- Storage usage
- Auth events

**3. Google Play Console**
- Crash reports
- ANR (App Not Responding)
- User reviews
- Install metrics

**4. Custom Analytics**
- Booking funnel conversion
- Revenue per venue
- User retention (D1, D7, D30)
- Average session duration

---

### Support Escalation

**Level 1 (Admin/CS)**: User questions, booking issues
- Response time: <1 hour
- Resolve: 80% issues

**Level 2 (Developer)**: Technical issues, bugs
- Response time: <4 hours
- Resolve: 15% issues

**Level 3 (DevOps)**: Infrastructure, critical bugs
- Response time: <1 hour
- Resolve: 5% issues

---

### Success Metrics (30 Days)

**User Metrics**:
- [ ] 100+ registered users
- [ ] 200+ bookings created
- [ ] 80%+ booking completion
- [ ] 70%+ D7 retention
- [ ] 4.0+ rating (Play Store)

**Business Metrics**:
- [ ] Rp 10jt+ revenue processed
- [ ] 5+ active venues
- [ ] 50+ fields available
- [ ] 85%+ payment verification rate

**Technical Metrics**:
- [ ] 99.9%+ uptime
- [ ] <0.1% crash rate
- [ ] <500ms API response time
- [ ] <2s app launch time

---

## EMERGENCY PROCEDURES

### Critical Bug Found

1. **Assess Severity** (P0/P1)
2. **Notify Team** (WhatsApp/Slack)
3. **Fix ASAP** (within 4 hours)
4. **Test Fix** (regression)
5. **Deploy Hotfix** (emergency release)
6. **Notify Users** (if needed)

### Server Down

1. **Check Supabase Status** (status.supabase.com)
2. **Check SSL Certificates** (expiry)
3. **Contact Supabase Support** (if their issue)
4. **Notify Users** (via social media)
5. **Escalate** (if critical)

### Data Breach

1. **Immediate**: Disable affected endpoints
2. **Investigate**: Identify breach source
3. **Contain**: Fix vulnerability
4. **Notify**: Users & authorities (GDPR)
5. **Document**: Incident report
6. **Review**: Security audit

---

## NEXT STEPS AFTER SOFT LAUNCH

### Month 2: Optimization
- [ ] Implement top user feedback
- [ ] Performance optimization
- [ ] Add automated tests
- [ ] Plan payment gateway integration

### Month 3: Payment Gateway
- [ ] Integrate Midtrans
- [ ] Test payment flows
- [ ] Gradual rollout

### Month 4: Full Launch
- [ ] Public release
- [ ] Marketing campaign
- [ ] iOS development (optional)

---

## 📞 CONTACTS & RESOURCES

**Development Team**:
- Lead Developer: [Name] - [Phone/Email]
- QA Tester: [Name] - [Phone/Email]
- DevOps: [Name] - [Phone/Email]

**Operations**:
- Admin Lead: [Name] - [Phone/Email]
- Customer Support: [Name] - [Phone/Email]

**Stakeholders**:
- Project Manager: [Name] - [Phone/Email]
- DISPORA Contact: [Name] - [Phone/Email]

**Emergency**:
- On-Call Developer: [Phone] (24/7)

---

## 📚 REFERENCE DOCUMENTS

- [Manual Testing Checklist](./MANUAL_TESTING_CHECKLIST.md)
- [Bug Tracking Template](./BUG_TRACKING_TEMPLATE.md)
- [User Manual](./USER_MANUAL_SIPELOR.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)
- [Sentry Setup Guide](./SENTRY_SETUP_GUIDE.md)

---

**Document Version**: 1.0  
**Last Updated**: 28 Januari 2026  
**Status**: Ready for Execution  

**🚀 Let's launch SIPELOR BEDAS successfully!**
