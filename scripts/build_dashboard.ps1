Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$RawPath = Join-Path $ProjectRoot "data/superstore_raw.csv"
$CleanPath = Join-Path $ProjectRoot "data/superstore_cleaned.csv"
$AnalysisDir = Join-Path $ProjectRoot "analysis"
$AssetsDir = Join-Path $ProjectRoot "assets"

New-Item -ItemType Directory -Force $AnalysisDir, $AssetsDir | Out-Null

if (-not (Test-Path $RawPath)) {
    throw "Missing raw dataset at $RawPath"
}

function Convert-Number {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return 0.0 }
    return [double]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture)
}

function Convert-DateValue {
    param([string]$Value)
    $formats = @("M/d/yyyy", "MM/dd/yyyy", "M/d/yy", "MM/dd/yy")
    $parsed = [datetime]::MinValue
    if ([datetime]::TryParseExact($Value, $formats, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        return $parsed
    }
    if ([datetime]::TryParse($Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        return $parsed
    }
    throw "Could not parse date value '$Value'"
}

function Format-CurrencyShort {
    param([double]$Value)
    if ([math]::Abs($Value) -ge 1000000) { return ('$' + ("{0:N2}M" -f ($Value / 1000000))) }
    if ([math]::Abs($Value) -ge 1000) { return ('$' + ("{0:N1}K" -f ($Value / 1000))) }
    return ('$' + ("{0:N0}" -f $Value))
}

function Format-Percent {
    param([double]$Value)
    return ("{0:P1}" -f $Value)
}

function Get-SafeMax {
    param([array]$Values)
    $max = ($Values | Measure-Object -Maximum).Maximum
    if ($null -eq $max -or $max -eq 0) { return 1 }
    return [double]$max
}

function Read-SuperstoreCsv {
    param([string]$Path)

    Add-Type -AssemblyName Microsoft.VisualBasic
    $parser = New-Object Microsoft.VisualBasic.FileIO.TextFieldParser($Path)
    $parser.TextFieldType = [Microsoft.VisualBasic.FileIO.FieldType]::Delimited
    $parser.SetDelimiters(",")
    $parser.HasFieldsEnclosedInQuotes = $true

    try {
        $headers = $parser.ReadFields()
        $records = New-Object System.Collections.Generic.List[object]

        while (-not $parser.EndOfData) {
            $fields = $parser.ReadFields()
            if ($fields.Count -ne $headers.Count) {
                Write-Warning "Skipping malformed CSV row with $($fields.Count) fields; expected $($headers.Count)."
                continue
            }

            $record = [ordered]@{}
            for ($i = 0; $i -lt $headers.Count; $i++) {
                $record[$headers[$i]] = $fields[$i]
            }
            $records.Add([pscustomobject]$record) | Out-Null
        }

        return $records
    }
    finally {
        $parser.Close()
    }
}

$rows = Read-SuperstoreCsv $RawPath
$cleanRows = foreach ($row in $rows) {
    $orderDate = Convert-DateValue $row.'Order Date'
    $shipDate = Convert-DateValue $row.'Ship Date'
    $sales = Convert-Number $row.Sales
    $profit = Convert-Number $row.Profit
    $quantity = [int](Convert-Number $row.'Order Quantity')
    $discount = Convert-Number $row.Discount
    $shippingCost = Convert-Number $row.'Shipping Cost'
    $unitPrice = Convert-Number $row.'Unit Price'

    [pscustomobject]@{
        RowID = [int]$row.'Row ID'
        OrderID = [int]$row.'Order ID'
        OrderDate = $orderDate.ToString("yyyy-MM-dd")
        ShipDate = $shipDate.ToString("yyyy-MM-dd")
        Year = $orderDate.Year
        Month = $orderDate.Month
        YearMonth = $orderDate.ToString("yyyy-MM")
        Region = $row.Region
        Province = $row.Province
        CustomerSegment = $row.'Customer Segment'
        Category = $row.'Product Category'
        SubCategory = $row.'Product Sub-Category'
        ProductName = $row.'Product Name'
        Sales = [math]::Round($sales, 2)
        Profit = [math]::Round($profit, 2)
        Quantity = $quantity
        Discount = [math]::Round($discount, 4)
        UnitPrice = [math]::Round($unitPrice, 2)
        ShippingCost = [math]::Round($shippingCost, 2)
        ProfitMargin = if ($sales -ne 0) { [math]::Round($profit / $sales, 4) } else { 0 }
    }
}

$cleanRows | Export-Csv $CleanPath -NoTypeInformation -Encoding UTF8

$totalSales = ($cleanRows | Measure-Object Sales -Sum).Sum
$totalProfit = ($cleanRows | Measure-Object Profit -Sum).Sum
$totalQuantity = ($cleanRows | Measure-Object Quantity -Sum).Sum
$orderCount = ($cleanRows | Select-Object -ExpandProperty OrderID -Unique).Count
$profitMargin = $totalProfit / $totalSales
$avgDiscount = ($cleanRows | Measure-Object Discount -Average).Average
$negativeProfitRows = ($cleanRows | Where-Object { $_.Profit -lt 0 }).Count

$monthly = $cleanRows |
    Group-Object YearMonth |
    ForEach-Object {
        $sales = ($_.Group | Measure-Object Sales -Sum).Sum
        $profit = ($_.Group | Measure-Object Profit -Sum).Sum
        [pscustomobject]@{
            YearMonth = $_.Name
            Sales = [math]::Round($sales, 2)
            Profit = [math]::Round($profit, 2)
            Orders = ($_.Group | Select-Object -ExpandProperty OrderID -Unique).Count
            ProfitMargin = [math]::Round($profit / $sales, 4)
        }
    } | Sort-Object YearMonth

$region = $cleanRows |
    Group-Object Region |
    ForEach-Object {
        $sales = ($_.Group | Measure-Object Sales -Sum).Sum
        $profit = ($_.Group | Measure-Object Profit -Sum).Sum
        [pscustomobject]@{
            Region = $_.Name
            Sales = [math]::Round($sales, 2)
            Profit = [math]::Round($profit, 2)
            ProfitMargin = [math]::Round($profit / $sales, 4)
        }
    } | Sort-Object Sales -Descending

$category = $cleanRows |
    Group-Object Category |
    ForEach-Object {
        $sales = ($_.Group | Measure-Object Sales -Sum).Sum
        $profit = ($_.Group | Measure-Object Profit -Sum).Sum
        [pscustomobject]@{
            Category = $_.Name
            Sales = [math]::Round($sales, 2)
            Profit = [math]::Round($profit, 2)
            ProfitMargin = [math]::Round($profit / $sales, 4)
        }
    } | Sort-Object Profit -Descending

$segment = $cleanRows |
    Group-Object CustomerSegment |
    ForEach-Object {
        $sales = ($_.Group | Measure-Object Sales -Sum).Sum
        $profit = ($_.Group | Measure-Object Profit -Sum).Sum
        [pscustomobject]@{
            CustomerSegment = $_.Name
            Sales = [math]::Round($sales, 2)
            Profit = [math]::Round($profit, 2)
            ProfitMargin = [math]::Round($profit / $sales, 4)
        }
    } | Sort-Object Sales -Descending

$subCategory = $cleanRows |
    Group-Object SubCategory |
    ForEach-Object {
        $sales = ($_.Group | Measure-Object Sales -Sum).Sum
        $profit = ($_.Group | Measure-Object Profit -Sum).Sum
        $quantity = ($_.Group | Measure-Object Quantity -Sum).Sum
        [pscustomobject]@{
            SubCategory = $_.Name
            Sales = [math]::Round($sales, 2)
            Profit = [math]::Round($profit, 2)
            Quantity = [int]$quantity
            ProfitMargin = [math]::Round($profit / $sales, 4)
        }
    } | Sort-Object Sales -Descending

$riskSubCategory = $subCategory |
    Where-Object { $_.Sales -ge 100000 -and $_.ProfitMargin -lt 0.05 } |
    Sort-Object ProfitMargin |
    Select-Object -First 8

$monthly | Export-Csv (Join-Path $AnalysisDir "monthly_sales_profit.csv") -NoTypeInformation -Encoding UTF8
$region | Export-Csv (Join-Path $AnalysisDir "region_performance.csv") -NoTypeInformation -Encoding UTF8
$category | Export-Csv (Join-Path $AnalysisDir "category_profitability.csv") -NoTypeInformation -Encoding UTF8
$segment | Export-Csv (Join-Path $AnalysisDir "segment_contribution.csv") -NoTypeInformation -Encoding UTF8
$subCategory | Export-Csv (Join-Path $AnalysisDir "subcategory_performance.csv") -NoTypeInformation -Encoding UTF8
$riskSubCategory | Export-Csv (Join-Path $AnalysisDir "high_sales_low_profit_subcategories.csv") -NoTypeInformation -Encoding UTF8

$topRegion = $region | Select-Object -First 1
$topCategory = $category | Select-Object -First 1
$topSegment = $segment | Select-Object -First 1
$lowestMarginSubCategory = $riskSubCategory | Select-Object -First 1

$metrics = [pscustomobject]@{
    DataSource = "https://raw.githubusercontent.com/curran/data/gh-pages/superstoreSales/superstoreSales.csv"
    Rows = $cleanRows.Count
    Orders = $orderCount
    TotalSales = [math]::Round($totalSales, 2)
    TotalProfit = [math]::Round($totalProfit, 2)
    TotalQuantity = [int]$totalQuantity
    ProfitMargin = [math]::Round($profitMargin, 4)
    AverageDiscount = [math]::Round($avgDiscount, 4)
    NegativeProfitRows = $negativeProfitRows
    TopRegion = $topRegion.Region
    TopRegionSales = $topRegion.Sales
    TopCategory = $topCategory.Category
    TopCategoryProfit = $topCategory.Profit
    TopSegment = $topSegment.CustomerSegment
    TopSegmentSales = $topSegment.Sales
    LowestMarginRiskSubCategory = $lowestMarginSubCategory.SubCategory
    LowestMarginRiskSubCategoryMargin = $lowestMarginSubCategory.ProfitMargin
}
$metrics | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $AnalysisDir "summary_metrics.json") -Encoding UTF8

Add-Type -AssemblyName System.Drawing

$width = 1600
$height = 1000
$bitmap = New-Object Drawing.Bitmap $width, $height
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.TextRenderingHint = [Drawing.Text.TextRenderingHint]::ClearTypeGridFit

$bg = [Drawing.Color]::FromArgb(246, 248, 251)
$ink = [Drawing.Color]::FromArgb(31, 41, 55)
$muted = [Drawing.Color]::FromArgb(107, 114, 128)
$grid = [Drawing.Color]::FromArgb(229, 231, 235)
$blue = [Drawing.Color]::FromArgb(37, 99, 235)
$green = [Drawing.Color]::FromArgb(5, 150, 105)
$red = [Drawing.Color]::FromArgb(220, 38, 38)
$amber = [Drawing.Color]::FromArgb(217, 119, 6)
$violet = [Drawing.Color]::FromArgb(124, 58, 237)
$card = [Drawing.Color]::White

$graphics.Clear($bg)

function New-Font {
    param([float]$Size, [Drawing.FontStyle]$Style = [Drawing.FontStyle]::Regular)
    return New-Object Drawing.Font "Segoe UI", $Size, $Style
}

function Draw-Text {
    param(
        [string]$Text,
        [float]$X,
        [float]$Y,
        [float]$Size,
        [Drawing.Color]$Color,
        [Drawing.FontStyle]$Style = [Drawing.FontStyle]::Regular
    )
    $font = New-Font $Size $Style
    $brush = New-Object Drawing.SolidBrush $Color
    $graphics.DrawString($Text, $font, $brush, $X, $Y)
    $brush.Dispose()
    $font.Dispose()
}

function Draw-Card {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    $brush = New-Object Drawing.SolidBrush $card
    $pen = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(224, 229, 236)), 1
    $graphics.FillRectangle($brush, $X, $Y, $W, $H)
    $graphics.DrawRectangle($pen, $X, $Y, $W, $H)
    $brush.Dispose()
    $pen.Dispose()
}

