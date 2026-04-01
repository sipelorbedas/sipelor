# 📋 Manual Testing Plan - SIPELOR BEDAS

> **Comprehensive manual testing checklist for QA team**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026  
> **Test Environment**: Staging/Production

---

## 🎯 Test Objectives

- Verify all user flows work end-to-end
- Identify critical bugs before production
- Ensure security features function correctly
- Validate UI/UX meets requirements
- Test edge cases and error handling
- Verify cross-device compatibility

---

## 👥 Test Team Roles

| Role | Responsibility | Count |
|------|---------------|-------|
| QA Lead | Coordinate testing, review results | 1 |
| QA Tester | Execute test cases, log bugs | 2-3 |
| Developer | Fix bugs, retest | 1-2 |
| Product Owner | Accept/reject features | 1 |

---

## 📱 Test Environment Setup

### Required Test Devices

**Android:**
- [ ] Low-end device (2GB RAM, Android 8.0)
- [ ] Mid-range device (4GB RAM, Android 11)
- [ ] High-end device (6GB+ RAM, Android 13+)
- [ ] Tablet (10" screen)

**Network Conditions:**
- [ ] WiFi (fast connection)
- [ ] 4G/LTE (mobile data)
- [ ] 3G (slow connection)
- [ ] Offline mode

**Screen Sizes:**
- [ ] Small (5" - 5.5")
- [ ] Medium (5.5" - 6.5")
- [ ] Large (6.5"+)
- [ ] Tablet (10"+)

### Test Data Requirements

**Test Accounts:**
```
User Account 1:
- Email: test.user1@sipelor.test
- Password: TestUser123!
- Status: Verified

User Account 2:
- Email: test.user2@sipelor.test
- Password: TestUser123!
- Status: Unverified

Admin Account:
- Email: admin@sipelor.test
- Password: AdminTest123!
- Role: Admin
```

**Test Venues:**
- Minimum 5 venues dengan different types
- Each venue harus punya min 3 fields
- Various price ranges (Rp 50k - Rp 300k)
- Different locations

---

## 📝 Test Cases

### Category 1: Authentication & Security (25 test cases)

#### TC-AUTH-001: Sign Up - Happy Path
**Priority**: 🔴 Critical  
**Precondition**: None  
**Steps**:
1. Launch app
2. Tap "Daftar" button
3. Enter valid email: `newuser@test.com`
4. Enter valid password: `Test123!`
5. Enter matching confirm password
6. Tap "Daftar"

**Expected Result**:
- ✅ Account created successfully
- ✅ Verification email sent
- ✅ Redirect to email verification banner
- ✅ Toast message shows success

**Status**: [ ] Pass [ ] Fail [ ] Blocked  
**Tested By**: __________ **Date**: __________  
**Notes**: _______________

---

#### TC-AUTH-002: Sign Up - Invalid Email
**Priority**: 🟡 High  
**Steps**:
1. Launch app → Daftar
2. Enter invalid email: `notanemail`
3. Enter valid password
4. Tap "Daftar"

**Expected**:
- ✅ Error message: "Email tidak valid"
- ✅ Cannot proceed to registration

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-003: Sign Up - Weak Password
**Priority**: 🟡 High  
**Steps**:
1. Launch app → Daftar
2. Enter valid email
3. Enter weak password: `123`
4. Tap "Daftar"

**Expected**:
- ✅ Error: "Password min 8 characters"
- ✅ Password strength indicator shows "Weak"

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-004: Sign Up - Password Mismatch
**Priority**: 🟡 High  
**Steps**:
1. Launch app → Daftar
2. Enter email and password: `Test123!`
3. Enter different confirm password: `Test456!`
4. Tap "Daftar"

**Expected**:
- ✅ Error: "Password tidak cocok"

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-005: Sign In - Happy Path
**Priority**: 🔴 Critical  
**Steps**:
1. Launch app → Masuk
2. Enter verified email
3. Enter correct password
4. Tap "Masuk"

**Expected**:
- ✅ Redirect to home screen
- ✅ User profile loads
- ✅ Bottom navigation shows

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-006: Sign In - Wrong Password
**Priority**: 🔴 Critical  
**Steps**:
1. Launch app → Masuk
2. Enter valid email
3. Enter wrong password
4. Tap "Masuk"

**Expected**:
- ✅ Error: "Email atau password salah"
- ✅ Failed attempt counted (3 max)
- ✅ No redirect

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-007: Sign In - Account Lockout
**Priority**: 🔴 Critical  
**Steps**:
1. Attempt sign in dengan wrong password 3x
2. Try signing in 4th time

**Expected**:
- ✅ Account locked for 1 hour
- ✅ Error message shows lockout time
- ✅ Cannot login even with correct password

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-008: Email Verification - Resend
**Priority**: 🟡 High  
**Steps**:
1. Login dengan unverified account
2. See verification banner
3. Tap "Kirim Ulang"
4. Check email

**Expected**:
- ✅ Success message shown
- ✅ Email received in inbox
- ✅ Rate limiting works (max 3 per hour)

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-009: Email Verification - Click Link
**Priority**: 🔴 Critical  
**Steps**:
1. Open verification email
2. Click verification link
3. Return to app

**Expected**:
- ✅ Email verified in Supabase
- ✅ Banner disappears on app refresh
- ✅ Can now create bookings

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-010: Forgot Password
**Priority**: 🔴 Critical  
**Steps**:
1. Sign In screen → "Lupa Password"
2. Enter registered email
3. Tap "Kirim Email Reset"
4. Check email
5. Click reset link
6. Enter new password
7. Login dengan new password

**Expected**:
- ✅ Reset email received
- ✅ Deep link opens app
- ✅ Can set new password
- ✅ Old password no longer works
- ✅ New password works

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-011: Biometric Authentication Setup
**Priority**: 🟡 High  
**Precondition**: Device has fingerprint enrolled  
**Steps**:
1. Login → Profile → Security Settings
2. Enable "Login dengan Sidik Jari"
3. Authenticate dengan fingerprint
4. Logout
5. Try login dengan biometric

**Expected**:
- ✅ Biometric prompt shows
- ✅ Can login dengan fingerprint
- ✅ No password required

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-012: Auto Logout - Inactivity
**Priority**: 🟡 High  
**Steps**:
1. Login to app
2. Don't interact for 15 minutes
3. Try to navigate

**Expected**:
- ✅ Session expired message
- ✅ Redirect to login screen
- ✅ Must login again

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-AUTH-013: Change Password
**Priority**: 🔴 Critical  
**Steps**:
1. Profile → Security Settings
2. Tap "Ubah Password"
3. Enter old password
4. Enter new password
5. Enter confirm password
6. Save

**Expected**:
- ✅ Password updated
- ✅ Other sessions logged out
- ✅ Audit log created
- ✅ Can login dengan new password

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 2: Venue Browsing & Search (15 test cases)

#### TC-VENUE-001: Browse All Venues
**Priority**: 🔴 Critical  
**Steps**:
1. Login → Home
2. Scroll venue list

**Expected**:
- ✅ All venues displayed
- ✅ Venue cards show: photo, name, location, rating, price
- ✅ Smooth scrolling
- ✅ Images load correctly

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-VENUE-002: Filter by Sport Type
**Priority**: 🟡 High  
**Steps**:
1. Home → Categories
2. Tap "Futsal"

**Expected**:
- ✅ Only futsal venues shown
- ✅ Count matches filter
- ✅ Can clear filter

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-VENUE-003: View Venue Detail
**Priority**: 🔴 Critical  
**Steps**:
1. Tap any venue card
2. View detail page

**Expected**:
- ✅ Full venue info displayed
- ✅ Photo gallery works
- ✅ Fields list shown
- ✅ Reviews displayed
- ✅ Location map shown
- ✅ "Booking" button visible

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-VENUE-004: View Venue Reviews
**Priority**: 🟡 High  
**Steps**:
1. Venue detail → Scroll to reviews
2. Read reviews

**Expected**:
- ✅ Reviews display dengan rating
- ✅ User name & date shown
- ✅ Review text readable
- ✅ Photos attached (if any)

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-VENUE-005: Search Venues
**Priority**: 🟡 High  
**Steps**:
1. Home → Search bar
2. Type venue name
3. View results

**Expected**:
- ✅ Real-time search results
- ✅ Matching venues displayed
- ✅ No results message if empty

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 3: Booking Flow (30 test cases)

#### TC-BOOK-001: Create Booking - Happy Path
**Priority**: 🔴 Critical  
**Precondition**: Verified account  
**Steps**:
1. Browse venue → Select venue
2. Tap "Booking Sekarang"
3. Select field (e.g., "Lapangan A")
4. Select date (tomorrow)
5. Select time slot (09:00 - 10:00)
6. Review booking details
7. Tap "Lanjut ke Pembayaran"
8. View payment instruction
9. Upload payment proof (JPG/PNG)
10. Tap "Submit"

**Expected**:
- ✅ Booking created dengan status "pending"
- ✅ Payment timer starts (24 hours)
- ✅ Redirect to booking detail
- ✅ Admin notified untuk verification

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-002: Booking - Unverified Email Block
**Priority**: 🔴 Critical  
**Precondition**: Unverified email account  
**Steps**:
1. Login dengan unverified account
2. Try to create booking
3. Tap "Booking Sekarang"

**Expected**:
- ✅ Dialog blocks booking
- ✅ Message: "Verifikasi email dulu"
- ✅ Option to resend verification
- ✅ Cannot proceed with booking

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-003: Time Slot - Already Booked
**Priority**: 🔴 Critical  
**Steps**:
1. Select field
2. Select date
3. Try to select already booked slot

**Expected**:
- ✅ Slot disabled/grayed out
- ✅ Cannot select
- ✅ Shows "Sudah dibooking" label

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-004: Time Slot - Past Time Block
**Priority**: 🟡 High  
**Steps**:
1. Select today's date
2. Try to select past time slot

**Expected**:
- ✅ Past slots disabled
- ✅ Cannot select
- ✅ Shows "Tidak tersedia"

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-005: Payment Upload - Invalid Format
**Priority**: 🟡 High  
**Steps**:
1. Create booking → Payment screen
2. Try to upload PDF file

**Expected**:
- ✅ Error: "Only JPG/PNG allowed"
- ✅ File not uploaded

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-006: Payment Upload - Large File
**Priority**: 🟡 High  
**Steps**:
1. Payment screen
2. Upload 10MB image

**Expected**:
- ✅ Error: "Max file size 5MB" atau
- ✅ Image compressed automatically

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-007: Payment Timer - Expiration
**Priority**: 🔴 Critical  
**Steps**:
1. Create booking
2. Wait for payment timer to expire (or manually change system time)
3. Check booking status

**Expected**:
- ✅ Booking auto-cancelled
- ✅ Status changed to "expired"
- ✅ Slot released for others
- ✅ Notification sent to user

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-008: View Booking History
**Priority**: 🔴 Critical  
**Steps**:
1. Bottom nav → "Orders"
2. View booking list

**Expected**:
- ✅ All bookings displayed
- ✅ Shows: venue, date, time, status, price
- ✅ Sorted by date (newest first)
- ✅ Status badge colored correctly

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-009: View E-Ticket
**Priority**: 🔴 Critical  
**Precondition**: Approved booking  
**Steps**:
1. Orders → Select approved booking
2. Tap "Lihat E-Ticket"

**Expected**:
- ✅ E-ticket displayed dengan QR code
- ✅ Shows: booking info, venue, date, time
- ✅ QR code scannable
- ✅ Can save ticket to gallery
- ✅ Can share ticket

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-BOOK-010: Download Ticket
**Priority**: 🟡 High  
**Steps**:
1. View E-ticket
2. Tap "Download"
3. Check gallery

**Expected**:
- ✅ Ticket saved as image
- ✅ Success message shown
- ✅ Image viewable in gallery

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 4: Review System (10 test cases)

#### TC-REVIEW-001: Submit Review - Happy Path
**Priority**: 🔴 Critical  
**Precondition**: Completed booking  
**Steps**:
1. Orders → Completed booking
2. Tap "Beri Review"
3. Select 5 stars
4. Write review text
5. Tap "Kirim"

**Expected**:
- ✅ Review submitted
- ✅ Shows on venue detail
- ✅ Venue rating updated
- ✅ Cannot review again

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-REVIEW-002: Review - Before Booking Completed
**Priority**: 🟡 High  
**Steps**:
1. Orders → Pending/confirmed booking
2. Try to review

**Expected**:
- ✅ Review button disabled atau hidden
- ✅ Message: "Tunggu booking selesai"

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-REVIEW-003: Review - Duplicate Prevention
**Priority**: 🟡 High  
**Steps**:
1. Submit review untuk booking
2. Try to review same booking again

**Expected**:
- ✅ Review button hidden
- ✅ Shows "Sudah direview"

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 5: Chat with Admin (15 test cases)

#### TC-CHAT-001: Start Chat - From Booking
**Priority**: 🔴 Critical  
**Steps**:
1. Booking detail screen
2. Tap "Chat Admin"
3. Type message
4. Send

**Expected**:
- ✅ Chat screen opens
- ✅ Message sent
- ✅ Admin receives message
- ✅ Real-time delivery

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-CHAT-002: Receive Admin Reply
**Priority**: 🔴 Critical  
**Steps**:
1. Send message to admin
2. Wait for admin to reply

**Expected**:
- ✅ Reply shows immediately (Realtime)
- ✅ Notification received
- ✅ Message displayed correctly

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-CHAT-003: Send Image in Chat
**Priority**: 🟡 High  
**Steps**:
1. Open chat
2. Tap attach image icon
3. Select image
4. Send

**Expected**:
- ✅ Image uploaded
- ✅ Thumbnail displayed
- ✅ Full image viewable on tap

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 6: Admin Dashboard (25 test cases)

#### TC-ADMIN-001: View Dashboard - Analytics
**Priority**: 🔴 Critical  
**Steps**:
1. Login as admin
2. View dashboard

**Expected**:
- ✅ Total bookings shown
- ✅ Revenue displayed
- ✅ Pending verifications count
- ✅ Charts render correctly
- ✅ Recent bookings list

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-002: Approve Booking
**Priority**: 🔴 Critical  
**Steps**:
1. Admin dashboard
2. Navigate to pending bookings
3. Select booking
4. Verify payment proof
5. Tap "Approve"

**Expected**:
- ✅ Status changed to "confirmed"
- ✅ Payment status = "paid"
- ✅ User notified
- ✅ E-ticket generated
- ✅ Audit log created

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-003: Reject Booking
**Priority**: 🔴 Critical  
**Steps**:
1. Pending bookings
2. Select booking
3. Tap "Reject"
4. Enter rejection reason
5. Confirm

**Expected**:
- ✅ Status changed to "cancelled"
- ✅ Slot released
- ✅ User notified dengan reason
- ✅ Audit log created

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-004: Bulk Approve Bookings
**Priority**: 🟡 High  
**Steps**:
1. Pending bookings list
2. Select multiple bookings (checkbox)
3. Tap "Bulk Approve"
4. Confirm

**Expected**:
- ✅ All selected approved
- ✅ Success count shown
- ✅ Users notified
- ✅ E-tickets generated

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-005: View Revenue Analytics
**Priority**: 🟡 High  
**Steps**:
1. Admin menu → Revenue Analytics
2. View monthly report
3. Change date range

**Expected**:
- ✅ Charts display correctly
- ✅ Revenue breakdown by venue
- ✅ Can filter by date
- ✅ Export to CSV works

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-006: Manage Staff
**Priority**: 🟡 High  
**Steps**:
1. Admin menu → Staff Management
2. Tap "Add Staff"
3. Fill details (name, email, role)
4. Save

**Expected**:
- ✅ Staff created
- ✅ Email invitation sent
- ✅ Shows in staff list

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-007: Schedule Maintenance
**Priority**: 🟡 High  
**Steps**:
1. Admin → Maintenance Schedule
2. Create new schedule
3. Select venue & field
4. Set date range
5. Assign staff
6. Save

**Expected**:
- ✅ Maintenance scheduled
- ✅ Field status = "maintenance"
- ✅ Slot blocked for booking
- ✅ Users notified if existing booking

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ADMIN-008: View Audit Logs
**Priority**: 🟡 High  
**Steps**:
1. Admin → Audit Logs
2. View activity history

**Expected**:
- ✅ All admin actions logged
- ✅ Shows: timestamp, user, action, details
- ✅ Can filter by date/user/action

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 7: Notifications (15 test cases)

#### TC-NOTIF-001: Booking Approved Notification
**Priority**: 🔴 Critical  
**Steps**:
1. Admin approves booking
2. Check user device

**Expected**:
- ✅ Push notification received
- ✅ Notification shows: "Booking disetujui"
- ✅ Tap opens booking detail
- ✅ In-app notification badge

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-NOTIF-002: Payment Reminder
**Priority**: 🟡 High  
**Steps**:
1. Create booking
2. Wait 15 min before expiry

**Expected**:
- ✅ Reminder notification sent
- ✅ Shows time remaining
- ✅ Tap opens payment screen

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-NOTIF-003: Notification Preferences
**Priority**: 🟡 High  
**Steps**:
1. Profile → Settings → Notifications
2. Disable "Promo & Diskon"
3. Admin sends promo broadcast

**Expected**:
- ✅ User doesn't receive promo notif
- ✅ Other notif types still work

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 8: Profile & Settings (15 test cases)

#### TC-PROFILE-001: View Profile
**Priority**: 🔴 Critical  
**Steps**:
1. Bottom nav → Profile

**Expected**:
- ✅ Profile info displayed
- ✅ Avatar shown (or default)
- ✅ Name, email, phone shown
- ✅ Menu items visible

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-PROFILE-002: Edit Profile
**Priority**: 🔴 Critical  
**Steps**:
1. Profile → Tap "Edit Profile"
2. Change name
3. Change phone
4. Save

**Expected**:
- ✅ Profile updated
- ✅ Success message shown
- ✅ Changes reflected immediately

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-PROFILE-003: Upload Profile Photo
**Priority**: 🟡 High  
**Steps**:
1. Edit Profile
2. Tap avatar
3. Select photo from gallery
4. Save

**Expected**:
- ✅ Photo uploaded to Supabase Storage
- ✅ Avatar updated
- ✅ Shows across app

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 9: Error Handling & Edge Cases (20 test cases)

#### TC-ERROR-001: Network Offline - Browse
**Priority**: 🔴 Critical  
**Steps**:
1. Turn off internet
2. Try to browse venues

**Expected**:
- ✅ Error message: "Tidak ada koneksi"
- ✅ Retry button shown
- ✅ App doesn't crash

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ERROR-002: Network Offline - Create Booking
**Priority**: 🔴 Critical  
**Steps**:
1. Start booking flow
2. Turn off internet
3. Try to submit

**Expected**:
- ✅ Error message shown
- ✅ Data preserved (not lost)
- ✅ Can retry when online

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ERROR-003: Session Expired - API Call
**Priority**: 🟡 High  
**Steps**:
1. Login
2. Manually expire session in Supabase
3. Try any API action

**Expected**:
- ✅ Session expired detected
- ✅ Redirect to login
- ✅ Error logged in Sentry

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-ERROR-004: Malformed Data from API
**Priority**: 🟡 High  
**Steps**:
1. Manually corrupt venue data in DB
2. Try to load venue detail

**Expected**:
- ✅ Graceful error handling
- ✅ User-friendly error message
- ✅ App doesn't crash
- ✅ Error logged

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 10: Performance & Load (10 test cases)

#### TC-PERF-001: Load Time - Home Screen
**Priority**: 🟡 High  
**Steps**:
1. Launch app (fresh install)
2. Login
3. Measure time to home screen

**Expected**:
- ✅ < 3 seconds on WiFi
- ✅ < 5 seconds on 4G

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________  
**Actual Time**: __________

---

#### TC-PERF-002: Scroll Performance - Venue List
**Priority**: 🟡 High  
**Steps**:
1. Browse 100+ venues
2. Scroll rapidly

**Expected**:
- ✅ Smooth scrolling (60 FPS)
- ✅ No lag or jank
- ✅ Images lazy load

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-PERF-003: Memory Usage - Long Session
**Priority**: 🟢 Medium  
**Steps**:
1. Use app for 30 minutes
2. Navigate between screens
3. Check memory usage

**Expected**:
- ✅ < 200MB RAM usage
- ✅ No memory leaks

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 11: Security Testing (15 test cases)

#### TC-SEC-001: SQL Injection - Login
**Priority**: 🔴 Critical  
**Steps**:
1. Login screen
2. Enter email: `' OR '1'='1`
3. Try to login

**Expected**:
- ✅ Login fails
- ✅ Input sanitized
- ✅ No SQL error shown

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-SEC-002: XSS Attack - Review Text
**Priority**: 🔴 Critical  
**Steps**:
1. Submit review dengan script: `<script>alert('XSS')</script>`

**Expected**:
- ✅ Script sanitized
- ✅ No script execution
- ✅ Text rendered safely

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-SEC-003: Certificate Pinning - MITM
**Priority**: 🔴 Critical  
**Precondition**: Proxy with fake cert (Burp Suite)  
**Steps**:
1. Route traffic through proxy
2. Try to intercept API calls

**Expected**:
- ✅ Connection fails
- ✅ Certificate mismatch detected
- ✅ User warned

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-SEC-004: Sensitive Data in Logs
**Priority**: 🔴 Critical  
**Steps**:
1. Login to app
2. Check Android logcat

**Expected**:
- ✅ No passwords in logs
- ✅ No tokens in logs
- ✅ No API keys visible

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-SEC-005: Encrypted Local Storage
**Priority**: 🔴 Critical  
**Steps**:
1. Login
2. Check app data folder
3. View database/SharedPreferences

**Expected**:
- ✅ Credentials encrypted
- ✅ Cannot read plaintext data

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

### Category 12: Usability & Accessibility (10 test cases)

#### TC-UI-001: Text Readability - Small Screen
**Priority**: 🟡 High  
**Steps**:
1. Test on 5" device
2. Check all text elements

**Expected**:
- ✅ All text readable
- ✅ No overflow
- ✅ Font sizes appropriate

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-UI-002: Touch Targets - Minimum Size
**Priority**: 🟡 High  
**Steps**:
1. Test all buttons
2. Measure touch area

**Expected**:
- ✅ All buttons >= 44x44 dp
- ✅ Easy to tap
- ✅ No accidental taps

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

#### TC-UI-003: Color Contrast - Readability
**Priority**: 🟢 Medium  
**Steps**:
1. Check text on backgrounds
2. Test with accessibility tool

**Expected**:
- ✅ WCAG AA compliant
- ✅ Contrast ratio >= 4.5:1

**Status**: [ ] Pass [ ] Fail  
**Tested By**: __________ **Date**: __________

---

## 📊 Test Summary

### Test Execution Tracking

**Total Test Cases**: 215+  
**Executed**: ____ / 215  
**Passed**: ____  
**Failed**: ____  
**Blocked**: ____  
**Pass Rate**: ____%

### Critical Issues Found

| ID | Severity | Description | Status |
|----|----------|-------------|--------|
| BUG-001 | 🔴 Critical | | [ ] Open [ ] Fixed |
| BUG-002 | 🟡 High | | [ ] Open [ ] Fixed |
| BUG-003 | 🟢 Medium | | [ ] Open [ ] Fixed |

### Test Coverage

| Category | Test Cases | Executed | Pass | Fail |
|----------|-----------|----------|------|------|
| Authentication | 25 | ___ | ___ | ___ |
| Venue Browsing | 15 | ___ | ___ | ___ |
| Booking Flow | 30 | ___ | ___ | ___ |
| Review System | 10 | ___ | ___ | ___ |
| Chat | 15 | ___ | ___ | ___ |
| Admin Dashboard | 25 | ___ | ___ | ___ |
| Notifications | 15 | ___ | ___ | ___ |
| Profile | 15 | ___ | ___ | ___ |
| Error Handling | 20 | ___ | ___ | ___ |
| Performance | 10 | ___ | ___ | ___ |
| Security | 15 | ___ | ___ | ___ |
| Usability | 10 | ___ | ___ | ___ |

---

## 🚨 Test Exit Criteria

Testing can be considered complete when:

- [ ] ≥ 95% test cases executed
- [ ] ≥ 90% pass rate achieved
- [ ] All critical bugs fixed
- [ ] All high priority bugs fixed
- [ ] No show-stopper bugs remaining
- [ ] Performance benchmarks met
- [ ] Security tests passed
- [ ] Regression testing completed
- [ ] Sign-off from Product Owner

---

## 📝 Notes & Recommendations

### Testing Tips

1. **Test on Real Devices**: Emulators don't catch all issues
2. **Test Different Network Conditions**: WiFi, 4G, 3G, offline
3. **Test Edge Cases**: Empty states, max limits, special characters
4. **Document Everything**: Screenshots, logs, steps to reproduce
5. **Retest After Fixes**: Verify bug fixes don't create new issues

### Common Issues to Watch For

- Image loading failures
- Payment proof upload errors
- Real-time chat delays
- Notification not received
- Session timeout issues
- Memory leaks during long usage
- Crash on back button
- Data loss on app restart

---

**Test Plan Version**: 1.0  
**Created By**: QA Team  
**Approved By**: ____________  
**Date**: 28 Januari 2026
