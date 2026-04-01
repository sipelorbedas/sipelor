#!/bin/bash
# Certificate Expiry Check Script (Bash)
# Checks Supabase SSL certificate expiry and alerts if renewal needed

echo "╔════════════════════════════════════════════════════════════╗"
echo "║      SSL Certificate Expiry Check - SIPELOR BEDAS        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

DOMAIN="gbhprmibbcqfwjgrkfzq.supabase.co"
ALERT_DAYS=30  # Alert if expiring within 30 days

# Get certificate info
CERT_INFO=$(openssl s_client -servername $DOMAIN -connect $DOMAIN:443 -showcerts </dev/null 2>/dev/null | openssl x509 -noout -dates -issuer -subject 2>/dev/null)

if [ -z "$CERT_INFO" ]; then
    echo "❌ ERROR: Failed to retrieve certificate from $DOMAIN"
    exit 1
fi

# Parse certificate dates
VALID_FROM=$(echo "$CERT_INFO" | grep "notBefore" | cut -d= -f2)
VALID_UNTIL=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)
ISSUER=$(echo "$CERT_INFO" | grep "issuer" | cut -d= -f2-)
SUBJECT=$(echo "$CERT_INFO" | grep "subject" | cut -d= -f2-)

# Calculate days until expiry
EXPIRY_DATE=$(date -d "$VALID_UNTIL" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$VALID_UNTIL" +%s 2>/dev/null)
CURRENT_DATE=$(date +%s)
DAYS_REMAINING=$(( ($EXPIRY_DATE - $CURRENT_DATE) / 86400 ))

# Get SHA-256 fingerprint
SHA256_PIN=$(openssl s_client -servername $DOMAIN -connect $DOMAIN:443 -showcerts </dev/null 2>/dev/null | \
    openssl x509 -pubkey -noout | \
    openssl pkey -pubin -outform der | \
    openssl dgst -sha256 -binary | \
    openssl enc -base64)

# Display info
echo "Domain        : $DOMAIN"
echo "Issuer        : $ISSUER"
echo "Subject       : $SUBJECT"
echo "Valid From    : $VALID_FROM"
echo "Valid Until   : $VALID_UNTIL"
echo "Days Remaining: $DAYS_REMAINING days"
echo "SHA-256 Pin   : sha256/$SHA256_PIN"
echo ""

# Check expiry status
if [ $DAYS_REMAINING -lt 0 ]; then
    echo "🚨 CRITICAL: Certificate has EXPIRED!"
    echo "   Action Required: Update certificate pins immediately!"
    exit 1
elif [ $DAYS_REMAINING -lt 7 ]; then
    echo "🚨 URGENT: Certificate expires in $DAYS_REMAINING days!"
    echo "   Action Required: Update certificate pins NOW!"
    exit 1
elif [ $DAYS_REMAINING -lt $ALERT_DAYS ]; then
    echo "⚠️  WARNING: Certificate expires in $DAYS_REMAINING days"
    echo "   Action Required: Plan certificate update soon"
    exit 0
else
    echo "✅ OK: Certificate is valid for $DAYS_REMAINING days"
    exit 0
fi