function Draw-Kpi {
    param([int]$X, [string]$Label, [string]$Value, [string]$Note, [Drawing.Color]$Accent)
    Draw-Card $X 105 355 115
    $accentBrush = New-Object Drawing.SolidBrush $Accent
    $graphics.FillRectangle($accentBrush, $X, 105, 8, 115)
    $accentBrush.Dispose()
    Draw-Text $Label ($X + 24) 124 13 $muted ([Drawing.FontStyle]::Regular)
    Draw-Text $Value ($X + 24) 148 28 $ink ([Drawing.FontStyle]::Bold)
    Draw-Text $Note ($X + 24) 190 11 $muted ([Drawing.FontStyle]::Regular)
}

function Draw-BarChart {
    param([array]$Data, [string]$LabelField, [string]$ValueField, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Title, [Drawing.Color]$Color)
    Draw-Card $X $Y $W $H
    Draw-Text $Title ($X + 22) ($Y + 18) 16 $ink ([Drawing.FontStyle]::Bold)
    $plotX = $X + 170
    $plotY = $Y + 58
    $plotW = $W - 205
    $barH = 28
    $gap = 15
    $max = Get-SafeMax ($Data | ForEach-Object { [double]$_.$ValueField })
    $i = 0
    foreach ($item in $Data) {
        $barY = $plotY + ($i * ($barH + $gap))
        $value = [double]$item.$ValueField
        $label = [string]$item.$LabelField
        $barW = [int]([math]::Max(2, ($value / $max) * $plotW))
        Draw-Text $label ($X + 22) ($barY + 3) 11 $muted
        $barBrush = New-Object Drawing.SolidBrush $Color
        $graphics.FillRectangle($barBrush, $plotX, $barY, $barW, $barH)
        $barBrush.Dispose()
        Draw-Text (Format-CurrencyShort $value) ($plotX + $barW + 8) ($barY + 3) 10 $ink
        $i += 1
    }
}

