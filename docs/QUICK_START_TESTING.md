# ⚡ Quick Start - Testing & Soft Launch

> **Panduan Singkat untuk Memulai Testing & Launch**  
> **Target**: Start testing HARI INI!  
> **Waktu Setup**: 2-3 jam

---

## 🎯 TODAY'S ACTION PLAN

### ✅ MORNING (2-3 jam): Setup & Configuration

#### 1. Setup Sentry (30 menit) 🔴 URGENT

**Quick Steps**:
```bash
1. Go to https://sentry.io
2. Sign up → Create project → Flutter
3. Copy DSN (looks like: https://xxx@xxx.ingest.sentry.io/xxx)
4. Test it works
```

**Test Sentry**:
```dart
// Add to any screen temporarily
throw Exception('Test Sentry - Delete this!');
```

---

#### 2. Configure Email Templates (30 menit) 🔴 URGENT

**Quick Steps**:
1. Supabase Dashboard → Authentication → Email Templates
2. Edit "Confirmation" template (Email Verification)
3. Edit "Reset Password" template
4. Save
5. Test by signing up new account

**Quick Template**:
```
Subject: Verifikasi Email SIPELOR BEDAS

Hai!

Klik link di bawah untuk verifikasi email:
{{ .ConfirmationURL }}

Link expired dalam 24 jam.

Salam,
Tim SIPELOR BEDAS
```

---

#### 3. Create Test Plan Spreadsheet (1 jam)

**Quick Steps**:
1. Open Google Sheets
2. Create spreadsheet: `SIPELOR_Test_Cases`
3. Copy test cases from `MANUAL_TESTING_CHECKLIST.md`
4. Add columns: Test ID | Description | Expected | Actual | Status | Bug ID
5. Share dengan team

**Shortcut**: Use the provided template!

---

#### 4. Build Production APK (30 menit)

**Quick Steps**:

**Windows**:
```batch
# 1. Copy template
copy scripts\build_production_env_TEMPLATE.bat scripts\build_production_env.bat

# 2. Edit file, add your credentials:
# - SUPABASE_URL
# - SUPABASE_ANON_KEY  
# - SENTRY_DSN

# 3. Run
.\scripts\build_production_env.bat
```

**Output**: `build\app\outputs\flutter-apk\app-release.apk`

---

### ✅ AFTERNOON (2-3 jam): Start Testing

#### 5. Priority Test Cases (Execute First!)

**Execute these 20 critical tests first** (2 jam):

**Authentication (5 tests)**:
- [ ] TC-001: Sign up with valid email
- [ ] TC-006: Login with valid credentials
- [ ] TC-007: Login with wrong password (rate limiting)
- [ ] TC-010: Verify email from link
- [ ] TC-015: Logout

**Booking Flow (10 tests)**:
- [ ] TC-022: Open venue detail
- [ ] TC-028: Select date
- [ ] TC-030: Select time slot
- [ ] TC-034: Confirm booking
- [ ] TC-036: View payment instructions
- [ ] TC-037: Upload payment proof
- [ ] TC-042: View booking history
- [ ] TC-043: View booking detail
- [ ] TC-044: Download e-ticket
- [ ] TC-047: Chat admin about booking

**Admin (5 tests)**:
- [ ] TC-072: Admin login
- [ ] TC-076: View pending bookings
- [ ] TC-077: Approve booking
- [ ] TC-078: Reject booking
- [ ] TC-081: View field list

**Result**: Log Pass/Fail in spreadsheet

---

### ✅ EVENING (1 jam): Review & Plan

#### 6. Daily Standup (15 menit)

**Discuss**:
- Tests completed today: __ / 20
- Pass rate: ___%
- Critical bugs found: __
- Blockers: Yes / No

#### 7. Log Bugs (30 menit)

**For each failed test**:
1. Create bug in `BUG_TRACKING_TEMPLATE.md`
2. Assign severity (P0/P1/P2/P3)
3. Add screenshot
4. Assign to developer

#### 8. Plan Tomorrow (15 menit)

**Tomorrow's Tasks**:
- [ ] Fix P0 bugs
- [ ] Continue testing (next 30 test cases)
- [ ] Regression test fixed bugs

---

## 📅 WEEK 1 ROADMAP (Quick View)

