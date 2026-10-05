# ==========================================================
# NUSA DHIPA BUSINESS OS
# CATALOG + GATEWAY FULL INTEGRATION TEST
# ==========================================================

$ErrorActionPreference = "Continue"

$BaseUrl = "http://localhost:8300"
$CatalogUrl = "http://localhost:8304"
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

$TestPassword = "NusaDhipa-Test-2026!"

$Results = New-Object System.Collections.Generic.List[object]

$EmailA = "catalog.integration.a.$Timestamp@example.com"
$EmailB = "catalog.integration.b.$Timestamp@example.com"

$TenantAId = $null
$TenantBId = $null
$BusinessAId = $null
$BusinessBId = $null
$CategoryAId = $null
$ProductAId = $null

$TokenA = $null
$TokenB = $null


function Write-Step {
    param(
        [string]$Message
    )

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor DarkGray
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor DarkGray
}


function Add-Result {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Details
    )

    $status = if ($Passed) { "PASS" } else { "FAIL" }

    $Results.Add(
        [PSCustomObject]@{
            Test    = $Name
            Status  = $status
            Details = $Details
        }
    )

    if ($Passed) {
        Write-Host "[PASS] $Name" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Name :: $Details" -ForegroundColor Red
    }
}


function Invoke-JsonRequest {
    param(
        [string]$Method,
        [string]$Uri,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )

    try {
        $params = @{
            Method      = $Method
            Uri         = $Uri
            Headers     = $Headers
            ContentType = "application/json"
            ErrorAction = "Stop"
        }

        if ($null -ne $Body) {
            $params.Body = $Body | ConvertTo-Json -Depth 20 -Compress
        }

        $response = Invoke-WebRequest @params

        $json = $null

        if ($response.Content) {
            try {
                $json = $response.Content | ConvertFrom-Json
            }
            catch {
                $json = $null
            }
        }

        return [PSCustomObject]@{
            Status = [int]$response.StatusCode
            Body   = $response.Content
            Json   = $json
            Error  = $null
        }
    }
    catch {
        $status = 0
        $body = ""

        if ($_.Exception.Response) {
            try {
                $status = [int]$_.Exception.Response.StatusCode.value__

                $stream = $_.Exception.Response.GetResponseStream()

                if ($stream) {
                    $reader = New-Object System.IO.StreamReader($stream)
                    $body = $reader.ReadToEnd()
                    $reader.Dispose()
                }
            }
            catch {
            }
        }

        $json = $null

        if ($body) {
            try {
                $json = $body | ConvertFrom-Json
            }
            catch {
                $json = $null
            }
        }

        return [PSCustomObject]@{
            Status = $status
            Body   = $body
            Json   = $json
            Error  = $_.Exception.Message
        }
    }
}


function Get-PropertyValue {
    param(
        [object]$Object,
        [string[]]$Paths
    )

    foreach ($path in $Paths) {
        try {
            $value = $Object

            foreach ($part in ($path -split "\.")) {
                if ($null -eq $value) {
                    break
                }

                $value = $value.$part
            }

            if ($null -ne $value -and "$value" -ne "") {
                return $value
            }
        }
        catch {
        }
    }

    return $null
}


function Get-AccessToken {
    param(
        [object]$Json
    )

    return Get-PropertyValue $Json @(
        "data.data.tokens.access_token",
        "data.tokens.access_token",
        "data.access_token",
        "access_token"
    )
}


function Get-EntityId {
    param(
        [object]$Json
    )

    return Get-PropertyValue $Json @(
        "data.product.id",
        "data.category.id",
        "data.business.id",
        "data.tenant.id",
        "product.id",
        "category.id",
        "business.id",
        "tenant.id",
        "data.id",
        "data.data.id",
        "id"
    )
}


# ==========================================================
# 1. GATEWAY HEALTH
# ==========================================================

Write-Step "1. GATEWAY HEALTH"

$r = Invoke-JsonRequest `
    -Method "GET" `
    -Uri "$BaseUrl/health"

Add-Result `
    -Name "Gateway health" `
    -Passed ($r.Status -eq 200) `
    -Details ("HTTP {0}" -f $r.Status)


# ==========================================================
# 2. CATALOG HEALTH
# ==========================================================

Write-Step "2. CATALOG HEALTH"

$r = Invoke-JsonRequest `
    -Method "GET" `
    -Uri "$CatalogUrl/health"

Add-Result `
    -Name "Catalog health" `
    -Passed ($r.Status -eq 200) `
    -Details ("HTTP {0}" -f $r.Status)


