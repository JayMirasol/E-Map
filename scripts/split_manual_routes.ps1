# Split manual_routes.json by building for easier transfer

$sourcePath = "c:\Dev\E-Map\assets\data\manual_routes.json"
$outputDir = "c:\Dev\E-Map\assets\data\manual_routes_split"

Write-Host "Splitting manual_routes.json by building..." -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Load JSON
$data = Get-Content $sourcePath -Raw | ConvertFrom-Json
$dataDict = $data.PSObject.Properties | ForEach-Object { @{$_.Name = $_.Value} }

# Split by category
$buildings = @{
    'main' = @()
    'ngo' = @()
    'pagcor' = @()
    'campus' = @()
    'other' = @()
}

foreach ($entry in $data.PSObject.Properties) {
    $key = $entry.Name
    $value = $entry.Value
    
    if ($key -match 'MAIN|^[1-4]:') {
        $buildings['main'] += @{$key = $value}
    }
    elseif ($key -match 'NGO|^[5-6]:') {
        $buildings['ngo'] += @{$key = $value}
    }
    elseif ($key -match 'PAGCOR|^[7-9]:|^10:') {
        $buildings['pagcor'] += @{$key = $value}
    }
    elseif ($key -match 'CAMPUS|GATE|^-1:') {
        $buildings['campus'] += @{$key = $value}
    }
    else {
        $buildings['other'] += @{$key = $value}
    }
}

# Save split files
$totalSize = 0
foreach ($building in $buildings.Keys) {
    if ($buildings[$building].Count -eq 0) {
        continue
    }
    
    $outputPath = Join-Path $outputDir "manual_routes_$building.json"
    
    # Convert array of hashtables to single hashtable
    $merged = @{}
    foreach ($item in $buildings[$building]) {
        $merged += $item
    }
    
    $json = $merged | ConvertTo-Json -Depth 10
    $json | Out-File -FilePath $outputPath -Encoding UTF8
    
    $size = (Get-Item $outputPath).Length / 1KB
    $totalSize += $size
    $count = $buildings[$building].Count
    
    Write-Host "  $building : $count routes, $([math]::Round($size, 2)) KB" -ForegroundColor Green
}

Write-Host ""
Write-Host "Split complete! Files saved to:" -ForegroundColor Yellow
Write-Host "  $outputDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total size: $([math]::Round($totalSize, 2)) KB" -ForegroundColor Green
Write-Host "Now you can transfer only the files you need to your phone!"
