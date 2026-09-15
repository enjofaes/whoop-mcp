<#
  Tests MCP_CONNECTOR_PASSWORD directly against the server, with claude.ai
  taken out of the picture. Answers one question: does the deployed server
  accept this password?

  /authorize is rate limited to 3 requests per minute, so run this at most
  once a minute.

  Usage:  .\scripts\verify-connector.ps1 -Password 'abc123...'
#>

param(
  [Parameter(Mandatory = $true)][string] $Password,
  [string] $AppUrl = "https://whoop-mcp-enjofaes.fly.dev"
)

$body = @{
  connector_password    = $Password
  client_id             = "whoop-mcp-connector"
  response_type         = "code"
  redirect_uri          = "https://claude.ai/api/mcp/auth_callback"
  code_challenge        = "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM"
  code_challenge_method = "S256"
}

$code = 0; $content = ""
try {
  $r = Invoke-WebRequest -Uri "$AppUrl/authorize" -Method POST -Body $body `
        -ContentType "application/x-www-form-urlencoded" `
        -MaximumRedirection 0 -ErrorAction Stop
  $code = [int]$r.StatusCode; $content = $r.Content
} catch {
  if ($_.Exception.Response) {
    $code = [int]$_.Exception.Response.StatusCode
    try {
      $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
      $content = $sr.ReadToEnd()
    } catch { }
  } else {
    Write-Host "`n  Could not reach $AppUrl — $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
  }
}

Write-Host ""
if ($code -eq 401 -and $content -match "Incorrect password") {
  Write-Host "  WRONG PASSWORD" -ForegroundColor Red
  Write-Host "  The server rejected it. What is deployed differs from what you typed."
  Write-Host "  Reset it with .\scripts\new-connector-password.ps1, then re-run both workflows."
} elseif ($code -eq 429) {
  Write-Host "  RATE LIMITED" -ForegroundColor Yellow
  Write-Host "  /authorize allows 3 requests a minute, and a browser attempt costs 2."
  Write-Host "  This was never a password problem. Wait 60 seconds and try the connector again."
} elseif ($code -eq 401) {
  Write-Host "  401, but not the password page (HTTP $code)." -ForegroundColor Yellow
  Write-Host "  Check the app URL is right."
} else {
  Write-Host "  PASSWORD ACCEPTED (HTTP $code)" -ForegroundColor Green
  Write-Host "  The server took it and moved on to the OAuth step, so the password is"
  Write-Host "  correct and the problem is elsewhere in the claude.ai connector flow."
}
Write-Host ""
