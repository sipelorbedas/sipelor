# ✅ Manual Testing Checklist - SIPELOR BEDAS

> **Comprehensive Test Cases untuk Manual Testing**
> 
> **Total Test Cases**: 120+  
> **Estimated Time**: 2-3 hari (2 testers)  
> **Format**: Copy to spreadsheet untuk tracking

---

## 📋 HOW TO USE THIS CHECKLIST

1. **Copy ke Excel/Google Sheets**
2. **Add columns**: Test ID | Test Case | Steps | Expected | Actual | Status | Screenshot | Priority | Notes
3. **Execute tests** satu per satu
4. **Mark status**: ✅ Pass | ❌ Fail | ⏭️ Skip | 🔄 Retest
5. **Log bugs** di bug tracking sheet
6. **Calculate**: Pass Rate = (Pass / Total) × 100%

**Target**: 80%+ Pass Rate untuk launch

---

## 1. AUTHENTICATION & ONBOARDING (15 Test Cases)

### 1.1 Sign Up Flow

**TC-001: Sign Up dengan Email Valid**
- **Steps**:
  1. Open app → Tap "Daftar"
  2. Enter: nama, email valid, password (min 8 char)
  3. Confirm password (sama)
  4. Tap "Daftar"
- **Expected**: 
  - Success message shown
  - Email verification sent
  - Redirect ke home screen
  - Banner "Verifikasi Email" muncul
- **Priority**: P0 (Critical)

**TC-002: Sign Up dengan Email Invalid**
- **Steps**: Enter email tanpa @ atau domain invalid
- **Expected**: Error "Email tidak valid"
- **Priority**: P1

**TC-003: Sign Up dengan Password Lemah**
- **Steps**: Enter password <8 karakter
- **Expected**: Error "Password minimal 8 karakter"
- **Priority**: P1

**TC-004: Sign Up dengan Password Tidak Match**
- **Steps**: Password ≠ Confirm Password
- **Expected**: Error "Password tidak sama"
- **Priority**: P1

**TC-005: Sign Up dengan Email Sudah Terdaftar**
- **Steps**: Gunakan email yang sudah ada
- **Expected**: Error "Email sudah terdaftar"
- **Priority**: P1

### 1.2 Sign In Flow

**TC-006: Login dengan Credentials Valid**
- **Steps**:
  1. Enter registered email & password
  2. Tap "Masuk"
- **Expected**: Login success, redirect ke home
- **Priority**: P0

**TC-007: Login dengan Password Salah**
- **Steps**: Enter wrong password (3x)
- **Expected**: 
  - Error "Password salah"
  - After 3 attempts: "Akun dikunci 1 jam"
- **Priority**: P0

**TC-008: Login dengan Email Tidak Terdaftar**
- **Steps**: Enter unregistered email
- **Expected**: Error "Email tidak terdaftar"
- **Priority**: P1

**TC-009: Login dengan Biometric**
- **Steps**:
  1. Enable biometric di settings (after first login)
  2. Logout
  3. Tap "Login dengan Biometric"
  4. Use fingerprint/face
- **Expected**: Login success tanpa password
- **Priority**: P1

### 1.3 Email Verification

**TC-010: Verify Email dari Link**
- **Steps**:
  1. Check email inbox
  2. Click verification link
  3. Return to app
- **Expected**: 
  - Email verified
  - Banner hilang
  - Can create booking
- **Priority**: P0

**TC-011: Resend Verification Email**
- **Steps**:
  1. Login dengan unverified account
  2. Tap "Kirim Ulang" di banner
- **Expected**: 
  - "Email terkirim" message
  - New email received
- **Priority**: P1

**TC-012: Booking Blocked jika Belum Verify**
- **Steps**:
  1. Login unverified
  2. Try to create booking
- **Expected**: Dialog "Verifikasi email dulu"
- **Priority**: P0

### 1.4 Password Management

