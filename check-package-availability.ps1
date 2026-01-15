# Script PowerShell pour vérifier la disponibilité du package Android
# Usage: .\check-package-availability.ps1

$packageName = "com.pouls.scolaire.parentresponsable"

Write-Host "🔍 Vérification de la disponibilité du package: $packageName" -ForegroundColor Cyan
Write-Host ""

# 1. Vérification sur Google Play Store
Write-Host "1. Vérification sur Google Play Store..." -ForegroundColor Yellow
$playStoreUrl = "https://play.google.com/store/apps/details?id=$packageName"
try {
    $response = Invoke-WebRequest -Uri $playStoreUrl -UseBasicParsing -ErrorAction SilentlyContinue
    if ($response.StatusCode -eq 200) {
        Write-Host "   ❌ Le package existe déjà sur Google Play Store!" -ForegroundColor Red
        Write-Host "   URL: $playStoreUrl" -ForegroundColor Gray
    }
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "   ✅ Package non trouvé sur Google Play Store (probablement disponible)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Impossible de vérifier (erreur: $($_.Exception.Message))" -ForegroundColor Yellow
    }
}

Write-Host ""

# 2. Vérification sur APK Mirror
Write-Host "2. Vérification sur APK Mirror..." -ForegroundColor Yellow
$apkMirrorUrl = "https://www.apkmirror.com/apk/?q=$packageName"
try {
    $response = Invoke-WebRequest -Uri $apkMirrorUrl -UseBasicParsing -ErrorAction SilentlyContinue
    if ($response.Content -match $packageName) {
        Write-Host "   ⚠️  Le package pourrait exister sur APK Mirror" -ForegroundColor Yellow
    } else {
        Write-Host "   ✅ Package non trouvé sur APK Mirror" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️  Impossible de vérifier APK Mirror" -ForegroundColor Yellow
}

Write-Host ""

# 3. Vérification locale dans le projet
Write-Host "3. Vérification dans le projet local..." -ForegroundColor Yellow
$buildGradlePath = "android\app\build.gradle.kts"
if (Test-Path $buildGradlePath) {
    $content = Get-Content $buildGradlePath -Raw
    if ($content -match $packageName) {
        Write-Host "   ✅ Package trouvé dans build.gradle.kts" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Package non trouvé dans build.gradle.kts!" -ForegroundColor Red
    }
} else {
    Write-Host "   ⚠️  Fichier build.gradle.kts non trouvé" -ForegroundColor Yellow
}

Write-Host ""

# 4. Vérification du MainActivity
Write-Host "4. Vérification du MainActivity..." -ForegroundColor Yellow
$mainActivityPath = "android\app\src\main\kotlin\com\pouls\scolaire\parentresponsable\MainActivity.kt"
if (Test-Path $mainActivityPath) {
    $content = Get-Content $mainActivityPath -Raw
    if ($content -match $packageName) {
        Write-Host "   ✅ Package trouvé dans MainActivity.kt" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Package non trouvé dans MainActivity.kt!" -ForegroundColor Red
    }
} else {
    Write-Host "   ❌ MainActivity.kt non trouvé au bon emplacement!" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Résumé:" -ForegroundColor Cyan
Write-Host "   Package: $packageName" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT:" -ForegroundColor Yellow
Write-Host "   - La vérification en ligne n'est pas garantie à 100%" -ForegroundColor Gray
Write-Host "   - Pour être sûr, créez une application de test dans Google Play Console" -ForegroundColor Gray
Write-Host "   - Une fois publié, le package devient votre propriété exclusive" -ForegroundColor Gray

