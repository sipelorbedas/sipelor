# Certificate Expiry Check Script (PowerShell)
# Checks Supabase SSL certificate expiry and alerts if renewal needed

Write-Host "╔════════════════════════════════════════════════════════════╗"
Write-Host "║      SSL Certificate Expiry Check - SIPELOR BEDAS        ║"
Write-Host "╚════════════════════════════════════════════════════════════╝"
Write-Host ""

$domain = "gbhprmibbcqfwjgrkfzq.supabase.co"
$alertDays = 30  # Alert if expiring within 30 days

try {
    # Connect and get certificate
    $tcpClient = New-Object System.Net.Sockets.TcpClient($domain, 443)
    $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, {$true})
    $sslStream.AuthenticateAsClient($domain)
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($sslStream.RemoteCertificate)
    
    # Get certificate info
    $issuer = $cert.Issuer
    $subject = $cert.Subject
    $validFrom = $cert.NotBefore
    $validUntil = $cert.NotAfter
    $daysUntilExpiry = ($validUntil - (Get-Date)).Days
    
    # Calculate SHA-256 fingerprint
    $certHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
    $sha256 = "sha256/" + [System.Convert]::ToBase64String($certHash)
    
    # Display info
    Write-Host "Domain       : $domain"
    Write-Host "Issuer       : $issuer"
    Write-Host "Subject      : $subject"
    Write-Host "Valid From   : $validFrom"
    Write-Host "Valid Until  : $validUntil"
    Write-Host "Days Remaining: $daysUntilExpiry days"
    Write-Host "SHA-256 Pin  : $sha256"
    Write-Host ""
    
    # Check expiry status
    if ($daysUntilExpiry -lt 0) {
        Write-Host "🚨 CRITICAL: Certificate has EXPIRED!" -ForegroundColor Red
        Write-Host "   Action Required: Update certificate pins immediately!" -ForegroundColor Red
        exit 1
    }
    elseif ($daysUntilExpiry -lt 7) {
        Write-Host "🚨 URGENT: Certificate expires in $daysUntilExpiry days!" -ForegroundColor Red
        Write-Host "   Action Required: Update certificate pins NOW!" -ForegroundColor Red
        exit 1
    }
    elseif ($daysUntilExpiry -lt $alertDays) {
        Write-Host "⚠️  WARNING: Certificate expires in $daysUntilExpiry days" -ForegroundColor Yellow
        Write-Host "   Action Required: Plan certificate update soon" -ForegroundColor Yellow
        exit 0
    }
    else {
        Write-Host "✅ OK: Certificate is valid for $daysUntilExpiry days" -ForegroundColor Green
        exit 0
    }
    
    $sslStream.Close()
    $tcpClient.Close()
}
catch {
    Write-Host "❌ ERROR: Failed to check certificate" -ForegroundColor Red
    Write-Host "   $_"
    exit 1
}