function Draw-LineChart {
    param([array]$Data, [int]$X, [int]$Y, [int]$W, [int]$H)
    Draw-Card $X $Y $W $H
    Draw-Text "Monthly Sales Trend" ($X + 22) ($Y + 18) 16 $ink ([Drawing.FontStyle]::Bold)
    $plotX = $X + 55
    $plotY = $Y + 58
    $plotW = $W - 85
    $plotH = $H - 105
    $penGrid = New-Object Drawing.Pen $grid, 1
    for ($i = 0; $i -le 4; $i++) {
        $yy = $plotY + ($i * $plotH / 4)
        $graphics.DrawLine($penGrid, $plotX, $yy, $plotX + $plotW, $yy)
    }
    $penGrid.Dispose()
    $max = Get-SafeMax ($Data | ForEach-Object { [double]$_.Sales })
    $points = New-Object 'System.Collections.Generic.List[Drawing.PointF]'
    for ($i = 0; $i -lt $Data.Count; $i++) {
        $xPoint = $plotX + (($i / [math]::Max(1, $Data.Count - 1)) * $plotW)
        $yPoint = $plotY + $plotH - (([double]$Data[$i].Sales / $max) * $plotH)
        $points.Add((New-Object Drawing.PointF ([float]$xPoint), ([float]$yPoint)))
    }
    $pen = New-Object Drawing.Pen $blue, 3
    $graphics.DrawLines($pen, $points.ToArray())
    $pen.Dispose()
    $dotBrush = New-Object Drawing.SolidBrush $blue
    foreach ($pt in $points) {
        $graphics.FillEllipse($dotBrush, $pt.X - 3, $pt.Y - 3, 6, 6)
    }
    $dotBrush.Dispose()
    Draw-Text $Data[0].YearMonth $plotX ($Y + $H - 35) 10 $muted
    Draw-Text $Data[$Data.Count - 1].YearMonth ($X + $W - 92) ($Y + $H - 35) 10 $muted
    Draw-Text ("Peak month: " + (($Data | Sort-Object Sales -Descending | Select-Object -First 1).YearMonth)) ($X + 365) ($Y + $H - 35) 10 $muted
}

