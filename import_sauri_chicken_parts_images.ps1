param(
    [string]$ZipPath = "$env:USERPROFILE\Downloads\Chicken_Parts_18_Individual_Crops.zip",
    [string]$ProjectRoot = "D:\NUSA-DHIPA-BUSINESS-OS",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# ============================================================
# CONFIG
# ============================================================

$container = "nusa-dhipa-postgres"
$db = "nusa_dhipa"
$dbUser = "nusa_dhipa"

$businessName = "FRESH MARKET UNGGAS & ANIMAL PETFOOD INDONESIA"
$legalName = "PT SAURI UNGGUL SEJAHTERA"

$businessIdExpected = "2c432df3-cd1a-420f-90cb-9b705abff26c"

# Product defaults.
# Harga TIDAK DIKARANGI.
$defaultPrice = 0
$defaultCostPrice = 0
$defaultUnit = "kg"
$defaultProductType = "product"
$defaultStatus = "active"

# ============================================================
# FUNCTIONS
# ============================================================

function SqlEscape {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return $Value.Replace("'", "''")
}

function Norm {
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    $x = $Value.ToUpperInvariant()
    $x = $x -replace '[^A-Z0-9]+', ' '
    $x = $x.Trim()
    $x = $x -replace '\s+', ' '

    return $x
}

function Exec-Psql {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Sql
    )

    $encoded = [Convert]::ToBase64String(
        [Text.Encoding]::UTF8.GetBytes($Sql)
    )

    $cmd = "echo $encoded | base64 -d | psql -U $dbUser -d $db -t -A"

    $result = docker exec $container sh -lc $cmd

    if ($LASTEXITCODE -ne 0) {
        throw "psql query gagal."
    }

    return $result
}

function Invoke-Sql {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Sql
    )

    $encoded = [Convert]::ToBase64String(
        [Text.Encoding]::UTF8.GetBytes($Sql)
    )

    $cmd = "echo $encoded | base64 -d | psql -U $dbUser -d $db"

    $result = docker exec $container sh -lc $cmd

    if ($LASTEXITCODE -ne 0) {
        throw "psql command gagal."
    }

    return $result
}

# ============================================================
# HEADER
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " NUSA-DHIPA / SAURI CHICKEN PARTS PRODUCT IMPORT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($Apply) {
    Write-Host "Mode       : APPLY" -ForegroundColor Yellow
}
else {
    Write-Host "Mode       : DRY-RUN" -ForegroundColor Green
}

Write-Host "Project    : $ProjectRoot"
Write-Host "ZIP        : $ZipPath"
Write-Host "Business   : $businessName"
Write-Host ""

# ============================================================
# 1. VALIDATE PROJECT
# ============================================================

Write-Host "[1/10] Validating environment..." -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "ProjectRoot tidak ditemukan: $ProjectRoot"
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "ZIP tidak ditemukan: $ZipPath"
}

docker inspect $container *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Container PostgreSQL '$container' tidak ditemukan."
}

$running = docker inspect -f "{{.State.Running}}" $container 2>$null

if ($running -ne "true") {
    throw "Container PostgreSQL '$container' tidak running."
}

Write-Host "      Environment OK." -ForegroundColor Green

# ============================================================
# 2. EXTRACT ZIP
# ============================================================

Write-Host "[2/10] Extracting 18 chicken-part images..." -ForegroundColor Cyan

$work = Join-Path `
    $env:TEMP `
    ("nusa-dhipa-sauri-chicken-" + [guid]::NewGuid().ToString("N"))

New-Item `
    -ItemType Directory `
    -Path $work `
    -Force | Out-Null

Expand-Archive `
    -LiteralPath $ZipPath `
    -DestinationPath $work `
    -Force

