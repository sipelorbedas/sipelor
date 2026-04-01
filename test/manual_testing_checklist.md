# 📋 Manual Testing Checklist - SIPELOR BEDAS

> **Version**: 1.0.0  
> **Last Updated**: 28 Januari 2026  
> **Target Coverage**: 100% of critical user flows

---

## 🎯 Testing Objectives

- Verify all critical user flows work end-to-end
- Validate UI/UX across different devices and screen sizes
- Ensure data integrity and security measures
- Test error handling and edge cases
- Verify performance and responsiveness

---

## ✅ Authentication & Security

### Sign Up Flow
- [ ] User can create account with email and password
- [ ] Form validation works (email format, password strength)
- [ ] Email verification email is sent
- [ ] User cannot access booking features before email verification
- [ ] Error messages are clear and helpful
- [ ] Loading states are shown appropriately

### Sign In Flow
- [ ] User can login with verified email and password
- [ ] Invalid credentials show appropriate error
- [ ] "Forgot Password" link works
- [ ] Remember me functionality works (if implemented)
- [ ] Biometric login works (if device supports)
- [ ] Rate limiting prevents brute force (max 5 attempts)

### Password Management
- [ ] Forgot password sends reset email
- [ ] Reset password link works and expires appropriately
- [ ] New password meets security requirements
- [ ] User can change password in settings
- [ ] Old password is required for password change

### Session Management
- [ ] Auto logout after 15 minutes of inactivity
- [ ] User is redirected to login after logout
- [ ] Session persists on app restart (if not timed out)
- [ ] Multiple devices handling works correctly

### Security Features
- [ ] Biometric authentication can be enabled/disabled
- [ ] Security notifications appear for critical actions
- [ ] Sensitive data is not visible in logs (check debug console)
- [ ] SSL pinning prevents MITM attacks (test with proxy)

---

## 🏟️ Venue & Field Management

### Browse Venues
- [ ] Venue list loads correctly with images
- [ ] Search functionality works (name, location)
- [ ] Filters work (type, price range, rating)
- [ ] Sorting works (price, rating, distance)
- [ ] Pagination/infinite scroll works
- [ ] Empty state shows when no results

### Venue Details
- [ ] All venue information displays correctly
- [ ] Image gallery works (swipe, zoom)
- [ ] Rating and reviews display correctly
- [ ] Available fields list shows correct data
- [ ] Pricing information is clear
- [ ] Location map displays correctly
- [ ] "Book Now" button navigates to booking

### Field Selection
- [ ] Available time slots display correctly
- [ ] Unavailable slots are disabled
- [ ] Price calculation updates correctly
- [ ] Field type selection works
- [ ] Date picker works correctly
- [ ] Time range validation works (min 1 hour)

---

## 📅 Booking Flow

### Create Booking
- [ ] Time slot selection works correctly
- [ ] Price calculation is accurate
- [ ] Booking confirmation shows all details
- [ ] Payment instructions are clear
- [ ] Payment timer (30 minutes) displays correctly
- [ ] User can upload payment proof (image)
- [ ] File size validation works (max size)
- [ ] File type validation works (image only)

### Booking Management
- [ ] User can view all their bookings
- [ ] Bookings are filtered by status (pending, confirmed, completed, cancelled)
- [ ] Booking details show all information
- [ ] User can cancel booking (within allowed timeframe)
- [ ] Cancellation confirmation dialog works
- [ ] E-ticket displays correctly after payment approval

### E-Ticket
- [ ] QR code generates correctly
- [ ] Ticket can be saved to gallery
- [ ] Ticket can be shared
- [ ] All booking details are visible
- [ ] Ticket design is clear and professional

### Booking Expiration
- [ ] Unpaid bookings expire after 30 minutes
- [ ] User receives notification before expiration
- [ ] Expired bookings are automatically cancelled
- [ ] Time slot becomes available again after cancellation

---

## 💬 Chat & Communication

### User Chat
- [ ] User can access chat from booking details
- [ ] User can send text messages
- [ ] User can send images
- [ ] Messages display in correct order
- [ ] Real-time updates work (new messages appear instantly)
- [ ] Read status indicators work
- [ ] Unread count displays correctly
- [ ] Notification shows for new messages

