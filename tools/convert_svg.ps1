# Convert SVG to PNG for app icons (Windows PowerShell)
# Requires Inkscape (recommended) or ImageMagick (magick) installed.

param(
    [string]$svgPath = "assets/icons/app_icon.svg",
    [string]$pngPath = "assets/icons/app_icon.png",
    [int]$size = 1024
)

$svgFull = Resolve-Path $svgPath
$pngFull = Resolve-Path $pngPath -ErrorAction SilentlyContinue
if (-Not $pngFull) {
    $pngFull = Join-Path (Split-Path $svgFull -Parent) (Split-Path $pngPath -Leaf)
}

# Preferred: use Inkscape (command line)
$inkscape = Get-Command inkscape -ErrorAction SilentlyContinue
if ($inkscape) {
    Write-Host "Converting SVG to PNG using Inkscape..." -ForegroundColor Green
    & inkscape --export-type=png --export-filename=$pngFull --export-width=$size --export-height=$size $svgFull
    exit $LASTEXITCODE
}

# Fallback: use ImageMagick (magick)
$magick = Get-Command magick -ErrorAction SilentlyContinue
if ($magick) {
    Write-Host "Converting SVG to PNG using ImageMagick..." -ForegroundColor Green
    & magick convert $svgFull -resize ${size}x${size} $pngFull
    exit $LASTEXITCODE
}

Write-Host "Error: Inkscape or ImageMagick not found. Please install one of these tools and try again." -ForegroundColor Red
exit 1
