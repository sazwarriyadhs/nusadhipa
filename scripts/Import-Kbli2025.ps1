param(
    [string]$CsvPath = ".\data\kbli\kbli_2025.csv",
    [string]$DbContainer = "nusa-dhipa-postgres"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " NUSA DHIPA - KBLI 2025 IMPORTER" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

if (!(Test-Path $CsvPath)) {
    throw "CSV not found: $CsvPath"
}

Write-Host "[1/6] Reading CSV..." -ForegroundColor Cyan

$rows = @(Import-Csv -Path $CsvPath)

if ($rows.Count -eq 0) {
    throw "CSV contains no rows."
}

Write-Host "Rows detected : $($rows.Count)" -ForegroundColor Green

$required = @(
    "version",
    "code",
    "title",
    "description",
    "level",
    "category_code",
    "category_title",
    "group_code",
    "group_title",
    "subgroup_code",
    "subgroup_title",
    "parent_code",
    "source",
    "source_reference"
)

$headers = @($rows[0].PSObject.Properties.Name)

foreach ($column in $required) {
    if ($headers -notcontains $column) {
        throw "Required CSV column missing: $column"
    }
}

Write-Host "[2/6] CSV structure validated." -ForegroundColor Green

Write-Host "[3/6] Validating KBLI 2025..." -ForegroundColor Cyan

$activityCount = @(
    $rows | Where-Object {
        $_.level -eq "activity"
    }
).Count

$code46322 = @(
    $rows | Where-Object {
        $_.code -eq "46322"
    }
)

Write-Host "Total records : $($rows.Count)" -ForegroundColor White
Write-Host "Activities    : $activityCount" -ForegroundColor White

if ($code46322.Count -eq 0) {
    throw "KBLI 46322 was not found in CSV."
}

Write-Host "KBLI 46322   : FOUND" -ForegroundColor Green
Write-Host "Title         : $($code46322[0].title)" -ForegroundColor White

Write-Host "[4/6] Copying CSV into PostgreSQL container..." -ForegroundColor Cyan

$containerCsv = "/tmp/kbli_2025.csv"

docker cp $CsvPath "${DbContainer}:$containerCsv"

if ($LASTEXITCODE -ne 0) {
    throw "docker cp failed."
}

Write-Host "[5/6] Importing into kbli_master..." -ForegroundColor Cyan

$sql = @"
BEGIN;

CREATE TEMP TABLE kbli_import (
    version varchar(10),
    code varchar(10),
    title text,
    description text,
    level varchar(30),
    category_code varchar(10),
    category_title text,
    group_code varchar(10),
    group_title text,
    subgroup_code varchar(10),
    subgroup_title text,
    parent_code varchar(10),
    source varchar(50),
    source_reference text
);

COPY kbli_import (
    version,
    code,
    title,
    description,
    level,
    category_code,
    category_title,
    group_code,
    group_title,
    subgroup_code,
    subgroup_title,
    parent_code,
    source,
    source_reference
)
FROM '$containerCsv'
WITH (
    FORMAT csv,
    HEADER true,
    QUOTE '"',
    ESCAPE '"'
);

INSERT INTO kbli_master (
    version,
    code,
    title,
    description,
    level,
    category_code,
    category_title,
    group_code,
    group_title,
    subgroup_code,
    subgroup_title,
    parent_code,
    is_active,
    source,
    source_reference
)
SELECT
    version,
    code,
    COALESCE(NULLIF(TRIM(title), ''), code),
    COALESCE(description, ''),
    level,
    NULLIF(category_code, ''),
    NULLIF(category_title, ''),
    NULLIF(group_code, ''),
    NULLIF(group_title, ''),
    NULLIF(subgroup_code, ''),
    NULLIF(subgroup_title, ''),
    NULLIF(parent_code, ''),
    true,
    COALESCE(NULLIF(source, ''), 'BPS'),
    NULLIF(source_reference, '')
FROM kbli_import
ON CONFLICT DO NOTHING;

COMMIT;
"@

$sql | docker exec -i $DbContainer psql `
    -U nusa_dhipa `
    -d nusa_dhipa `
    -v ON_ERROR_STOP=1

if ($LASTEXITCODE -ne 0) {
    throw "KBLI database import failed."
}

Write-Host "[6/6] Verifying database..." -ForegroundColor Cyan

$verify = @"
SELECT
    COUNT(*) AS total,
    COUNT(*) FILTER (WHERE level = 'activity') AS activities,
    COUNT(*) FILTER (WHERE code = '46322') AS kbli_46322
FROM kbli_master
WHERE version = '2025';

SELECT
    version,
    code,
    title,
    level,
    category_code,
    group_code,
    subgroup_code,
    parent_code,
    source
FROM kbli_master
WHERE version = '2025'
  AND code = '46322';
"@

docker exec -i $DbContainer psql `
    -U nusa_dhipa `
    -d nusa_dhipa `
    -v ON_ERROR_STOP=1 `
    -c $verify

if ($LASTEXITCODE -ne 0) {
    throw "KBLI verification failed."
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host " KBLI 2025 IMPORT COMPLETED" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green


