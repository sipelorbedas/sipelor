#!/bin/bash
# ============================================================
#  SIPELOR BEDAS — Twilio WhatsApp OTP Test Script (Linux/Mac)
#  Jalankan: bash scripts/test_twilio_whatsapp_otp.sh
# ============================================================

# ── ISI VARIABEL INI ────────────────────────────────────────
ACCOUNT_SID="ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
AUTH_TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
FROM_NUMBER="+14155238886"
TO_NUMBER="+628xxxxxxxxxx"
OTP_CODE="123456"
# ─────────────────────────────────────────────────────────────

echo ""
echo "============================================================"
echo "  SIPELOR BEDAS - Test Kirim OTP via Twilio WhatsApp"
echo "============================================================"
echo "  From : whatsapp:$FROM_NUMBER"
echo "  To   : whatsapp:$TO_NUMBER"
echo "  OTP  : $OTP_CODE"
echo "============================================================"
echo ""

curl -s -X POST \
  "https://api.twilio.com/2010-04-01/Accounts/$ACCOUNT_SID/Messages.json" \
  --data-urlencode "From=whatsapp:$FROM_NUMBER" \
  --data-urlencode "To=whatsapp:$TO_NUMBER" \
  --data-urlencode "Body=Kode verifikasi SIPELOR BEDAS Anda adalah: *$OTP_CODE*. Kode ini berlaku selama 10 menit. Jangan bagikan kode ini kepada siapapun." \
  -u "$ACCOUNT_SID:$AUTH_TOKEN"

echo ""
echo "============================================================"
echo "  Selesai. Cek WhatsApp di nomor $TO_NUMBER"
echo "============================================================"
