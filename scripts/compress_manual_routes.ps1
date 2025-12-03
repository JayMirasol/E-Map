# Compress manual_routes.json to a ZIP file for easy transfer to phone

$sourcePath = "c:\Dev\E-Map\assets\data\manual_routes.json"
$destPath = "c:\Dev\E-Map\assets\data\manual_routes.zip"

Write-Host "Compressing manual_routes.json..." -ForegroundColor Cyan

# Remove old zip if exists
if (Test-Path $destPath) {
    Remove-Item $destPath
}

# Compress
Compress-Archive -Path $sourcePath -DestinationPath $destPath -CompressionLevel Optimal

$originalSize = (Get-Item $sourcePath).Length / 1KB
$compressedSize = (Get-Item $destPath).Length / 1KB
$ratio = [math]::Round(($compressedSize / $originalSize) * 100, 2)

Write-Host ""
Write-Host "Compression Complete!" -ForegroundColor Green
Write-Host "Original size:   $([math]::Round($originalSize, 2)) KB"
Write-Host "Compressed size: $([math]::Round($compressedSize, 2)) KB"
Write-Host "Ratio: $ratio%"
Write-Host ""
Write-Host "Compressed file: $destPath" -ForegroundColor Yellow
Write-Host "You can now transfer this ZIP file to your phone easily!"