# ==========================================================
# 3. CATALOG AUTH
# ==========================================================

Write-Step "3. CATALOG AUTHORIZATION"

$r = Invoke-JsonRequest `
    -Method "GET" `
    -Uri "$BaseUrl/api/v1/catalog/products?business_id=test"

Add-Result `
    -Name "Catalog rejects missing JWT" `
    -Passed ($r.Status -eq 401) `
    -Details ("Expected 401, received HTTP {0}" -f $r.Status)


# ==========================================================
# 4. REGISTER TENANT A
# ==========================================================

Write-Step "4. REGISTER TENANT A"

$registerA = @{
    name          = "Catalog Integration User A"
    email         = $EmailA
    password      = $TestPassword
    tenant_name   = "Catalog Integration Tenant A $Timestamp"
    business_name = "Catalog Integration Business A $Timestamp"
}

$r = Invoke-JsonRequest `
    -Method "POST" `
    -Uri "$BaseUrl/api/v1/auth/register" `
    -Body $registerA

Add-Result `
    -Name "Register Tenant A" `
    -Passed ($r.Status -ge 200 -and $r.Status -lt 300) `
    -Details ("HTTP {0}" -f $r.Status)


# ==========================================================
# 5. LOGIN TENANT A
# ==========================================================

Write-Step "5. LOGIN TENANT A"

$r = Invoke-JsonRequest `
    -Method "POST" `
    -Uri "$BaseUrl/api/v1/auth/login" `
    -Body @{
        email = $EmailA
        password = $TestPassword
    }

$TokenA = Get-AccessToken $r.Json

$TenantAId = Get-PropertyValue $r.Json @(
    "data.data.tenant.id",
    "data.tenant.id",
    "tenant.id"
)

$BusinessAId = Get-PropertyValue $r.Json @(
    "data.data.business.id",
    "data.business.id",
    "business.id"
)

Add-Result `
    -Name "Login Tenant A" `
    -Passed ($r.Status -eq 200 -and $TokenA) `
    -Details ("HTTP {0}; authenticated={1}" -f $r.Status, [bool]$TokenA)

Add-Result `
    -Name "Tenant A context available" `
    -Passed ([bool]$TenantAId) `
    -Details ("Tenant resolved={0}" -f [bool]$TenantAId)

Add-Result `
    -Name "Business A context available" `
    -Passed ([bool]$BusinessAId) `
    -Details ("Business resolved={0}" -f [bool]$BusinessAId)


# ==========================================================
# 6. CREATE BUSINESS A FALLBACK
# ==========================================================

if (-not $BusinessAId -and $TokenA) {

    Write-Step "6. CREATE BUSINESS A"

    $headersA = @{
        Authorization = "Bearer $TokenA"
    }

    $r = Invoke-JsonRequest `
        -Method "POST" `
        -Uri "$BaseUrl/api/v1/businesses" `
        -Headers $headersA `
        -Body @{
            name = "Catalog Integration Business A $Timestamp"
            type = "retail"
            slug = "catalog-business-a-$Timestamp"
        }

    $BusinessAId = Get-EntityId $r.Json

    Add-Result `
        -Name "Create Business A" `
        -Passed ($r.Status -ge 200 -and $r.Status -lt 300 -and $BusinessAId) `
        -Details ("HTTP {0}; business resolved={1}" -f $r.Status, [bool]$BusinessAId)
}


# ==========================================================
# 7. CREATE CATEGORY
# ==========================================================

if ($TokenA -and $BusinessAId) {

    Write-Step "7. CREATE CATEGORY A"

    $headersA = @{
        Authorization = "Bearer $TokenA"
    }

    $r = Invoke-JsonRequest `
        -Method "POST" `
        -Uri "$BaseUrl/api/v1/catalog/categories?business_id=$BusinessAId" `
        -Headers $headersA `
        -Body @{
            name = "Integration Category $Timestamp"
            description = "Automated Catalog Integration Test"
        }

    $CategoryAId = Get-EntityId $r.Json

    Add-Result `
        -Name "Create Category A" `
        -Passed ($r.Status -ge 200 -and $r.Status -lt 300 -and $CategoryAId) `
        -Details ("HTTP {0}; category resolved={1}" -f $r.Status, [bool]$CategoryAId)
}
else {

    Add-Result `
        -Name "Create Category A" `
        -Passed $false `
        -Details "Missing Tenant A token or Business A ID"
}


