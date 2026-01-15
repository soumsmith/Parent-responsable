# Script PowerShell pour lancer l'application Pouls École Parent

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Pouls École Parent - Lancement" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Vérifier si Flutter est installé
Write-Host "Vérification de Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Flutter est installé" -ForegroundColor Green
        Write-Host $flutterVersion[0] -ForegroundColor Gray
    } else {
        throw "Flutter non trouvé"
    }
} catch {
    Write-Host "✗ Flutter n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Pour installer Flutter :" -ForegroundColor Yellow
    Write-Host "1. Téléchargez Flutter depuis : https://flutter.dev/docs/get-started/install/windows" -ForegroundColor White
    Write-Host "2. Extrayez-le dans C:\src\flutter (ou un autre dossier)" -ForegroundColor White
    Write-Host "3. Ajoutez C:\src\flutter\bin au PATH Windows" -ForegroundColor White
    Write-Host "4. Redémarrez PowerShell" -ForegroundColor White
    Write-Host ""
    Write-Host "Voir INSTALLATION.md pour plus de détails" -ForegroundColor Cyan
    exit 1
}

Write-Host ""

# Vérifier les appareils disponibles
Write-Host "Vérification des appareils disponibles..." -ForegroundColor Yellow
$devices = flutter devices 2>&1
Write-Host $devices -ForegroundColor Gray
Write-Host ""

# Demander à l'utilisateur quel appareil utiliser
Write-Host "Choisissez une option :" -ForegroundColor Cyan
Write-Host "1. Chrome (recommandé pour tester rapidement)" -ForegroundColor White
Write-Host "2. Android (émulateur ou appareil physique)" -ForegroundColor White
Write-Host "3. Windows Desktop" -ForegroundColor White
Write-Host "4. Premier appareil disponible" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Votre choix (1-4)"

switch ($choice) {
    "1" {
        Write-Host "Lancement sur Chrome..." -ForegroundColor Green
        flutter run -d chrome
    }
    "2" {
        Write-Host "Lancement sur Android..." -ForegroundColor Green
        flutter run -d android
    }
    "3" {
        Write-Host "Lancement sur Windows..." -ForegroundColor Green
        flutter run -d windows
    }
    "4" {
        Write-Host "Lancement sur le premier appareil disponible..." -ForegroundColor Green
        flutter run
    }
    default {
        Write-Host "Choix invalide. Lancement par défaut..." -ForegroundColor Yellow
        flutter run
    }
}

Write-Host ""
Write-Host "Pour arrêter l'application, appuyez sur 'q' dans le terminal" -ForegroundColor Cyan