function Draw-RiskTable {
    param([array]$Data, [int]$X, [int]$Y, [int]$W, [int]$H)
    Draw-Card $X $Y $W $H
    Draw-Text "High Sales, Low Profit Diagnostic" ($X + 22) ($Y + 18) 16 $ink ([Drawing.FontStyle]::Bold)
    Draw-Text "Sub-Category" ($X + 22) ($Y + 58) 10 $muted ([Drawing.FontStyle]::Bold)
    Draw-Text "Sales" ($X + 330) ($Y + 58) 10 $muted ([Drawing.FontStyle]::Bold)
    Draw-Text "Margin" ($X + 440) ($Y + 58) 10 $muted ([Drawing.FontStyle]::Bold)
    $rowY = $Y + 84
    foreach ($item in ($Data | Select-Object -First 6)) {
        $color = if ($item.ProfitMargin -lt 0) { $red } elseif ($item.ProfitMargin -lt 0.03) { $amber } else { $ink }
        Draw-Text $item.SubCategory ($X + 22) $rowY 11 $ink
        Draw-Text (Format-CurrencyShort $item.Sales) ($X + 330) $rowY 11 $ink
        Draw-Text (Format-Percent $item.ProfitMargin) ($X + 440) $rowY 11 $color ([Drawing.FontStyle]::Bold)
        $rowY += 34
    }
}