**TC-013: Change Password**
- **Steps**:
  1. Profile → Security Settings → Ubah Password
  2. Enter old password, new password
  3. Save
- **Expected**: 
  - Password changed
  - Success message
  - Force re-login
- **Priority**: P1

**TC-014: Forgot Password**
- **Steps**:
  1. Login screen → "Lupa Password"
  2. Enter email
  3. Check email → click reset link
  4. Enter new password
- **Expected**: 
  - Reset email sent
  - Password changed
  - Can login dengan new password
- **Priority**: P1

**TC-015: Logout**
- **Steps**: Profile → Logout → Confirm
- **Expected**: 
  - Logged out
  - Redirect ke sign in screen
  - Clear session
- **Priority**: P0

---

## 2. VENUE BROWSING & SEARCH (12 Test Cases)

### 2.1 Venue List

**TC-016: Load Venue List**
- **Steps**: Open app (logged in) → Home tab
- **Expected**: 
  - Venues loaded
  - Show: foto, nama, rating, harga
  - Shimmer loading while fetching
- **Priority**: P0

**TC-017: Search Venue by Name**
- **Steps**: 
  1. Tap search bar
  2. Type venue name (e.g., "Futsal")
- **Expected**: Filtered results shown
- **Priority**: P1

**TC-018: Filter by Sport Type**
- **Steps**: 
  1. Tap filter button
  2. Select sport (Futsal/Badminton/Basket)
  3. Apply
- **Expected**: Filtered venues shown
- **Priority**: P1

**TC-019: Sort by Rating**
- **Steps**: 
  1. Tap sort button
  2. Select "Rating Tertinggi"
- **Expected**: Venues sorted by rating (high to low)
- **Priority**: P2

**TC-020: Sort by Price**
- **Steps**: Select "Harga Terendah"
- **Expected**: Venues sorted by price (low to high)
- **Priority**: P2

**TC-021: Empty Search Result**
- **Steps**: Search "xyz123nonexistent"
- **Expected**: "Tidak ada hasil" message
- **Priority**: P2

### 2.2 Venue Detail

**TC-022: Open Venue Detail**
- **Steps**: Tap any venue card
- **Expected**: 
  - Venue detail screen opens
  - Show: foto, deskripsi, fasilitas, fields, reviews
- **Priority**: P0

**TC-023: View Venue Photos**
- **Steps**: Swipe photo gallery
- **Expected**: Multiple photos shown, smooth swipe
- **Priority**: P2

**TC-024: View Field List**
- **Steps**: Scroll ke section "Lapangan Tersedia"
- **Expected**: 
  - List of fields
  - Show: nama, harga, status
- **Priority**: P0

**TC-025: View Reviews**
- **Steps**: Scroll ke section "Review"
- **Expected**: 
  - Reviews shown dengan rating & komentar
  - User avatar & name
  - Review date
- **Priority**: P1

**TC-026: Tap Book Button**
- **Steps**: Tap "Booking Sekarang"
- **Expected**: Navigate ke booking confirmation screen
- **Priority**: P0

**TC-027: Share Venue**
- **Steps**: Tap share icon
- **Expected**: Share dialog opens (WhatsApp, dll)
- **Priority**: P3

---

## 3. BOOKING FLOW (20 Test Cases)

### 3.1 Booking Creation

**TC-028: Select Date**
- **Steps**:
  1. Venue detail → Booking
  2. Tap date selector
  3. Select tomorrow's date
- **Expected**: 
  - Calendar opens
  - Today & past dates disabled
  - Selected date highlighted
- **Priority**: P0

**TC-029: Select Past Date**
- **Steps**: Try to select yesterday
- **Expected**: Date disabled/unselectable
- **Priority**: P1

**TC-030: Select Time Slot**
- **Steps**: 
  1. After selecting date
  2. View available time slots
  3. Select "08:00 - 10:00"
- **Expected**: 
  - Available slots shown (green)
  - Booked slots shown (grey/disabled)
  - Selected slot highlighted
- **Priority**: P0

