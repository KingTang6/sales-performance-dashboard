Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DatabasePath = Join-Path $ProjectRoot "superstore_analysis.db"
$CsvPath = Join-Path $ProjectRoot "data/superstore_cleaned.csv"
$SqlDir = Join-Path $ProjectRoot "sql"

if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
    throw "sqlite3 was not found in PATH. Install SQLite before running this script."
}

if (Test-Path $DatabasePath) {
    Remove-Item $DatabasePath
}

sqlite3 $DatabasePath ".read $((Join-Path $SqlDir '01_create_tables.sql').Replace('\', '/'))"
sqlite3 $DatabasePath ".mode csv" ".import --skip 1 $($CsvPath.Replace('\', '/')) superstore_cleaned"

$queryFiles = @(
    "02_sales_kpis.sql",
    "03_monthly_trends.sql",
    "04_region_analysis.sql",
    "05_product_profitability.sql",
    "06_customer_segment_analysis.sql",
    "07_high_sales_low_profit.sql"
)

foreach ($file in $queryFiles) {
    Write-Host ""
    Write-Host "===== $file ====="
    sqlite3 $DatabasePath ".read $((Join-Path $SqlDir $file).Replace('\', '/'))"
}
