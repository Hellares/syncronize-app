# =============================================================================
# Syncronize - build-apk.ps1
# Builds Flutter APK con flavor dev (beta) o prod (producción).
#
# Uso:
#   .\scripts\build-apk.ps1 dev    # APK dev → apunta a saas-beta.syncronize.net.pe
#   .\scripts\build-apk.ps1 prod   # APK prod → apunta a saas.syncronize.net.pe
#   .\scripts\build-apk.ps1 both   # ambos APKs en paralelo
#
# Flags fijas:
#   --release: optimizado para distribución (NO debug).
#   --flavor + --dart-define=FLAVOR: dual-env (selecciona endpoint backend
#     y bundleId; com.syncronize.app.dev side-by-side com.syncronize.app).
#   --no-tree-shake-icons: la app guarda iconos en BD como codePoint y los
#     reconstruye en runtime (custom_sede_selector, categorias_gasto, etc.),
#     así que el tree-shaking automático no funciona. Sin esta flag el
#     build falla con "Avoid non-constant invocations of IconData".
# =============================================================================

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("dev","prod","both")]
    [string]$Flavor
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot/..

function Build-Flavor {
    param([string]$f)
    Write-Host ""
    Write-Host "==> [build] APK $f release" -ForegroundColor Cyan
    Write-Host ""
    flutter build apk --release --flavor $f --dart-define=FLAVOR=$f --no-tree-shake-icons
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk --flavor $f falló (exit $LASTEXITCODE)" }
    $outPath = "build/app/outputs/flutter-apk/app-$f-release.apk"
    if (Test-Path $outPath) {
        $size = "{0:N1} MB" -f ((Get-Item $outPath).Length / 1MB)
        Write-Host ""
        Write-Host "✓ $f listo: $outPath ($size)" -ForegroundColor Green
    }
}

if ($Flavor -eq "both") {
    Build-Flavor "dev"
    Build-Flavor "prod"
} else {
    Build-Flavor $Flavor
}

Write-Host ""
Write-Host "==> [done] Build finalizado" -ForegroundColor Green