### Admin Chat
- [ ] Admin can view all user chats
- [ ] Chat list shows unread counts
- [ ] Admin can reply to users
- [ ] Admin can send images
- [ ] Messages are filtered by booking (if applicable)
- [ ] Search/filter chats works

### Content Moderation
- [ ] Offensive content is blocked
- [ ] SARA content is filtered
- [ ] User receives appropriate error message
- [ ] URLs and special characters are handled

---

## ⭐ Reviews & Ratings

### Submit Review
- [ ] Review form appears after booking completion
- [ ] User can rate (1-5 stars)
- [ ] User can write comment
- [ ] Review submission works
- [ ] Review appears in venue details
- [ ] User cannot review same booking twice

### Review Management
- [ ] Reviews display correctly on venue details
- [ ] Average rating calculates correctly
- [ ] Reviews can be sorted (most recent, highest rated)
- [ ] User can edit their own review
- [ ] User can delete their own review

### Admin Review Moderation
- [ ] Admin can view all reviews
- [ ] Admin can delete inappropriate reviews
- [ ] Admin receives notification for flagged reviews
- [ ] Deleted reviews don't appear in venue details

---

## 👨‍💼 Admin Dashboard

### Dashboard Overview
- [ ] Statistics display correctly (revenue, bookings, users)
- [ ] Charts render properly (revenue chart, booking chart)
- [ ] Recent bookings list shows latest data
- [ ] Pending approvals count is accurate
- [ ] Quick actions work (approve, reject)
- [ ] Responsive on desktop and tablet

### Field Management
- [ ] Admin can view all fields
- [ ] Admin can create new field (with validation)
- [ ] Admin can edit field details
- [ ] Admin can delete field (with confirmation)
- [ ] Admin can toggle field availability
- [ ] Field images upload works
- [ ] Bulk operations work (if implemented)

### Booking Management
- [ ] Admin can view all bookings
- [ ] Admin can filter by status, date, venue
- [ ] Admin can approve bookings
- [ ] Admin can reject bookings (with reason)
- [ ] Admin can cancel bookings (with notification)
- [ ] Payment proof displays correctly
- [ ] Admin can download booking data (CSV/PDF)

### Staff Management
- [ ] Admin can view all staff members
- [ ] Admin can invite new staff (via email)
- [ ] Admin can assign roles (Admin, Manager, Operator)
- [ ] Admin can deactivate staff accounts
- [ ] Role-based permissions work correctly
- [ ] Audit logs track staff actions

### Revenue Analytics
- [ ] Revenue charts display correctly
- [ ] Date range filters work
- [ ] Revenue breakdown by venue works
- [ ] Export reports functionality works
- [ ] Automated reports are sent via email
- [ ] Report scheduling works (daily/weekly/monthly)

### Maintenance Schedule
- [ ] Admin can create maintenance schedule
- [ ] Scheduled maintenance blocks bookings
- [ ] Users see maintenance notification
- [ ] Maintenance history is tracked
- [ ] Recurring maintenance works

### Audit Logs
- [ ] All admin actions are logged
- [ ] Logs show user, action, timestamp, details
- [ ] Logs can be filtered and searched
- [ ] Logs are immutable (cannot be deleted)
- [ ] Logs can be exported

---

## 🔔 Notifications

### Push Notifications
- [ ] User receives booking confirmation notification
- [ ] User receives payment approval notification
- [ ] User receives booking reminder (24h before)
- [ ] User receives chat message notification
- [ ] Admin receives new booking notification
- [ ] Admin receives payment proof upload notification
- [ ] Notifications can be toggled on/off
- [ ] Notification sound/vibration works

### In-App Notifications
- [ ] Notification bell shows unread count
- [ ] Notification list displays all notifications
- [ ] Notifications can be marked as read
- [ ] Notifications can be cleared
- [ ] Deep links work (tap notification navigates to relevant screen)

### Security Notifications
- [ ] User receives notification for new device login
- [ ] User receives notification for password change
- [ ] User receives notification for email change
- [ ] User can view security event history

---

## 📱 UI/UX & Responsiveness

### Mobile (Android & iOS)
- [ ] App renders correctly on small screens (320px width)
- [ ] App renders correctly on medium screens (375px, 414px)
- [ ] App renders correctly on large screens (tablet)
- [ ] All buttons and inputs are tappable
- [ ] Scrolling is smooth
- [ ] Images load and cache correctly
- [ ] Animations are smooth (no jank)