**TC-031: Select Booked Time Slot**
- **Steps**: Try to select grey/booked slot
- **Expected**: Cannot select, error message
- **Priority**: P1

**TC-032: Enter Booking Notes**
- **Steps**: Enter optional notes (max 200 char)
- **Expected**: Text accepted, counter shown
- **Priority**: P2

**TC-033: Review Booking Summary**
- **Steps**: Scroll ke section "Ringkasan"
- **Expected**: 
  - Show: venue, field, date, time, duration
  - Show: price breakdown
  - Show: total amount
- **Priority**: P0

**TC-034: Confirm Booking**
- **Steps**: Tap "Konfirmasi Booking"
- **Expected**: 
  - Loading indicator
  - Success message
  - Navigate ke payment screen
  - Email notification sent
- **Priority**: P0

**TC-035: Booking Conflict**
- **Steps**: 
  1. User A books slot 08:00-10:00
  2. User B tries to book same slot simultaneously
- **Expected**: 
  - User B gets error "Slot sudah dibooking"
  - Refresh available slots
- **Priority**: P0

### 3.2 Payment Upload

**TC-036: View Payment Instructions**
- **Steps**: After booking confirmed → payment screen
- **Expected**: 
  - Show: bank account info
  - Show: total amount
  - Show: booking ID
  - Show: expiry timer (24 jam)
- **Priority**: P0

**TC-037: Upload Payment Proof**
- **Steps**:
  1. Tap "Upload Bukti Transfer"
  2. Select photo dari gallery
  3. Upload
- **Expected**: 
  - File picker opens
  - Image preview shown
  - Upload progress shown
  - Success message
- **Priority**: P0

**TC-038: Upload Large File (>5MB)**
- **Steps**: Try upload file >5MB
- **Expected**: Error "File terlalu besar (max 5MB)"
- **Priority**: P1

**TC-039: Upload Invalid File (PDF/Doc)**
- **Steps**: Try upload non-image file
- **Expected**: Error "Hanya file gambar (JPG/PNG)"
- **Priority**: P1

**TC-040: Take Photo with Camera**
- **Steps**:
  1. Tap "Ambil Foto"
  2. Take photo dengan camera
  3. Confirm
- **Expected**: 
  - Camera opens
  - Photo captured
  - Uploaded successfully
- **Priority**: P1

**TC-041: Payment Expiration**
- **Steps**: 
  1. Create booking
  2. Don't upload payment
  3. Wait 24+ hours
- **Expected**: 
  - Booking auto-cancelled
  - Status changed to "Expired"
  - Notification sent
- **Priority**: P1

### 3.3 Booking Management

**TC-042: View Booking History**
- **Steps**: Home → Orders tab
- **Expected**: 
  - List all bookings (past & upcoming)
  - Show: venue, date, status
  - Filter tabs: Semua / Pending / Confirmed / Completed
- **Priority**: P0

**TC-043: View Booking Detail**
- **Steps**: Tap any booking card
- **Expected**: 
  - Full booking details shown
  - Payment status shown
  - Action buttons based on status
- **Priority**: P0

**TC-044: Download E-Ticket**
- **Steps**: 
  1. Booking with status "Confirmed"
  2. Tap "Lihat E-Ticket"
  3. Tap "Download"
- **Expected**: 
  - E-ticket screen opens
  - Show: QR code, booking details
  - Download to gallery
  - Success message
- **Priority**: P0

**TC-045: Cancel Booking (Before Approval)**
- **Steps**: 
  1. Booking dengan status "Pending"
  2. Tap "Batalkan Booking"
  3. Confirm
- **Expected**: 
  - Status changed to "Cancelled"
  - Refund info shown (if applicable)
  - Admin notified
- **Priority**: P1

**TC-046: Cannot Cancel Confirmed Booking**
- **Steps**: Try to cancel confirmed booking (< 24h before)
- **Expected**: Error "Booking sudah dikonfirmasi, hubungi admin"
- **Priority**: P2