# ==========================================================
# 8. CREATE PRODUCT
# ==========================================================

if ($TokenA -and $BusinessAId) {

    Write-Step "8. CREATE PRODUCT A"

    $headersA = @{
        Authorization = "Bearer $TokenA"
    }

    $r = Invoke-JsonRequest `
        -Method "POST" `
        -Uri "$BaseUrl/api/v1/catalog/products?business_id=$BusinessAId" `
        -Headers $headersA `
        -Body @{
            category_id = $CategoryAId
            sku = "CAT-INT-$Timestamp"
            name = "Integration Product $Timestamp"
            description = "Automated Catalog Integration Product"
            product_type = "product"
            unit = "pcs"
            price = 125000
            cost_price = 85000
            track_inventory = $true
        }

    Write-Host ""
Write-Host "=== CREATE PRODUCT RAW RESPONSE ===" -ForegroundColor Yellow
Write-Host "HTTP Status : $($r.Status)"
Write-Host "BusinessAId : [$BusinessAId]"
Write-Host "CategoryAId : [$CategoryAId]"
Write-Host "Raw Body:"
Write-Host $r.Body

Write-Host ""
Write-Host "=== CREATE PRODUCT JSON ===" -ForegroundColor Yellow

if ($null -ne $r.Json) {
    $r.Json | ConvertTo-Json -Depth 20
}
else {
    Write-Host "<JSON NULL>"
}

$ProductAId = Get-EntityId $r.Json

Write-Host ""
Write-Host "=== RESOLVED PRODUCT ID ===" -ForegroundColor Yellow
Write-Host "ProductAId : [$ProductAId]"
Write-Host "Length     : $($ProductAId.Length)"

if ($ProductAId) {
    Write-Host "UUID valid : $([bool]("$ProductAId" -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'))"
}
else {
    Write-Host "UUID valid : False"
}

    Add-Result `
        -Name "Create Product A" `
        -Passed ($r.Status -ge 200 -and $r.Status -lt 300 -and $ProductAId) `
        -Details ("HTTP {0}; product resolved={1}" -f $r.Status, [bool]$ProductAId)
}
else {

    Add-Result `
        -Name "Create Product A" `
        -Passed $false `
        -Details "Missing authentication or Business A ID"
}


# ==========================================================
# 9. GET PRODUCT
# ==========================================================

if ($TokenA -and $BusinessAId -and $ProductAId) {

    Write-Step "9. GET PRODUCT A"

    $headersA = @{
        Authorization = "Bearer $TokenA"
    }

    $r = Invoke-JsonRequest `
        -Method "GET" `
        -Uri "$BaseUrl/api/v1/catalog/products/${ProductAId}?business_id=${BusinessAId}" `
        -Headers $headersA

    Add-Result `
        -Name "GET Product A" `
        -Passed ($r.Status -eq 200) `
        -Details ("HTTP {0}" -f $r.Status)
}
else {

    Add-Result `
        -Name "GET Product A" `
        -Passed $false `
        -Details "Missing product context"
}


# ==========================================================
# 10. UPDATE PRODUCT
# ==========================================================

if ($TokenA -and $BusinessAId -and $ProductAId) {

    Write-Step "10. UPDATE PRODUCT A"

    $headersA = @{
        Authorization = "Bearer $TokenA"
    }

    $r = Invoke-JsonRequest `
        -Method "PUT" `
        -Uri "$BaseUrl/api/v1/catalog/products/${ProductAId}?business_id=${BusinessAId}" `
        -Headers $headersA `
        -Body @{
            category_id = $CategoryAId
            sku = "CAT-INT-$Timestamp"
            name = "Integration Product Updated $Timestamp"
            description = "Updated by automated integration test"
            product_type = "product"
            unit = "pcs"
            price = 135000
            cost_price = 90000
            track_inventory = $true
        }

    Add-Result `
        -Name "UPDATE Product A" `
        -Passed ($r.Status -ge 200 -and $r.Status -lt 300) `
        -Details ("HTTP {0}" -f $r.Status)
}
else {

    Add-Result `
        -Name "UPDATE Product A" `
        -Passed $false `
        -Details "Missing product context"
}


# ==========================================================
# 11. ARCHIVE PRODUCT
# ==========================================================

if ($TokenA -and $BusinessAId -and $ProductAId) {

    Write-Step "11. ARCHIVE PRODUCT A"

    $headersA = @{
        Authorization = "Bearer $TokenA"
    }

    $r = Invoke-JsonRequest `
        -Method "DELETE" `
        -Uri "$BaseUrl/api/v1/catalog/products/${ProductAId}?business_id=${BusinessAId}" `
        -Headers $headersA

    Add-Result `
        -Name "ARCHIVE Product A" `
        -Passed ($r.Status -ge 200 -and $r.Status -lt 300) `
        -Details ("HTTP {0}" -f $r.Status)
}
else {

    Add-Result `
        -Name "ARCHIVE Product A" `
        -Passed $false `
        -Details "Missing product context"
}