### Day 1 (TODAY) ✅
- [x] Setup Sentry, Email
- [x] Build production APK
- [x] Execute 20 priority tests

### Day 2 (TOMORROW)
- [ ] Fix P0 bugs from Day 1
- [ ] Execute 30 more test cases (User flows)
- [ ] Setup production Supabase

### Day 3
- [ ] Execute 30 more test cases (Admin flows)
- [ ] Fix P1 bugs
- [ ] Build updated APK

### Day 4
- [ ] Execute remaining test cases (Security, Edge cases)
- [ ] Regression testing
- [ ] Prepare beta test plan

### Day 5
- [ ] Final bug fixes
- [ ] Setup Google Play internal testing
- [ ] Recruit beta testers (5-10 people)

---

## 🚀 WEEK 2 ROADMAP (Quick View)

### Day 6-7: Beta Testing
- [ ] Deploy to Play Store internal testing
- [ ] Onboard beta testers
- [ ] Daily monitoring

### Day 8-9: Bug Fixes
- [ ] Fix beta feedback bugs
- [ ] Regression testing
- [ ] Build final APK

### Day 10: Soft Launch Decision
- [ ] Review metrics
- [ ] Go/No-Go decision
- [ ] Deploy to closed testing (50-100 users)

---

## 📊 SUCCESS METRICS

### Daily Tracking

| Metric | Target | Day 1 | Day 2 | Day 3 | Day 4 | Day 5 |
|--------|--------|-------|-------|-------|-------|-------|
| Tests Executed | 20/day | __ | __ | __ | __ | __ |
| Pass Rate | >80% | __% | __% | __% | __% | __% |
| P0 Bugs | 0 | __ | __ | __ | __ | __ |
| P1 Bugs | <3 | __ | __ | __ | __ | __ |

### Weekly Goal
- ✅ 100+ test cases executed
- ✅ 80%+ pass rate
- ✅ 0 P0 bugs
- ✅ <3 P1 bugs
- ✅ Production APK ready
- ✅ Beta testing started

---

## 🔥 QUICK TIPS

### Testing Efficiently
1. **Test on real device** (not emulator)
2. **Use different accounts** (user & admin)
3. **Take screenshots** of every bug
4. **Test edge cases** (slow network, low battery)
5. **Retest fixed bugs** (regression)

### Bug Reporting
1. **Be specific**: "Login button doesn't work" ❌ → "Login crashes when email field is empty" ✅
2. **Include steps**: Always write 1-2-3 steps
3. **Add evidence**: Screenshot or video
4. **Set priority**: P0/P1/P2/P3

### Time Management
- **Morning**: Configuration & setup
- **Afternoon**: Execute tests
- **Evening**: Review & plan
- **Don't**: Try to test everything in one day!

---

## 📞 NEED HELP?

### Quick References
- 📄 [Full Testing Guide](./TESTING_SOFT_LAUNCH_GUIDE.md)
- ✅ [All Test Cases](./MANUAL_TESTING_CHECKLIST.md) (126 tests)
- 🐛 [Bug Tracking](./BUG_TRACKING_TEMPLATE.md)
- 📊 [Analysis Report](./ANALISIS_PERKEMBANGAN_TERKINI.md)

### Common Issues

**Q: Sentry not receiving errors?**  
A: Check DSN configured correctly in build command

**Q: Email verification not working?**  
A: Check Supabase email templates & SMTP configuration

**Q: APK crashes on launch?**  
A: Check Supabase credentials in build script

**Q: How to test payment?**  
A: Use test image, upload, check admin dashboard for approval

---

## ✅ TODAY'S CHECKLIST

Before end of day, ensure:

- [ ] Sentry configured & tested
- [ ] Email templates customized
- [ ] Production APK built & installed on device
- [ ] Test spreadsheet created
- [ ] 20 priority test cases executed
- [ ] All P0 bugs logged
- [ ] Tomorrow's plan documented

---

## 🎯 LAUNCH COUNTDOWN

**Today**: Day 1 of testing  
**Target Soft Launch**: Day 15 (2 weeks)  
**Days Remaining**: 14 days  

**Let's do this! 🚀**

---

**Document**: Quick Start Guide  
**Version**: 1.0  
**Created**: 28 Januari 2026  

**💪 You got this! Start testing now!**
