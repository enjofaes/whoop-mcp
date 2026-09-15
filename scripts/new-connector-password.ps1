<#
  Generates a new MCP_CONNECTOR_PASSWORD and puts it on your clipboard.

  Hex only — no +, / or = — so there is nothing to mis-copy or lose off the
  end. 32 characters, 128 bits of entropy, comfortably over the server's
  12-character minimum.
#>

$rng   = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$bytes = New-Object byte[] 16
$rng.GetBytes($bytes)
$pw = ($bytes | ForEach-Object { $_.ToString('x2') }) -join ''

try { Set-Clipboard -Value $pw; $clip = "Copied to clipboard." }
catch { $clip = "Could not reach the clipboard — copy it by hand." }

Write-Host ""
Write-Host "  MCP_CONNECTOR_PASSWORD" -ForegroundColor Cyan
Write-Host "  $pw"                     -ForegroundColor Green
Write-Host ""
Write-Host "  $($pw.Length) characters. $clip" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Next:" -ForegroundColor Yellow
Write-Host "   1. Save it in your password manager. You cannot read it back later."
Write-Host "   2. GitHub -> Settings -> Secrets and variables -> Actions"
Write-Host "      Edit MCP_CONNECTOR_PASSWORD, paste, save."
Write-Host "   3. Actions -> 'Fly bootstrap (one time)' -> Run workflow"
Write-Host "      app: whoop-mcp-enjofaes   region: ams"
Write-Host "   4. Actions -> 'Fly deploy' -> Run workflow"
Write-Host "   5. Verify with:  .\scripts\verify-connector.ps1 -Password '$pw'"
Write-Host ""
Write-Host "  Do not touch the other secrets. WHOOP_REFRESH_TOKEN in particular" -ForegroundColor DarkGray
Write-Host "  has rotated since you set it; overwriting it would break a working server." -ForegroundColor DarkGray
Write-Host ""
