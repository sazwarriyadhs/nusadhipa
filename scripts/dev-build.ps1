$ErrorActionPreference = "Stop"

Set-Location "D:\NUSA-DHIPA-BUSINESS-OS"

Write-Host "Running gofmt..." -ForegroundColor Cyan
Get-ChildItem -Recurse -Filter *.go |
    Where-Object { $_.FullName -notmatch "\\vendor\\" } |
    ForEach-Object {
        gofmt -w $_.FullName
    }

Write-Host "Running go mod tidy..." -ForegroundColor Cyan
go mod tidy

Write-Host "Running go test..." -ForegroundColor Cyan
go test ./...

Write-Host "Building services..." -ForegroundColor Cyan

go build ./services/api_gateway/cmd/server
go build ./services/auth/cmd/server
go build ./services/tenant/cmd/server
go build ./services/business/cmd/server

Write-Host ""
Write-Host "BUILD PASSED" -ForegroundColor Green