**TC-047: Chat Admin about Booking**
- **Steps**: 
  1. Booking detail screen
  2. Tap "Chat Admin"
- **Expected**: 
  - Chat screen opens
  - Booking context shown
  - Can send messages
- **Priority**: P1

---

## 4. PROFILE & SETTINGS (10 Test Cases)

### 4.1 Profile Management

**TC-048: View Profile**
- **Steps**: Home → Profile tab
- **Expected**: 
  - Show: avatar, name, email, phone
  - Show: verified badge (if email verified)
  - Action buttons: Edit Profile, Settings
- **Priority**: P0

**TC-049: Edit Profile**
- **Steps**:
  1. Tap "Edit Profil"
  2. Change name, phone
  3. Save
- **Expected**: 
  - Changes saved
  - Success message
  - Updated di backend
- **Priority**: P1

**TC-050: Upload Profile Photo**
- **Steps**:
  1. Edit Profile
  2. Tap avatar → Select photo
  3. Upload
- **Expected**: 
  - New photo shown
  - Uploaded to Supabase storage
- **Priority**: P2

**TC-051: Change Email**
- **Steps**:
  1. Edit Profile
  2. Change email
  3. Save
- **Expected**: 
  - Verification email sent ke new email
  - Email changed after verification
  - Security notification sent
- **Priority**: P1

### 4.2 Settings

**TC-052: Enable Biometric Login**
- **Steps**:
  1. Profile → Settings → Security
  2. Toggle "Login dengan Biometric"
  3. Authenticate
- **Expected**: 
  - Biometric enabled
  - Can use fingerprint/face untuk login
- **Priority**: P1

**TC-053: Disable Biometric Login**
- **Steps**: Toggle off biometric
- **Expected**: 
  - Biometric disabled
  - Require password login
- **Priority**: P2

**TC-054: Enable Push Notifications**
- **Steps**: 
  1. Settings → Notifikasi
  2. Toggle notifikasi ON
- **Expected**: 
  - Notifications enabled
  - Receive test notification
- **Priority**: P1

**TC-055: View Privacy Policy**
- **Steps**: Settings → Kebijakan Privasi
- **Expected**: 
  - Privacy policy screen opens
  - Full content readable
- **Priority**: P2

**TC-056: View Terms of Service**
- **Steps**: Settings → Syarat & Ketentuan
- **Expected**: 
  - ToS screen opens
  - Full content readable
- **Priority**: P2

**TC-057: Logout dari Settings**
- **Steps**: Settings → Logout → Confirm
- **Expected**: Logged out successfully
- **Priority**: P0

---

## 5. CHAT & NOTIFICATIONS (8 Test Cases)

### 5.1 Real-Time Chat

**TC-058: Open Chat List**
- **Steps**: Home → Chat icon
- **Expected**: 
  - List of conversations
  - Show: last message, timestamp
  - Unread badge jika ada
- **Priority**: P1

**TC-059: Start New Chat**
- **Steps**: 
  1. Chat list → New chat
  2. Select admin
  3. Type message
  4. Send
- **Expected**: 
  - Chat screen opens
  - Message sent
  - Admin receives notification
- **Priority**: P1

**TC-060: Receive Message**
- **Steps**: 
  1. Admin sends message
  2. User receives
- **Expected**: 
  - Message appears in real-time
  - Push notification shown
  - Unread badge updated
- **Priority**: P1

**TC-061: Send Photo in Chat**
- **Steps**:
  1. Chat screen
  2. Tap attach icon
  3. Select photo
  4. Send
- **Expected**: 
  - Photo uploaded
  - Shown in chat
  - Admin receives photo
- **Priority**: P2

**TC-062: Chat while Offline**
- **Steps**:
  1. Disable network
  2. Try to send message
- **Expected**: 
  - Error "Tidak ada koneksi"
  - Message queued untuk retry
- **Priority**: P2

### 5.2 Push Notifications