# ==========================================================
# 12. REGISTER TENANT B
# ==========================================================

Write-Step "12. REGISTER TENANT B"

$registerB = @{
    name          = "Catalog Integration User B"
    email         = $EmailB
    password      = $TestPassword
    tenant_name   = "Catalog Integration Tenant B $Timestamp"
    business_name = "Catalog Integration Business B $Timestamp"
}

$r = Invoke-JsonRequest `
    -Method "POST" `
    -Uri "$BaseUrl/api/v1/auth/register" `
    -Body $registerB

Add-Result `
    -Name "Register Tenant B" `
    -Passed ($r.Status -ge 200 -and $r.Status -lt 300) `
    -Details ("HTTP {0}" -f $r.Status)


# ==========================================================
# 13. LOGIN TENANT B
# ==========================================================

Write-Step "13. LOGIN TENANT B"

$r = Invoke-JsonRequest `
    -Method "POST" `
    -Uri "$BaseUrl/api/v1/auth/login" `
    -Body @{
        email = $EmailB
        password = $TestPassword
    }

$TokenB = Get-AccessToken $r.Json

$TenantBId = Get-PropertyValue $r.Json @(
    "data.data.tenant.id",
    "data.tenant.id",
    "tenant.id"
)

$BusinessBId = Get-PropertyValue $r.Json @(
    "data.data.business.id",
    "data.business.id",
    "business.id"
)

Add-Result `
    -Name "Login Tenant B" `
    -Passed ($r.Status -eq 200 -and $TokenB) `
    -Details ("HTTP {0}; authenticated={1}" -f $r.Status, [bool]$TokenB)

Add-Result `
    -Name "Tenant B context available" `
    -Passed ([bool]$TenantBId) `
    -Details ("Tenant resolved={0}" -f [bool]$TenantBId)

Add-Result `
    -Name "Business B context available" `
    -Passed ([bool]$BusinessBId) `
    -Details ("Business resolved={0}" -f [bool]$BusinessBId)


# ==========================================================
# 14. CROSS TENANT GET
# ==========================================================

