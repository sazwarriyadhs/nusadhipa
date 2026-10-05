$ErrorActionPreference = "Continue"

Set-Location "D:\NUSA-DHIPA-BUSINESS-OS"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " NUSA DHIPA PHASE 2 VERIFICATION" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== DOCKER ===" -ForegroundColor Yellow
docker compose ps

Write-Host ""
Write-Host "=== DATABASE ===" -ForegroundColor Yellow
docker exec nusa-dhipa-postgres pg_isready -U nusa_dhipa -d nusa_dhipa

Write-Host ""
Write-Host "=== REDIS ===" -ForegroundColor Yellow
docker exec nusa-dhipa-redis redis-cli ping

Write-Host ""
Write-Host "=== HOST PORTS ===" -ForegroundColor Yellow

$ports = @(8300,8301,8302,8303,15440,16390)

foreach ($port in $ports) {

    $conn = Get-NetTCPConnection `
        -LocalPort $port `
        -State Listen `
        -ErrorAction SilentlyContinue

    if ($conn) {
        Write-Host "PORT $port : IN USE" -ForegroundColor Green
    }
    else {
        Write-Host "PORT $port : FREE" -ForegroundColor DarkYellow
    }
}

Write-Host ""
Write-Host "=== HTTP ===" -ForegroundColor Yellow

$urls = @(
    "http://localhost:8300/health",
    "http://localhost:8301/health",
    "http://localhost:8302/health",
    "http://localhost:8303/health"
)

foreach ($url in $urls) {

    try {
        $response = Invoke-RestMethod `
            -Uri $url `
            -Method GET `
            -TimeoutSec 10

        Write-Host "$url : OK" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 10
    }
    catch {
        Write-Host "$url : FAILED" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
    }
}

Write-Host ""
Write-Host "=== GO TEST ===" -ForegroundColor Yellow
go test ./...

Write-Host ""
Write-Host "VERIFICATION COMPLETE" -ForegroundColor Green