**TC-063: Booking Confirmation Notification**
- **Steps**: Admin approves booking
- **Expected**: 
  - Notification received
  - Tapping opens booking detail
- **Priority**: P1

**TC-064: Payment Reminder Notification**
- **Steps**: Booking dibuat, belum bayar (6 jam)
- **Expected**: 
  - Reminder notification sent
  - Tapping opens payment screen
- **Priority**: P2

**TC-065: New Chat Message Notification**
- **Steps**: Admin sends chat message
- **Expected**: 
  - Notification received
  - Tapping opens chat
- **Priority**: P1

---

## 6. REVIEWS & RATINGS (6 Test Cases)

**TC-066: View Venue Reviews**
- **Steps**: Venue detail → Reviews section
- **Expected**: 
  - All reviews shown
  - Average rating calculated
  - Sort by: newest, highest rating
- **Priority**: P1

**TC-067: Add Review (After Completed Booking)**
- **Steps**:
  1. Booking dengan status "Completed"
  2. Tap "Beri Review"
  3. Rate 1-5 stars
  4. Enter comment
  5. Submit
- **Expected**: 
  - Review saved
  - Shown di venue detail
  - Admin can see review
- **Priority**: P1

**TC-068: Cannot Review Before Booking Complete**
- **Steps**: Try to review venue without completed booking
- **Expected**: "Review button" tidak muncul
- **Priority**: P1

**TC-069: Cannot Review Twice**
- **Steps**: Try to review same booking 2x
- **Expected**: Error "Sudah memberikan review"
- **Priority**: P2

**TC-070: Edit Review**
- **Steps**:
  1. View own review
  2. Tap "Edit"
  3. Change rating/comment
  4. Save
- **Expected**: 
  - Review updated
  - Edit time shown
- **Priority**: P2

**TC-071: Delete Review**
- **Steps**:
  1. Own review
  2. Tap "Hapus"
  3. Confirm
- **Expected**: 
  - Review deleted
  - Removed dari venue
- **Priority**: P3

---

## 7. ADMIN DASHBOARD (15 Test Cases)

### 7.1 Admin Login

**TC-072: Admin Login**
- **Steps**: Login dengan admin credentials
- **Expected**: 
  - Login success
  - Redirect ke admin dashboard
- **Priority**: P0

**TC-073: User Cannot Access Admin**
- **Steps**: Login dengan user account → try access admin
- **Expected**: Error "Akses ditolak"
- **Priority**: P0

### 7.2 Dashboard Overview

**TC-074: View Dashboard Stats**
- **Steps**: Admin dashboard home
- **Expected**: 
  - Total bookings today
  - Revenue today
  - Pending approvals count
  - Active users count
- **Priority**: P0

**TC-075: View Revenue Chart**
- **Steps**: Dashboard → Analytics section
- **Expected**: 
  - Chart shown (line/bar)
  - Filter by: day, week, month
  - Interactive tooltips
- **Priority**: P1

### 7.3 Booking Management

**TC-076: View Pending Bookings**
- **Steps**: Dashboard → Bookings → Pending tab
- **Expected**: 
  - List of pending bookings
  - Show: user, venue, date, amount
- **Priority**: P0

**TC-077: Approve Booking**
- **Steps**:
  1. Select pending booking
  2. Verify payment proof
  3. Tap "Setujui"
  4. Confirm
- **Expected**: 
  - Status changed to "Confirmed"
  - User receives notification
  - Email sent to user
- **Priority**: P0

**TC-078: Reject Booking**
- **Steps**:
  1. Select pending booking
  2. Tap "Tolak"
  3. Enter reason
  4. Confirm
- **Expected**: 
  - Status changed to "Rejected"
  - User notified dengan reason
  - Refund process info shown
- **Priority**: P0

**TC-079: View Payment Proof**
- **Steps**: 
  1. Booking detail
  2. Tap payment proof image
- **Expected**: 
  - Full screen image viewer
  - Pinch to zoom
- **Priority**: P1