Draw-Text "Sales Performance Analytics Dashboard" 55 32 25 $ink ([Drawing.FontStyle]::Bold)
Draw-Text "Superstore retail transaction analysis | Executive one-page view" 56 69 12 $muted

Draw-Kpi 55 "Total Sales" (Format-CurrencyShort $totalSales) ("Across " + $cleanRows.Count.ToString("N0") + " transaction rows") $blue
Draw-Kpi 425 "Total Profit" (Format-CurrencyShort $totalProfit) ("Margin " + (Format-Percent $profitMargin)) $green
Draw-Kpi 795 "Total Orders" ($orderCount.ToString("N0")) ("Quantity sold " + $totalQuantity.ToString("N0")) $violet
Draw-Kpi 1165 "Avg Discount" (Format-Percent $avgDiscount) ($negativeProfitRows.ToString("N0") + " rows with negative profit") $amber

Draw-LineChart $monthly 55 250 940 330
Draw-BarChart ($region | Select-Object -First 6) "Region" "Sales" 1020 250 525 330 "Sales by Region" $blue
Draw-BarChart ($category | Sort-Object Profit -Descending) "Category" "Profit" 55 610 470 305 "Profit by Category" $green
Draw-BarChart ($segment | Select-Object -First 4) "CustomerSegment" "Sales" 555 610 470 305 "Sales by Customer Segment" $violet
Draw-RiskTable $riskSubCategory 1055 610 490 305

Draw-Text ("Insight: " + $topRegion.Region + " leads sales, " + $topCategory.Category + " leads profit, and " + $lowestMarginSubCategory.SubCategory + " needs margin review.") 56 945 12 $muted

$pngPath = Join-Path $AssetsDir "sales_performance_dashboard.png"
$bitmap.Save($pngPath, [Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()

$insights = @"
# Analysis Notes

- Dataset rows: $($cleanRows.Count.ToString("N0"))
- Unique orders: $($orderCount.ToString("N0"))
- Total sales: $(Format-CurrencyShort $totalSales)
- Total profit: $(Format-CurrencyShort $totalProfit)
- Profit margin: $(Format-Percent $profitMargin)
- Top region by sales: $($topRegion.Region) ($(Format-CurrencyShort $topRegion.Sales))
- Most profitable category: $($topCategory.Category) ($(Format-CurrencyShort $topCategory.Profit))
- Largest customer segment by sales: $($topSegment.CustomerSegment) ($(Format-CurrencyShort $topSegment.Sales))
- Margin risk example: $($lowestMarginSubCategory.SubCategory) has $(Format-CurrencyShort $lowestMarginSubCategory.Sales) sales and $(Format-Percent $lowestMarginSubCategory.ProfitMargin) margin.

Recommended business actions:

1. Prioritize margin review for high-sales, low-margin sub-categories before increasing promotional spend.
2. Use the top-performing region as the baseline for sales playbook comparison.
3. Track segment-level contribution monthly to separate revenue growth from profit quality.
"@
$insights | Set-Content (Join-Path $AnalysisDir "analysis_notes.md") -Encoding UTF8

Write-Host "Generated cleaned data, analysis outputs, and dashboard image."
Write-Host "Dashboard image: $pngPath"
