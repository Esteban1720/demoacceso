$lines = Get-Content 'lib/screens/scan_screen.dart'
for ($i = 108; $i -le 232; $i++) {
    Write-Output ("{0,4}: {1}" -f $i, $lines[$i-1])
}