**TC-080: Bulk Approve Bookings**
- **Steps**:
  1. Select multiple bookings (checkbox)
  2. Tap "Approve Semua"
  3. Confirm
- **Expected**: 
  - All selected bookings approved
  - Batch notifications sent
- **Priority**: P2

### 7.4 Field Management

**TC-081: View Field List**
- **Steps**: Dashboard → Lapangan
- **Expected**: 
  - All fields shown
  - Show: venue, nama, harga, status
- **Priority**: P0

**TC-082: Add New Field**
- **Steps**:
  1. Tap "Tambah Lapangan"
  2. Fill form: venue, nama, area, harga
  3. Upload photo
  4. Save
- **Expected**: 
  - Field created
  - Shown di list
  - Available for booking
- **Priority**: P1

**TC-083: Edit Field**
- **Steps**:
  1. Select field
  2. Edit price
  3. Save
- **Expected**: 
  - Field updated
  - New price shown di booking
- **Priority**: P1

**TC-084: Set Field Maintenance**
- **Steps**:
  1. Select field
  2. Change status to "Maintenance"
  3. Set date range
  4. Save
- **Expected**: 
  - Field unavailable untuk booking
  - Status shown as "Maintenance"
  - Auto available after end date
- **Priority**: P1

### 7.5 Reports & Analytics

**TC-085: Generate Revenue Report**
- **Steps**:
  1. Dashboard → Laporan
  2. Select date range
  3. Tap "Generate"
- **Expected**: 
  - Report generated
  - Show: total revenue, bookings, per venue
  - Export to PDF/CSV
- **Priority**: P1

**TC-086: Export Report**
- **Steps**: 
  1. Generated report
  2. Tap "Export CSV"
- **Expected**: 
  - CSV file downloaded
  - Contains all data
- **Priority**: P2

---

## 8. SECURITY TESTING (12 Test Cases)

### 8.1 Authentication Security

**TC-087: Rate Limiting - Login**
- **Steps**: Try login dengan wrong password 5x rapidly
- **Expected**: 
  - After 3 attempts: Lockout 1 hour
  - Error message shown
- **Priority**: P0

**TC-088: Session Timeout**
- **Steps**: 
  1. Login
  2. Don't interact for 15 minutes
  3. Try any action
- **Expected**: 
  - Auto logout
  - Redirect ke login screen
- **Priority**: P1

**TC-089: Concurrent Sessions**
- **Steps**: 
  1. Login di device A
  2. Login di device B dengan same account
- **Expected**: 
  - Both sessions work
  - Security notification sent
- **Priority**: P2

### 8.2 Data Protection

**TC-090: SSL Pinning**
- **Steps**: Try MITM attack dengan proxy (advanced)
- **Expected**: App blocks connection
- **Priority**: P0

**TC-091: Sensitive Data Encryption**
- **Steps**: Check device storage (rooted device)
- **Expected**: 
  - No plain text passwords
  - Payment proofs encrypted
  - Session tokens secure
- **Priority**: P0

**TC-092: SQL Injection Attempt**
- **Steps**: Enter SQL injection payload in search/forms
- **Example**: `' OR '1'='1`
- **Expected**: Treated as string, no DB breach
- **Priority**: P0

**TC-093: XSS Attempt**
- **Steps**: Enter HTML/JS in text fields
- **Example**: `<script>alert('XSS')</script>`
- **Expected**: Sanitized, no script execution
- **Priority**: P0

### 8.3 Authorization

**TC-094: Access Control - User to Admin**
- **Steps**: User try access admin endpoints directly
- **Expected**: 403 Forbidden error
- **Priority**: P0

**TC-095: Access Other User's Data**
- **Steps**: User A try access User B's bookings via URL manipulation
- **Expected**: 403 Forbidden or 404 Not Found
- **Priority**: P0

### 8.4 Audit Logging

**TC-096: Admin Actions Logged**
- **Steps**:
  1. Admin approve/reject booking
  2. Check audit logs