### Web Browser
- [ ] App renders correctly on desktop (1920x1080)
- [ ] App renders correctly on tablet (768px, 1024px)
- [ ] App is responsive (resize browser window)
- [ ] All features work on web
- [ ] Navigation works correctly
- [ ] Back button works correctly

### Orientation
- [ ] App works in portrait mode
- [ ] App works in landscape mode (if supported)
- [ ] Orientation change doesn't lose data

### Accessibility
- [ ] Text is readable (sufficient contrast)
- [ ] Font sizes are appropriate
- [ ] Touch targets are large enough (min 44x44)
- [ ] Screen reader support (if implemented)
- [ ] Keyboard navigation works (web)

---

## 🚀 Performance

### App Launch
- [ ] Splash screen displays correctly
- [ ] App launches in under 3 seconds
- [ ] Initial data loads quickly
- [ ] No ANR (Application Not Responding) errors

### Navigation
- [ ] Screen transitions are smooth
- [ ] No lag when navigating between screens
- [ ] Back button works correctly everywhere
- [ ] Deep links work correctly

### Data Loading
- [ ] Lists load with pagination (not all at once)
- [ ] Images load with placeholders/shimmer
- [ ] Offline data caching works (if implemented)
- [ ] Pull to refresh works correctly
- [ ] Loading indicators are shown appropriately

### Memory & Resources
- [ ] No memory leaks (test with profiler)
- [ ] App doesn't drain battery excessively
- [ ] Network usage is reasonable
- [ ] Storage usage is reasonable

---

## 🔒 Security Testing

### Data Protection
- [ ] Sensitive data is encrypted at rest
- [ ] Sensitive data is encrypted in transit (HTTPS)
- [ ] No sensitive data in logs
- [ ] No sensitive data in screenshots (e.g., password fields)
- [ ] Secure storage is used for tokens

### Authentication Security
- [ ] Password is hashed (not stored in plain text)
- [ ] JWT tokens expire appropriately
- [ ] Refresh tokens work correctly
- [ ] Rate limiting prevents brute force
- [ ] Account lockout after failed attempts

### Authorization
- [ ] Users can only access their own data
- [ ] Admin features are not accessible to regular users
- [ ] Role-based access control works correctly
- [ ] API requests validate user permissions

### Input Validation
- [ ] All inputs are validated (client & server side)
- [ ] SQL injection is prevented
- [ ] XSS attacks are prevented
- [ ] File upload validation works
- [ ] Content moderation filters offensive content

---

## 📊 Edge Cases & Error Handling

### Network Errors
- [ ] App handles no internet connection gracefully
- [ ] App shows appropriate error message
- [ ] App can retry failed requests
- [ ] Offline mode works (if implemented)

### Data Errors
- [ ] App handles empty states (no data)
- [ ] App handles malformed data gracefully
- [ ] App handles API errors (4xx, 5xx)
- [ ] App shows user-friendly error messages

### User Errors
- [ ] App handles invalid input gracefully
- [ ] App shows validation errors clearly
- [ ] App prevents duplicate submissions
- [ ] App confirms destructive actions (delete, cancel)

### System Errors
- [ ] App handles low memory situations
- [ ] App handles low storage situations
- [ ] App handles permission denied errors
- [ ] App recovers from crashes (if possible)

---

## 🌐 Localization (if implemented)

- [ ] All text is translatable
- [ ] Date/time formats are localized
- [ ] Currency formats are localized
- [ ] App switches language correctly
- [ ] RTL layout works (if applicable)

---

## 📝 Legal & Compliance

- [ ] Terms of Service are accessible
- [ ] Privacy Policy is accessible
- [ ] User consent is obtained appropriately
- [ ] User can delete their account
- [ ] User data export works (GDPR compliance)

---

## ✅ Sign-off

**Tested by**: _____________________  
**Date**: _____________________  
**Build Version**: _____________________  
**Platform**: _____________________  

**Overall Result**: 
- [ ] Pass
- [ ] Pass with minor issues
- [ ] Fail (requires fixes)

**Notes**:
_________________________________________________________
_________________________________________________________
_________________________________________________________