$files = @(
    Get-ChildItem `
        -LiteralPath $work `
        -File `
        -Recurse |
    Where-Object {
        $_.Extension -match '^\.(jpg|jpeg|png)$'
    } |
    Sort-Object Name
)

Write-Host "      Image files found : $($files.Count)"

if ($files.Count -ne 18) {
    Write-Host ""
    $files | ForEach-Object {
        Write-Host " - $($_.Name)"
    }

    throw "Expected exactly 18 images, ditemukan $($files.Count)."
}

# ============================================================
# 3. CANONICAL PRODUCT MAP
# ============================================================

$map = @(
    @{
        File = "BLD_Boneless_Dada.jpg"
        SKU = "BLD"
        Name = "Boneless Dada"
        Description = "Processed chicken breast boneless."
        Aliases = @("BLD", "BONeLESS DADA", "BONELESS DADA")
    },
    @{
        File = "BLP_Boneless_Paha.jpg"
        SKU = "BLP"
        Name = "Boneless Paha"
        Description = "Processed chicken thigh boneless."
        Aliases = @("BLP", "BONELESS PAHA")
    },
    @{
        File = "Paha_Pentung.jpg"
        SKU = "PAHA-PENTUNG"
        Name = "Paha Pentung"
        Description = "Chicken drumstick / paha pentung."
        Aliases = @("PAHA PENTUNG")
    },
    @{
        File = "Sayap_R.jpg"
        SKU = "SAYAP-R"
        Name = "Sayap R"
        Description = "Processed chicken wing R."
        Aliases = @("SAYAP R")
    },
    @{
        File = "Sayap_BN.jpg"
        SKU = "SAYAP-BN"
        Name = "Sayap BN"
        Description = "Processed chicken wing BN."
        Aliases = @("SAYAP BN")
    },
    @{
        File = "Kepala_BN.jpg"
        SKU = "KEPALA-BN"
        Name = "Kepala BN"
        Description = "Processed chicken head BN."
        Aliases = @("KEPALA BN")
    },
    @{
        File = "Kepala_PT.jpg"
        SKU = "KEPALA-PT"
        Name = "Kepala PT"
        Description = "Processed chicken head PT."
        Aliases = @("KEPALA PT")
    },
    @{
        File = "Ceker_BN.jpg"
        SKU = "CEKER-BN"
        Name = "Ceker BN"
        Description = "Processed chicken feet BN."
        Aliases = @("CEKER BN")
    },
    @{
        File = "Ceker_Kuning.jpg"
        SKU = "CEKER-KUNING"
        Name = "Ceker Kuning"
        Description = "Processed yellow chicken feet."
        Aliases = @("CEKER KUNING")
    },
    @{
        File = "Kulit_Body.jpg"
        SKU = "KULIT-BODY"
        Name = "Kulit Body"
        Description = "Processed chicken skin."
        Aliases = @("KULIT BODY")
    },
    @{
        File = "Krongkong_PT.jpg"
        SKU = "KRONGKONG-PT"
        Name = "Krongkong PT"
        Description = "Processed chicken krongkong."
        Aliases = @("KRONGKONG PT")
    },
    @{
        File = "Jantung_Bersih.jpg"
        SKU = "JANTUNG-BERSIH"
        Name = "Jantung Bersih"
        Description = "Cleaned chicken heart."
        Aliases = @("JANTUNG BERSIH")
    },
    @{
        File = "Ampela_Bersih.jpg"
        SKU = "AMPELA-BERSIH"
        Name = "Ampela Bersih"
        Description = "Cleaned chicken gizzard."
        Aliases = @("AMPELA BERSIH")
    },
    @{
        File = "Ampela_Kotor.jpg"
        SKU = "AMPELA-KOTOR"
        Name = "Ampela Kotor"
        Description = "Uncleaned chicken gizzard."
        Aliases = @("AMPELA KOTOR")
    },
    @{
        File = "Hati_Bersih.jpg"
        SKU = "HATI-BERSIH"
        Name = "Hati Bersih"
        Description = "Cleaned chicken liver."
        Aliases = @("HATI BERSIH")
    },
    @{
        File = "Usus.jpg"
        SKU = "USUS"
        Name = "Usus"
        Description = "Processed chicken intestine."
        Aliases = @("USUS")
    },
    @{
        File = "Tulang_Paha.jpg"
        SKU = "TULANG-PAHA"
        Name = "Tulang Paha"
        Description = "Chicken thigh bone."
        Aliases = @("TULANG PAHA")
    },
    @{
        File = "Tunggir.jpg"
        SKU = "TUNGGIR"
        Name = "Tunggir"
        Description = "Processed chicken tail / tunggir."
        Aliases = @("TUNGGIR")
    }
)

# ============================================================
# 4. VALIDATE FILE NAMES
# ============================================================

Write-Host "[3/10] Validating canonical image set..." -ForegroundColor Cyan

$actualNames = @(
    $files |
    ForEach-Object { $_.Name }
)

$expectedNames = @(
    $map |
    ForEach-Object { $_.File }
)

$missing = @(
    $expectedNames |
    Where-Object { $_ -notin $actualNames }
)

$unexpected = @(
    $actualNames |
    Where-Object { $_ -notin $expectedNames }
)

if ($missing.Count -gt 0) {

    Write-Host "Missing:" -ForegroundColor Red

    $missing | ForEach-Object {
        Write-Host " - $_"
    }

    throw "Canonical image tidak lengkap."
}

if ($unexpected.Count -gt 0) {

    Write-Host "Unexpected:" -ForegroundColor Yellow

    $unexpected | ForEach-Object {
        Write-Host " - $_"
    }

    throw "ZIP berisi image di luar mapping."
}

Write-Host "      18/18 canonical images OK." -ForegroundColor Green

# ============================================================
# 5. FIND BUSINESS + TENANT
# ============================================================

Write-Host "[4/10] Resolving Business + Tenant..." -ForegroundColor Cyan

$businessSql = SqlEscape $businessName
$legalSql = SqlEscape $legalName

$businessRaw = Exec-Psql @"
SELECT
    b.id::text
    || E'\t'
    || b.tenant_id::text
    || E'\t'
    || b.name
FROM businesses b
WHERE lower(trim(b.name)) = lower(trim('$businessSql'))
   OR lower(trim(b.name)) = lower(trim('$legalSql'))
ORDER BY
    CASE
        WHEN lower(trim(b.name)) = lower(trim('$businessSql'))
        THEN 0
        ELSE 1
    END
LIMIT 1;
"@

$businessParts = $businessRaw.Trim() -split "`t", 3

if ($businessParts.Count -ne 3) {
    throw "Business Sauri tidak ditemukan atau tenant_id tidak tersedia."
}

$businessId = $businessParts[0]
$tenantId = $businessParts[1]
$resolvedBusinessName = $businessParts[2]

if ($businessId -ne $businessIdExpected) {
    Write-Host ""
    Write-Host "WARNING: Business ID berbeda dari expected ID." -ForegroundColor Yellow
    Write-Host "Expected : $businessIdExpected"
    Write-Host "Actual   : $businessId"
    Write-Host ""
}

Write-Host "      Business ID : $businessId"
Write-Host "      Tenant ID   : $tenantId"
Write-Host "      Name        : $resolvedBusinessName"

# ============================================================
# 6. CHECK EXISTING PRODUCTS
# ============================================================

Write-Host "[5/10] Checking existing Sauri Product Master..." -ForegroundColor Cyan

$existingRaw = Exec-Psql @"
SELECT
    sku
    || E'\t'
    || id::text
    || E'\t'
    || name
FROM catalog_products
WHERE business_id = '$businessId'
ORDER BY sku;
"@

$existing = @()

foreach ($line in ($existingRaw -split "`r?`n")) {

    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    $p = $line -split "`t", 3

    if ($p.Count -eq 3) {

        $existing += [pscustomobject]@{
            SKU = $p[0]
            Id = $p[1]
            Name = $p[2]
        }
    }
}

Write-Host "      Existing products : $($existing.Count)"

# ============================================================
# 7. BUILD IMPORT PLAN
# ============================================================

Write-Host "[6/10] Building Product Master import plan..." -ForegroundColor Cyan

$plan = @()

foreach ($m in $map) {

    $sameSku = @(
        $existing |
        Where-Object {
            $_.SKU.ToUpperInvariant() -eq $m.SKU.ToUpperInvariant()
        }
    )

    if ($sameSku.Count -gt 1) {
        throw "Duplicate SKU existing di Product Master: $($m.SKU)"
    }

    if ($sameSku.Count -eq 1) {

        $plan += [pscustomobject]@{
            Action = "EXISTS"
            ProductId = $sameSku[0].Id
            SKU = $m.SKU
            Name = $sameSku[0].Name
            File = $m.File
        }

    }
    else {

        $plan += [pscustomobject]@{
            Action = "CREATE"
            ProductId = $null
            SKU = $m.SKU
            Name = $m.Name
            File = $m.File
        }
    }
}

Write-Host ""
$plan | Format-Table Action, SKU, Name, File -AutoSize

$createCount = @(
    $plan |
    Where-Object { $_.Action -eq "CREATE" }
).Count

$existingCount = @(
    $plan |
    Where-Object { $_.Action -eq "EXISTS" }
).Count

Write-Host ""
Write-Host "To create : $createCount"
Write-Host "Existing  : $existingCount"

# ============================================================
# DRY RUN
# ============================================================

if (-not $Apply) {

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host " DRY-RUN COMPLETE" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Business resolved      : OK"
    Write-Host "Tenant resolved        : OK"
    Write-Host "Images                 : 18/18"
    Write-Host "Product Master target  : 18"
    Write-Host "New products           : $createCount"
    Write-Host "Existing products      : $existingCount"
    Write-Host ""
    Write-Host "No database changes."
    Write-Host "No image files copied."
    Write-Host ""
    Write-Host "Run APPLY:"
    Write-Host ""
    Write-Host ".\import_sauri_chicken_parts_images.ps1 -Apply" -ForegroundColor Yellow
    Write-Host ""

    Remove-Item `
        -LiteralPath $work `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue

    exit 0
}

# ============================================================
# 8. BACKUP
# ============================================================

Write-Host "[7/10] Creating controlled backup..." -ForegroundColor Cyan

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

$backupRoot = Join-Path `
    $ProjectRoot `
    "_controlled_backups\sauri-chicken-products-$timestamp"

$publicMedia = Join-Path `
    $ProjectRoot `
    "apps\marketplace_web\public\media\catalog\products\$businessId"

New-Item `
    -ItemType Directory `
    -Path $backupRoot `
    -Force | Out-Null

New-Item `
    -ItemType Directory `
    -Path $publicMedia `
    -Force | Out-Null

# Backup existing product rows.
$backupProductsSql = @"
COPY (
    SELECT *
    FROM catalog_products
    WHERE business_id = '$businessId'
)
TO STDOUT WITH CSV HEADER;
"@

$backupProductsFile = Join-Path `
    $backupRoot `
    "catalog_products.csv"

$encoded = [Convert]::ToBase64String(
    [Text.Encoding]::UTF8.GetBytes($backupProductsSql)
)

$cmd = "echo $encoded | base64 -d | psql -U $dbUser -d $db"

docker exec $container sh -lc $cmd |
    Out-File `
        -FilePath $backupProductsFile `
        -Encoding utf8

if ($LASTEXITCODE -ne 0) {
    throw "Backup catalog_products gagal."
}

# Backup existing target images.
foreach ($m in $map) {

    $target = Join-Path $publicMedia $m.File

    if (Test-Path -LiteralPath $target) {

        $backupImage = Join-Path `
            $backupRoot `
            $m.File

        Copy-Item `
            -LiteralPath $target `
            -Destination $backupImage `
            -Force
    }
}

Write-Host "      Backup : $backupRoot" -ForegroundColor Green

# ============================================================
# 9. CREATE / REUSE PRODUCTS
# ============================================================

Write-Host "[8/10] Creating/reusing Product Master..." -ForegroundColor Cyan

$finalPlan = @()

foreach ($m in $map) {

    $sameSku = @(
        $existing |
        Where-Object {
            $_.SKU.ToUpperInvariant() -eq $m.SKU.ToUpperInvariant()
        }
    )

    if ($sameSku.Count -eq 1) {

        $productId = $sameSku[0].Id

        $finalPlan += [pscustomobject]@{
            ProductId = $productId
            SKU = $m.SKU
            Name = $sameSku[0].Name
            File = $m.File
            Action = "EXISTING"
        }

        continue
    }

    $productId = [guid]::NewGuid().ToString()

    $sku = SqlEscape $m.SKU
    $name = SqlEscape $m.Name
    $description = SqlEscape $m.Description

    Invoke-Sql @"
INSERT INTO catalog_products
(
    id,
    tenant_id,
    business_id,
    category_id,
    sku,
    name,
    description,
    product_type,
    unit,
    price,
    cost_price,
    track_inventory,
    status,
    created_at,
    updated_at
)
VALUES
(
    '$productId',
    '$tenantId',
    '$businessId',
    NULL,
    '$sku',
    '$name',
    '$description',
    '$defaultProductType',
    '$defaultUnit',
    $defaultPrice,
    $defaultCostPrice,
    TRUE,
    '$defaultStatus',
    NOW(),
    NOW()
);
"@

    $finalPlan += [pscustomobject]@{
        ProductId = $productId
        SKU = $m.SKU
        Name = $m.Name
        File = $m.File
        Action = "CREATED"
    }
}

Write-Host "      Product Master processed : $($finalPlan.Count)" -ForegroundColor Green

# ============================================================
# 10. IMAGE TABLE + IMAGE IMPORT
# ============================================================

Write-Host "[9/10] Installing product images..." -ForegroundColor Cyan

$hasImageTable = (
    Exec-Psql @"
SELECT CASE
    WHEN to_regclass('public.catalog_product_images') IS NOT NULL
    THEN 'yes'
    ELSE 'no'
END;
"@
).Trim()

if ($hasImageTable -ne "yes") {

    Write-Host "      Creating catalog_product_images..."

    Invoke-Sql @"
CREATE TABLE IF NOT EXISTS catalog_product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID NOT NULL
        REFERENCES catalog_products(id)
        ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT catalog_product_images_product_url_key
        UNIQUE (product_id, image_url)
);

CREATE INDEX IF NOT EXISTS
    idx_catalog_product_images_product
ON catalog_product_images(product_id);
"@

}
else {

    Write-Host "      catalog_product_images already exists."
}

# ------------------------------------------------------------
# COPY + UPSERT
# ------------------------------------------------------------

foreach ($r in $finalPlan) {

    $source = @(
        $files |
        Where-Object {
            $_.Name -eq $r.File
        }
    )

    if ($source.Count -ne 1) {
        throw "Source image tidak ditemukan unik: $($r.File)"
    }

    $src = $source[0].FullName

    $dst = Join-Path `
        $publicMedia `
        $r.File

    Copy-Item `
        -LiteralPath $src `
        -Destination $dst `
        -Force

    $url = "/media/catalog/products/$businessId/$($r.File)"
    $safeUrl = SqlEscape $url

    Invoke-Sql @"
INSERT INTO catalog_product_images
(
    product_id,
    image_url,
    is_primary,
    sort_order,
    updated_at
)
VALUES
(
    '$($r.ProductId)',
    '$safeUrl',
    TRUE,
    0,
    NOW()
)
ON CONFLICT (product_id, image_url)
DO UPDATE SET
    is_primary = TRUE,
    sort_order = 0,
    updated_at = NOW();
"@

    # Ensure this image is the primary image for this product.
    Invoke-Sql @"
UPDATE catalog_product_images
SET
    is_primary = CASE
        WHEN image_url = '$safeUrl'
        THEN TRUE
        ELSE FALSE
    END,
    updated_at = NOW()
WHERE product_id = '$($r.ProductId)';
"@
}

Write-Host "      18 images installed." -ForegroundColor Green

# ============================================================
# VERIFY
# ============================================================

Write-Host "[10/10] Final verification..." -ForegroundColor Cyan

$productCount = (
    Exec-Psql @"
SELECT COUNT(*)::text
FROM catalog_products
WHERE business_id = '$businessId'
  AND sku IN (
    $((
        $map |
        ForEach-Object {
            "'" + (SqlEscape $_.SKU) + "'"
        }
    ) -join ",")
  );
"@
).Trim()

$imageCount = (
    Exec-Psql @"
SELECT COUNT(*)::text
FROM catalog_product_images
WHERE product_id IN (
    $((
        $finalPlan |
        ForEach-Object {
            "'$($_.ProductId)'"
        }
    ) -join ",")
  );
"@
).Trim()

$physicalMissing = @()

foreach ($r in $finalPlan) {

    $target = Join-Path `
        $publicMedia `
        $r.File

    if (-not (Test-Path -LiteralPath $target)) {
        $physicalMissing += $r.File
    }
}

Write-Host ""
Write-Host "Product Master rows : $productCount"
Write-Host "Image DB rows        : $imageCount"
Write-Host "Physical images      : $($finalPlan.Count - $physicalMissing.Count)"

if ([int]$physicalMissing.Count -gt 0) {

    Write-Host ""
    Write-Host "Missing physical files:" -ForegroundColor Red

    $physicalMissing | ForEach-Object {
        Write-Host " - $_"
    }

    throw "Physical image verification gagal."
}

if ([int]$productCount -lt 18) {
    throw "Product verification gagal. Expected >= 18, actual $productCount."
}

if ([int]$imageCount -lt 18) {
    throw "Image verification gagal. Expected >= 18, actual $imageCount."
}

# ============================================================
# CLEANUP
# ============================================================

Remove-Item `
    -LiteralPath $work `
    -Recurse `
    -Force `
    -ErrorAction SilentlyContinue

# ============================================================
# FINAL REPORT
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " SAURI CHICKEN PARTS IMPORT SUCCESS" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Business ID       : $businessId"
Write-Host "Tenant ID         : $tenantId"
Write-Host "Product Master    : $productCount"
Write-Host "Product Images    : $imageCount"
Write-Host "Physical Images   : 18"
Write-Host ""

Write-Host "Media directory:"
Write-Host $publicMedia
Write-Host ""

Write-Host "Backup directory:"
Write-Host $backupRoot
Write-Host ""

Write-Host "Prices            : Rp0 (belum ditentukan)" -ForegroundColor Yellow
Write-Host "Unit              : kg"
Write-Host "Inventory tracking: TRUE"
Write-Host "Status            : active"
Write-Host ""

Write-Host "Product Master dan image berhasil dibuat secara idempotent." -ForegroundColor Green
Write-Host "Tidak ada produk tenant lain yang disentuh." -ForegroundColor Green
Write-Host ""