- **Expected**: 
  - Action logged
  - Show: admin ID, action, timestamp
- **Priority**: P1

**TC-097: Security Event Notification**
- **Steps**: 
  1. Login dari new device
  2. Check notifications
- **Expected**: Security alert received
- **Priority**: P1

**TC-098: Failed Login Attempts Tracked**
- **Steps**: 
  1. Multiple failed logins
  2. Check security logs
- **Expected**: All attempts logged dengan IP
- **Priority**: P1

---

## 9. PERFORMANCE TESTING (8 Test Cases)

**TC-099: App Launch Time**
- **Steps**: Cold start app
- **Expected**: <2 seconds to home screen
- **Priority**: P1

**TC-100: Screen Transition Speed**
- **Steps**: Navigate between screens
- **Expected**: 
  - Smooth 60 FPS animations
  - <300ms transition
- **Priority**: P2

**TC-101: Image Loading**
- **Steps**: Browse venues with many photos
- **Expected**: 
  - Images load progressively
  - Cached untuk reuse
  - No lag while scrolling
- **Priority**: P1

**TC-102: Large List Scrolling**
- **Steps**: Scroll booking history (100+ items)
- **Expected**: 
  - Smooth scrolling
  - Lazy loading
  - No memory leak
- **Priority**: P1

**TC-103: Network Latency**
- **Steps**: Test dengan slow 3G network
- **Expected**: 
  - Loading indicators shown
  - Timeout after 30s
  - Graceful error handling
- **Priority**: P2

**TC-104: Offline Behavior**
- **Steps**: 
  1. Enable airplane mode
  2. Try various actions
- **Expected**: 
  - Error messages clear
  - Cached data still shown
  - Retry option available
- **Priority**: P2

**TC-105: Memory Usage**
- **Steps**: Monitor app memory (Android Studio Profiler)
- **Expected**: 
  - <150 MB average
  - No memory leaks
  - Proper image disposal
- **Priority**: P2

**TC-106: Battery Usage**
- **Steps**: Monitor battery drain (24 hour test)
- **Expected**: 
  - <5% per day (background)
  - Efficient location/network usage
- **Priority**: P3

---

## 10. EDGE CASES & ERROR HANDLING (12 Test Cases)

**TC-107: Network Error During Booking**
- **Steps**: 
  1. Start booking
  2. Disable network mid-flow
  3. Continue
- **Expected**: 
  - Error message clear
  - Data saved locally (if possible)
  - Retry option
- **Priority**: P1

**TC-108: App Killed During Payment Upload**
- **Steps**:
  1. Start uploading payment proof
  2. Kill app (swipe from recents)
  3. Reopen app
- **Expected**: 
  - Upload resumable or restarted
  - No data loss
- **Priority**: P1

**TC-109: Low Storage Space**
- **Steps**: Device storage <50 MB
- **Expected**: 
  - Warning shown
  - Can't upload photos
  - Clear error message
- **Priority**: P2

**TC-110: Date/Time Change**
- **Steps**: 
  1. Book for tomorrow
  2. Change device time to yesterday
  3. View booking
- **Expected**: 
  - Server time used (not device)
  - Booking still valid
- **Priority**: P2

**TC-111: Multiple Booking Conflicts**
- **Steps**: 
  1. User books venue A at 10:00
  2. Try book venue B at same time (valid use case)
- **Expected**: Both bookings allowed
- **Priority**: P2

**TC-112: Invalid QR Code**
- **Steps**: 
  1. Get e-ticket QR
  2. Modify QR data
  3. Try scan
- **Expected**: Error "QR tidak valid"
- **Priority**: P2

**TC-113: Expired Session During Action**
- **Steps**:
  1. Login, wait 15 min
  2. Try create booking
- **Expected**: 
  - Session expired error
  - Redirect to login
  - Return to same screen after login
- **Priority**: P1

