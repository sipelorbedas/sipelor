# 📧 Quick Start: Email Templates Setup

> **Fast setup guide untuk deploy email templates ke Supabase dalam 20 menit**
> 
> **Version**: 1.0  
> **Last Updated**: 28 Januari 2026

---

## 🎯 Goal

Deploy professional email templates untuk:
- ✉️ Email verification
- 🔐 Password reset
- ✅ Booking notifications
- 📊 Admin reports

---

## 📋 What You Need

1. ✅ Supabase project admin access
2. ✅ Email templates (from `docs/EMAIL_TEMPLATES.md`)
3. ⚪ SMTP provider account (optional but recommended)
4. ⚪ Company logo image URL (optional)

---

## ⚡ Quick Setup (20 Minutes)

### Step 1: Access Supabase Email Settings (2 min)

1. Login to [Supabase Dashboard](https://app.supabase.com)
2. Select your **SIPELOR** project
3. Navigate to **Authentication** → **Email Templates**

You should see 4 default templates:
- Confirm signup
- Invite user
- Magic Link
- Reset Password

### Step 2: (Optional) Setup SMTP (5 min)

**Skip this if:**
- You're just testing
- Using Supabase's built-in email (limited to 3-4 emails/hour)

**Do this if:**
- Going to production
- Need reliable email delivery
- Want custom sender domain

#### 2a. Choose SMTP Provider

**Recommended:** [Resend](https://resend.com)
- ✅ Free tier: 100 emails/day
- ✅ Easy setup (5 minutes)
- ✅ Modern API
- ✅ Good deliverability

**Alternatives:**
- SendGrid (100 free/day)
- Amazon SES (very cheap)
- Mailgun (feature-rich)

#### 2b. Get SMTP Credentials

**For Resend:**

1. Go to https://resend.com
2. Sign up → Create API key
3. Copy the API key

#### 2c. Configure in Supabase

1. Supabase → **Settings** → **Project Settings** → **SMTP Settings**
2. Toggle "Enable Custom SMTP server"
3. Fill in:

```
Host: smtp.resend.com
Port: 587
Username: resend
Password: [Your Resend API key]
Sender email: noreply@sipelor-bedas.com
Sender name: SIPELOR BEDAS
```

4. Click **Save**
5. Send test email to verify

### Step 3: Deploy Email Verification Template (5 min)

1. Go to **Authentication** → **Email Templates**
2. Click **"Confirm signup"** template
3. Click **"Edit template"**

#### 3a. Copy Template

Open `docs/EMAIL_TEMPLATES.md` and copy the HTML from **Template 1** (lines 49-242)

Or copy from here (abbreviated):

```html
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Verifikasi Email - SIPELOR BEDAS</title>
    <style>
        /* Styles from EMAIL_TEMPLATES.md */
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>🏟️ SIPELOR BEDAS</h1>
            <p>Sistem Pemesanan Lapangan Olahraga</p>
        </div>
        
        <div class="content">
            <h2>Selamat Datang di SIPELOR BEDAS! 🎉</h2>
            <p>Terima kasih telah mendaftar...</p>
            
            <div class="button-container">
                <a href="{{ .ConfirmationURL }}" class="button">
                    ✓ Verifikasi Email Saya
                </a>
            </div>
            
            <!-- Rest of template -->
        </div>
        
        <div class="footer">
            <p><strong>SIPELOR BEDAS</strong></p>
            <p>DISPORA Kabupaten Bandung</p>
        </div>
    </div>
</body>
</html>
```

#### 3b. Customize Placeholders

Update these in the template:

```html
<!-- Contact Email -->
<a href="mailto:support@sipelor-bedas.com">Butuh bantuan?</a>
→ Change to your actual support email

<!-- Website Links -->
<a href="https://sipelor-bedas.com/privacy">Privacy Policy</a>
→ Change to your actual domain

<!-- Phone Number (if you add it) -->
<a href="tel:+622212345678">(022) 1234-5678</a>
→ Change to actual phone
```

#### 3c. Test Subject Line

Update subject:
```
Subject: Verifikasi Email Anda - SIPELOR BEDAS
```

#### 3d. Save Template

1. Click **"Save"**
2. Click **"Send test email"**
3. Enter your email
4. Check inbox (and spam folder)

✅ Template deployed!

### Step 4: Deploy Password Reset Template (5 min)

Same process as Step 3:

1. Click **"Reset Password"** template
2. Copy HTML from `docs/EMAIL_TEMPLATES.md` **Template 2** (lines 250-456)
3. Customize placeholders
4. Update subject: `Reset Password - SIPELOR BEDAS`
5. Save and test

### Step 5: Test Email Flow (3 min)

#### Test Verification Email

```sql
-- Run in Supabase SQL Editor
SELECT auth.send_confirmation_email('your.test@email.com');
```

**Check:**
- [ ] Email received
- [ ] Subject correct
- [ ] Sender shows "SIPELOR BEDAS"
- [ ] Click verification link
- [ ] Link works (deep link or web redirect)

#### Test Password Reset

```sql
SELECT auth.send_password_reset_email('your.test@email.com');
```

**Check:**
- [ ] Email received
- [ ] Subject correct
- [ ] Click reset link
- [ ] Opens app correctly

---

## 🎨 Optional Customization

### Add Real Logo

Replace emoji with image:

```html
<!-- Before -->
<h1>🏟️ SIPELOR BEDAS</h1>

<!-- After -->
<img src="https://your-cdn.com/sipelor-logo.png" 
     alt="SIPELOR BEDAS" 
     width="200" 
     style="display: block; margin: 0 auto;">
```

### Update Brand Colors

Find and replace gradient colors:

```css
/* Current purple gradient */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Change to your brand colors */
background: linear-gradient(135deg, #YOUR_COLOR_1 0%, #YOUR_COLOR_2 100%);
```

### Add Social Media Links

In footer:

```html
<div class="footer">
    <p style="margin-top: 15px;">
        <a href="https://facebook.com/sipelor">Facebook</a> | 
        <a href="https://instagram.com/sipelor">Instagram</a> | 
        <a href="https://twitter.com/sipelor">Twitter</a>
    </p>
</div>
```

---

## 📱 Deep Link Configuration (Optional)

**What are deep links?**
- Email links that open your app directly
- Better user experience (no manual navigation)

**Current behavior:**
```
Email link → Browser → Supabase → Redirect to app
```

**With deep links:**
```
Email link → Opens app directly
```

### How to Enable

1. **Update email template links:**

```html
<!-- Before -->
<a href="{{ .ConfirmationURL }}">Verify Email</a>

<!-- After -->
<a href="sipelor://verify?token={{ .Token }}">Verify Email</a>
```

2. **Configure deep links in app:**
   - See `docs/DEEP_LINKS_CONFIGURATION.md`
   - Or use Universal Links (iOS) / App Links (Android)

3. **Test:**
   - Click email link on mobile device
   - Should open app directly

---

## 📊 Monitoring Email Deliverability

### Check Email Performance

**In your SMTP provider dashboard:**

| Metric | Target | What it means |
|--------|--------|---------------|
| **Delivery Rate** | > 95% | Emails successfully delivered |
| **Open Rate** | > 20% | Users opened email |
| **Click Rate** | > 5% | Users clicked link |
| **Bounce Rate** | < 2% | Invalid email addresses |
| **Spam Rate** | < 0.1% | Marked as spam |

### Improve Deliverability

**If emails going to spam:**

1. **Check spam score:**
   - Go to https://www.mail-tester.com
   - Send test email to provided address
   - Fix issues (aim for score > 8/10)

2. **Setup SPF/DKIM:**
   - Add DNS records (your SMTP provider will guide you)
   - Verifies emails are from your domain
   - Prevents spoofing

3. **Use custom domain:**
   ```
   noreply@sipelor-bedas.com  ✅ Professional
   noreply@gmail.com          ❌ Looks spammy
   ```

---

## 🔧 Advanced: Automated Booking Notifications

**Want to send booking approved emails automatically?**

### Option 1: Database Trigger (Simplest)

```sql
-- Create function to send notification
CREATE OR REPLACE FUNCTION send_booking_approved_email()
RETURNS TRIGGER AS $$
BEGIN
  -- When booking status changes to 'confirmed'
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
    -- Call your email service
    -- (You'll need to setup endpoint/edge function)
    PERFORM net.http_post(
      url := 'https://your-email-service.com/send-booking-approved',
      body := json_build_object(
        'email', (SELECT email FROM profiles WHERE id = NEW.user_id),
        'booking_id', NEW.id,
        'venue_name', (SELECT name FROM venues WHERE id = NEW.venue_id)
      )::text
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach trigger
CREATE TRIGGER on_booking_status_change
  AFTER UPDATE ON bookings
  FOR EACH ROW
  EXECUTE FUNCTION send_booking_approved_email();
```

### Option 2: Supabase Edge Function

```typescript
// supabase/functions/send-booking-email/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const { bookingId, type } = await req.json()
  
  // Fetch booking data
  // Generate email HTML
  // Send via your SMTP provider
  
  return new Response(JSON.stringify({ success: true }))
})
```

### Option 3: From Flutter App

```dart
// In admin_dashboard_screen.dart
Future<void> approveBooking(String bookingId) async {
  // Update booking status
  await supabase.from('bookings')
    .update({'status': 'confirmed'})
    .eq('id', bookingId);
  
  // Send email notification
  await EmailService.sendBookingApprovedEmail(bookingId);
}
```

**Note:** For production, Option 1 (Database Trigger) is most reliable.

---

## ✅ Verification Checklist

Before going live:

### Functionality
- [ ] Verification emails send and receive
- [ ] Password reset emails work
- [ ] Links in emails work correctly
- [ ] Deep links open app (if configured)

### Branding
- [ ] Logo added (or emoji looks good)
- [ ] Brand colors updated
- [ ] Contact info correct
- [ ] Footer links work

### Deliverability
- [ ] SMTP configured (if production)
- [ ] Sender name shows correctly
- [ ] Emails not going to spam
- [ ] Spam score > 8/10 (mail-tester.com)

### Testing
- [ ] Tested in Gmail
- [ ] Tested in Outlook (if targeting enterprise)
- [ ] Tested on mobile email apps
- [ ] All links clickable
- [ ] Images load (if using images)
- [ ] Responsive on mobile

### Performance
- [ ] Email sends within 5 seconds
- [ ] Delivery rate > 95%
- [ ] No errors in Supabase logs

---

## 🚨 Troubleshooting

### Email Not Received

**Check:**
1. Spam/junk folder
2. Email address correct
3. Supabase logs for errors:
   - Dashboard → Logs → Filter by "auth"
4. SMTP provider logs (if using)

**Common causes:**
- Invalid SMTP credentials
- Email rate limit exceeded
- Recipient email blocked

### Email Goes to Spam

**Fix:**
1. Setup SMTP with custom domain
2. Add SPF/DKIM DNS records
3. Don't use words like "free", "winner", "click here"
4. Include unsubscribe link (for marketing emails)

### Email Looks Broken

**Check:**
- HTML syntax errors (use validator)
- Missing closing tags
- CSS inline (not in `<style>` for better compatibility)
- Test in multiple email clients

---

## 📊 Email Template Best Practices

### ✅ Do's

- ✅ Use inline CSS (better compatibility)
- ✅ Keep width ≤ 600px
- ✅ Use tables for layout (yes, like 1999!)
- ✅ Include alt text for images
- ✅ Test in Gmail, Outlook, Apple Mail
- ✅ Make CTAs (buttons) obvious
- ✅ Include company info in footer

### ❌ Don'ts

- ❌ Don't use JavaScript
- ❌ Don't use external stylesheets
- ❌ Don't use background images
- ❌ Don't use forms
- ❌ Don't make emails too long
- ❌ Don't use all caps in subject
- ❌ Don't forget mobile testing

---

## 🎯 Next Steps

After email templates configured:

1. ✅ **Verify all templates work**
2. ⏳ **Setup automated notifications** (booking approved, etc.)
3. ⏳ **Monitor deliverability metrics**
4. 🚀 **Production deployment**

---

## 📞 Need Help?

**Email not working?**
- Check Supabase logs
- Check SMTP provider dashboard
- Test spam score: https://www.mail-tester.com

**Still stuck?**
- Team Slack: #sipelor-deployment
- Email: dev-team@sipelor-bedas.com

---

## 📚 Additional Resources

- **Full templates**: `docs/EMAIL_TEMPLATES.md`
- **Deep links**: `docs/DEEP_LINKS_CONFIGURATION.md`
- **Supabase docs**: https://supabase.com/docs/guides/auth/auth-email-templates
- **Resend docs**: https://resend.com/docs
- **Email HTML guide**: https://www.campaignmonitor.com/dev-resources/guides/coding/

---

**Setup Time**: ~20 minutes  
**Difficulty**: ⭐⭐ (Easy-Medium)  
**Once done**: Professional emails for all users! 📧✨

---

*Last Updated: 28 Januari 2026*