if ($TokenB -and $BusinessAId -and $ProductAId) {

    Write-Step "14. CROSS-TENANT GET PROTECTION"

    $headersB = @{
        Authorization = "Bearer $TokenB"
    }

    $r = Invoke-JsonRequest `
        -Method "GET" `
        -Uri "$BaseUrl/api/v1/catalog/products/${ProductAId}?business_id=${BusinessAId}" `
        -Headers $headersB

    Add-Result `
        -Name "Tenant B cannot GET Tenant A Product" `
        -Passed ($r.Status -eq 404) `
        -Details ("Expected 404, received HTTP {0}" -f $r.Status)
}
else {

    Add-Result `
        -Name "Tenant B cannot GET Tenant A Product" `
        -Passed $false `
        -Details "Missing cross-tenant context"
}


# ==========================================================
# 15. CROSS TENANT UPDATE
# ==========================================================

if ($TokenB -and $BusinessAId -and $ProductAId) {

    Write-Step "15. CROSS-TENANT UPDATE PROTECTION"

    $headersB = @{
        Authorization = "Bearer $TokenB"
    }

    $r = Invoke-JsonRequest `
        -Method "PUT" `
        -Uri "$BaseUrl/api/v1/catalog/products/${ProductAId}?business_id=${BusinessAId}" `
        -Headers $headersB `
        -Body @{
            category_id = $null
            sku = "ATTACK-$Timestamp"
            name = "Unauthorized Update"
            description = "Must never persist"
            product_type = "product"
            unit = "pcs"
            price = 1
            cost_price = 1
            track_inventory = $true
        }

    Add-Result `
        -Name "Tenant B cannot UPDATE Tenant A Product" `
        -Passed ($r.Status -eq 404) `
        -Details ("Expected 404, received HTTP {0}" -f $r.Status)
}
else {

    Add-Result `
        -Name "Tenant B cannot UPDATE Tenant A Product" `
        -Passed $false `
        -Details "Missing cross-tenant context"
}


# ==========================================================
# 16. CROSS TENANT ARCHIVE
# ==========================================================

if ($TokenB -and $BusinessAId -and $ProductAId) {

    Write-Step "16. CROSS-TENANT ARCHIVE PROTECTION"

    $headersB = @{
        Authorization = "Bearer $TokenB"
    }

    $r = Invoke-JsonRequest `
        -Method "DELETE" `
        -Uri "$BaseUrl/api/v1/catalog/products/${ProductAId}?business_id=${BusinessAId}" `
        -Headers $headersB

    Add-Result `
        -Name "Tenant B cannot ARCHIVE Tenant A Product" `
        -Passed ($r.Status -eq 404) `
        -Details ("Expected 404, received HTTP {0}" -f $r.Status)
}
else {

    Add-Result `
        -Name "Tenant B cannot ARCHIVE Tenant A Product" `
        -Passed $false `
        -Details "Missing cross-tenant context"
}


# ==========================================================
# ==========================================================
# CLEANUP TEST DATA
# ==========================================================

Write-Step "CLEANUP TEST DATA"

$CleanupTenantIds = @(
    $TenantAId,
    $TenantBId
) |
    Where-Object {
        $_ -and $_.ToString().Trim() -ne ""
    } |
    Select-Object -Unique

if ($CleanupTenantIds.Count -gt 0) {

    Write-Host "[INFO] Cleaning test tenants..." -ForegroundColor Cyan

    foreach ($cleanupTenantId in $CleanupTenantIds) {

        $cleanupSql = @"
DELETE FROM tenants
WHERE id = '$cleanupTenantId';
"@

        $cleanupResult = $cleanupSql |
            docker exec -i nusa-dhipa-postgres `
                psql -U nusa_dhipa -d nusa_dhipa `
                -P pager=off 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[PASS] Cleaned tenant $cleanupTenantId" -ForegroundColor Green
        }
        else {
            Write-Host "[FAIL] Failed to clean tenant $cleanupTenantId" -ForegroundColor Red
            Write-Host $cleanupResult
        }
    }
}
else {
    Write-Host "[INFO] No test tenants available for cleanup." -ForegroundColor DarkGray
}
# FINAL SUMMARY
# ==========================================================

Write-Step "FINAL TEST SUMMARY"

$passed = @($Results | Where-Object { $_.Status -eq "PASS" }).Count
$failed = @($Results | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $Results.Count

$Results | Format-Table -AutoSize

Write-Host ""
Write-Host "==========================================================" -ForegroundColor DarkGray
Write-Host " TOTAL : $total"
Write-Host " PASS  : $passed" -ForegroundColor Green

if ($failed -eq 0) {
    Write-Host " FAIL  : $failed" -ForegroundColor Green
}
else {
    Write-Host " FAIL  : $failed" -ForegroundColor Red
}

Write-Host "==========================================================" -ForegroundColor DarkGray

Write-Host ""
Write-Host "=== SAFE TEST CONTEXT ===" -ForegroundColor Cyan
Write-Host ("Tenant A   : {0}" -f [bool]$TenantAId)
Write-Host ("Business A : {0}" -f [bool]$BusinessAId)
Write-Host ("Category A : {0}" -f [bool]$CategoryAId)
Write-Host ("Product A  : {0}" -f [bool]$ProductAId)
Write-Host ("Tenant B   : {0}" -f [bool]$TenantBId)
Write-Host ("Business B : {0}" -f [bool]$BusinessBId)

Write-Host ""
Write-Host "[INFO] JWT tokens and passwords are intentionally not printed." -ForegroundColor DarkGray