**TC-114: Special Characters in Input**
- **Steps**: Enter emoji, symbols in nama/notes
- **Expected**: 
  - Accepted & saved correctly
  - Display correctly
- **Priority**: P2

**TC-115: Very Long Input**
- **Steps**: Enter 1000+ characters in notes
- **Expected**: 
  - Character limit enforced
  - Counter shown
  - Truncate jika over
- **Priority**: P2

**TC-116: Back Button Behavior**
- **Steps**: 
  1. Navigate deep (5+ screens)
  2. Press back repeatedly
- **Expected**: 
  - Navigate back correctly
  - Confirm before exit app
- **Priority**: P1

**TC-117: App Update Available**
- **Steps**: Simulate new version available
- **Expected**: 
  - Update prompt shown
  - Can skip (if not forced)
  - Link to Play Store
- **Priority**: P2

**TC-118: Permission Denied**
- **Steps**: 
  1. Deny camera/storage permission
  2. Try upload photo
- **Expected**: 
  - Error message clear
  - Link to settings
  - Alternative option shown
- **Priority**: P1

---

## 11. DEVICE COMPATIBILITY (8 Test Cases)

**TC-119: Test pada Android 8.0**
- **Expected**: App works smoothly
- **Priority**: P1

**TC-120: Test pada Android 13+**
- **Expected**: All permissions working
- **Priority**: P1

**TC-121: Small Screen (5 inch)**
- **Expected**: 
  - UI readable
  - No text cut off
  - Buttons accessible
- **Priority**: P1

**TC-122: Large Screen (Tablet)**
- **Expected**: 
  - Layout responsive
  - Admin dashboard optimized
- **Priority**: P2

**TC-123: Different Screen Densities**
- **Expected**: 
  - Images sharp
  - Icons correct size
- **Priority**: P2

**TC-124: Landscape Orientation**
- **Expected**: 
  - Layout adapts
  - All features work
- **Priority**: P3

**TC-125: Low-End Device (2GB RAM)**
- **Expected**: 
  - App doesn't crash
  - Acceptable performance
- **Priority**: P2

**TC-126: High-End Device (8GB+ RAM)**
- **Expected**: 
  - Smooth 60 FPS
  - Quick load times
- **Priority**: P2

---

## 📊 TEST SUMMARY TEMPLATE

### Test Execution Report

**Date**: _________________  
**Tester**: _________________  
**Device**: _________________  
**Android Version**: _________________  

**Total Test Cases**: 126  
**Executed**: _____ / 126  
**Passed**: _____ (___%)  
**Failed**: _____ (___%)  
**Blocked**: _____ (___%)  

### Pass Rate by Category

| Category | Total | Pass | Fail | Pass % |
|----------|-------|------|------|--------|
| Authentication | 15 | ___ | ___ | ___% |
| Browsing | 12 | ___ | ___ | ___% |
| Booking | 20 | ___ | ___ | ___% |
| Profile | 10 | ___ | ___ | ___% |
| Chat | 8 | ___ | ___ | ___% |
| Reviews | 6 | ___ | ___ | ___% |
| Admin | 15 | ___ | ___ | ___% |
| Security | 12 | ___ | ___ | ___% |
| Performance | 8 | ___ | ___ | ___% |
| Edge Cases | 12 | ___ | ___ | ___% |
| Compatibility | 8 | ___ | ___ | ___% |

### Critical Issues Found

| Bug ID | Description | Priority | Status |
|--------|-------------|----------|--------|
| ___ | ___ | ___ | ___ |

### Recommendation

- [ ] **PASS** - Ready for launch (80%+ pass rate, 0 P0 bugs)
- [ ] **CONDITIONAL PASS** - Launch dengan known issues
- [ ] **FAIL** - Need more fixes before launch

**Sign-off**: _________________  
**Date**: _________________

---

**Document Version**: 1.0  
**Total Test Cases**: 126  
**Estimated Time**: 16-20 hours (2 testers × 2-3 days)  

**🧪 Happy Testing! Let's ship quality software!**
