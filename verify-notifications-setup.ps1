# Script de vérification de la configuration des notifications
# Usage: .\verify-notifications-setup.ps1

Write-Host "🔍 Vérification de la configuration des notifications" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# 1. Vérifier les fichiers Google Services
Write-Host "1. Vérification des fichiers Google Services..." -ForegroundColor Yellow

$androidFile = "android\app\google-services.json"
$iosFile = "ios\Runner\GoogleService-Info.plist"

if (Test-Path $androidFile) {
    Write-Host "   ✅ google-services.json trouvé (Android)" -ForegroundColor Green
} else {
    Write-Host "   ❌ google-services.json non trouvé (Android)" -ForegroundColor Red
    Write-Host "      Emplacement attendu: $androidFile" -ForegroundColor Gray
    $errors++
}

if (Test-Path $iosFile) {
    Write-Host "   ✅ GoogleService-Info.plist trouvé (iOS)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  GoogleService-Info.plist non trouvé (iOS)" -ForegroundColor Yellow
    Write-Host "      Emplacement attendu: $iosFile" -ForegroundColor Gray
    Write-Host "      (Optionnel si vous ne développez pas pour iOS)" -ForegroundColor Gray
    $warnings++
}

Write-Host ""

# 2. Vérifier les dépendances dans pubspec.yaml
Write-Host "2. Vérification des dépendances..." -ForegroundColor Yellow

$pubspecContent = Get-Content "pubspec.yaml" -Raw

$requiredDeps = @(
    "firebase_core",
    "firebase_messaging",
    "flutter_local_notifications"
)

foreach ($dep in $requiredDeps) {
    if ($pubspecContent -match $dep) {
        Write-Host "   ✅ $dep trouvé" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $dep non trouvé" -ForegroundColor Red
        $errors++
    }
}

Write-Host ""

# 3. Vérifier la configuration Android
Write-Host "3. Vérification de la configuration Android..." -ForegroundColor Yellow

$buildGradleContent = Get-Content "android\app\build.gradle.kts" -Raw

if ($buildGradleContent -match "com.google.gms.google-services") {
    Write-Host "   ✅ Plugin Google Services configuré" -ForegroundColor Green
} else {
    Write-Host "   ❌ Plugin Google Services non trouvé" -ForegroundColor Red
    $errors++
}

if ($buildGradleContent -match "com.pouls.scolaire.parentresponsable") {
    Write-Host "   ✅ Package name correct" -ForegroundColor Green
} else {
    Write-Host "   ❌ Package name incorrect ou non trouvé" -ForegroundColor Red
    $errors++
}

Write-Host ""

# 4. Vérifier la configuration dans main.dart
Write-Host "4. Vérification de la configuration dans main.dart..." -ForegroundColor Yellow

$mainDartContent = Get-Content "lib\main.dart" -Raw

if ($mainDartContent -match "Firebase.initializeApp") {
    Write-Host "   ✅ Firebase initialisation trouvée" -ForegroundColor Green
} else {
    Write-Host "   ❌ Firebase initialisation non trouvée" -ForegroundColor Red
    $errors++
}

if ($mainDartContent -match "NotificationService") {
    Write-Host "   ✅ NotificationService trouvé" -ForegroundColor Green
} else {
    Write-Host "   ❌ NotificationService non trouvé" -ForegroundColor Red
    $errors++
}

Write-Host ""

# 5. Vérifier le service de notifications
Write-Host "5. Vérification du service de notifications..." -ForegroundColor Yellow

$notificationServiceFile = "lib\services\notification_service.dart"
if (Test-Path $notificationServiceFile) {
    Write-Host "   ✅ NotificationService existe" -ForegroundColor Green
    
    $notificationServiceContent = Get-Content $notificationServiceFile -Raw
    if ($notificationServiceContent -match "getToken") {
        Write-Host "   ✅ Méthode getToken trouvée" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Méthode getToken non trouvée" -ForegroundColor Red
        $errors++
    }
} else {
    Write-Host "   ❌ NotificationService non trouvé" -ForegroundColor Red
    $errors++
}

Write-Host ""

# Résumé
Write-Host "📋 Résumé:" -ForegroundColor Cyan
Write-Host "   Erreurs: $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
Write-Host "   Avertissements: $warnings" -ForegroundColor $(if ($warnings -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($errors -eq 0) {
    Write-Host "✅ Configuration de base correcte!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📝 Prochaines étapes:" -ForegroundColor Cyan
    Write-Host "   1. Exécutez: flutter pub get" -ForegroundColor White
    Write-Host "   2. Exécutez: flutter clean" -ForegroundColor White
    Write-Host "   3. Lancez l'application: flutter run" -ForegroundColor White
    Write-Host "   4. Vérifiez les logs pour le token FCM" -ForegroundColor White
    Write-Host "   5. Testez une notification depuis Firebase Console" -ForegroundColor White
} else {
    Write-Host "❌ Des erreurs ont été détectées. Veuillez les corriger avant de continuer." -ForegroundColor Red
}

Write-Host ""
Write-Host "📚 Consultez NEXT_STEPS_NOTIFICATIONS.md pour les étapes détaillées" -ForegroundColor Cyan

