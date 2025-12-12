$lines = Get-Content 'lib/screens/scan_screen.dart'
$stack = @()
for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    for ($j=0; $j -lt $line.Length; $j++) {
        $ch = $line[$j]
        if ($ch -eq '{') { $stack += ($i+1) }
        elseif ($ch -eq '}') {
            if ($stack.Count -gt 0) { $stack = $stack[0..($stack.Count-2)] } else { Write-Output "Unmatched closing brace at line $($i+1): $line"; exit }
        }
    }
}
if ($stack.Count -gt 0) {
    Write-Output "Unmatched opening brace(s) at lines: $($stack -join ', ')"
    Write-Output "Full stack length: $($stack.Count)"
    $toShow = 5
    if ($stack.Count -lt 5) { $toShow = $stack.Count }
    for ($idx = $stack.Count - $toShow; $idx -le $stack.Count -1; $idx++) {
        $ln = $stack[$idx]
        $start=[int]($ln-3)
        if ($start -lt 0) { $start = 0 }
        Write-Output "Context near line ${ln}:"
        $end = [int]($ln+3)
        for ($k=$start; $k -le $end -and $k -lt $lines.Count; $k++) {
            Write-Output ("{0,4}: {1}" -f ($k+1), $lines[$k])
        }
    }
} else { Write-Output "All braces matched" }
