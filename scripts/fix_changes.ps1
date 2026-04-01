# Fix 1: booking_date_time_sheet.dart - button text
$file1 = "lib\widgets\booking_date_time_sheet.dart"
$content = [System.IO.File]::ReadAllText($file1, [System.Text.Encoding]::UTF8)
$old1 = "                child: Text(`r`n                  _selectedTimeSlot != null`r`n                      ? 'Konfirmasi  `$_selectedTimeSlot'`r`n                          '`${_selectedDays > 1 ? `"  (`$_selectedDays Hari)`" : `"`"}'`r`n                      : 'Pilih jam terlebih dahulu',"
$new1 = "                child: Text(`r`n                  _selectedTimeSlot != null`r`n                      ? _selectedDays > 1`r`n                          ? 'Konfirmasi Booking `$_selectedDays Hari'`r`n                          : 'Konfirmasi  `$_selectedTimeSlot'`r`n                      : 'Pilih jam terlebih dahulu',"
if ($content -match [regex]::Escape("'Konfirmasi  `$_selectedTimeSlot'")) {
    $content = $content -replace [regex]::Escape("? 'Konfirmasi  `$_selectedTimeSlot'`r`n                          '`${_selectedDays > 1 ? `"  (`$_selectedDays Hari)`" : `"`"}'"), "? _selectedDays > 1`r`n                          ? 'Konfirmasi Booking `$_selectedDays Hari'`r`n                          : 'Konfirmasi  `$_selectedTimeSlot'"
    [System.IO.File]::WriteAllText($file1, $content, [System.Text.Encoding]::UTF8)
    Write-Host "Fix1: OK"
} else {
    Write-Host "Fix1: Pattern not found, trying LF"
    $old1lf = "                child: Text(`n                  _selectedTimeSlot != null`n                      ? 'Konfirmasi  `$_selectedTimeSlot'`n                          '`${_selectedDays > 1 ? `"  (`$_selectedDays Hari)`" : `"`"}'`n                      : 'Pilih jam terlebih dahulu',"
    $new1lf = "                child: Text(`n                  _selectedTimeSlot != null`n                      ? _selectedDays > 1`n                          ? 'Konfirmasi Booking `$_selectedDays Hari'`n                          : 'Konfirmasi  `$_selectedTimeSlot'`n                      : 'Pilih jam terlebih dahulu',"
    if ($content.Contains("'Konfirmasi  `$_selectedTimeSlot'")) {
        $escaped = [regex]::Escape("? 'Konfirmasi  `$_selectedTimeSlot'")
        $content = $content -replace ($escaped + ".*?'Pilih jam terlebih dahulu',"), "? _selectedDays > 1`n                          ? 'Konfirmasi Booking `$_selectedDays Hari'`n                          : 'Konfirmasi  `$_selectedTimeSlot'`n                      : 'Pilih jam terlebih dahulu',"
        [System.IO.File]::WriteAllText($file1, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fix1: OK (LF)"
    } else {
        Write-Host "Fix1: SKIP"
    }
}

# Fix 2: booking_confirmation_screen.dart - single booking + price summary
$file2 = "lib\screens\user\booking_confirmation_screen.dart"
$content2 = [System.IO.File]::ReadAllText($file2, [System.Text.Encoding]::UTF8)

# Fix price summary: hide "Durasi Sesi" row for multi-day
$oldPriceSesi = "_buildPriceRow(`r`n            'Durasi Sesi',"
$newPriceSesi = "if (_durationDays == 1) ...[`r`n            _buildPriceRow(`r`n              'Durasi Sesi',"
if ($content2.Contains("_buildPriceRow(`r`n            'Durasi Sesi',")) {
    Write-Host "Fix2a: CRLF found"
} elseif ($content2.Contains("_buildPriceRow(`n            'Durasi Sesi',")) {
    Write-Host "Fix2a: LF found"
} else {
    Write-Host "Fix2a: checking..."
    if ($content2 -match "'Durasi Sesi'") { Write-Host "  Durasi Sesi exists" } else { Write-Host "  NOT found" }
}

Write-Host "Done"
