# PowerShell script to generate platform app icons from the SVG
# This script will convert the SVG to PNG (1024x1024) and then run flutter_launcher_icons

# Step 1: Convert svg to png
Write-Host "Convirtiendo SVG a PNG de 1024x1024..." -ForegroundColor Cyan
.
\tools\convert_svg.ps1 -svgPath "assets/icons/app_icon.svg" -pngPath "assets/icons/app_icon.png" -size 1024

if ($LASTEXITCODE -ne 0) { Write-Host "Error al convertir el SVG a PNG" -ForegroundColor Red; exit $LASTEXITCODE }

# Step 2: Pub get
Write-Host "Ejecutando flutter pub get..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { Write-Host "flutter pub get falló" -ForegroundColor Red; exit $LASTEXITCODE }

# Step 3: Generar iconos con flutter_launcher_icons
Write-Host "Generando iconos con flutter_launcher_icons..." -ForegroundColor Cyan
flutter pub run flutter_launcher_icons:main
if ($LASTEXITCODE -ne 0) { Write-Host "Generación de iconos falló" -ForegroundColor Red; exit $LASTEXITCODE }

Write-Host "Iconos generados correctamente." -ForegroundColor Green
