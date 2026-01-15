# Pouls École Parent

Application mobile Flutter pour le suivi scolaire des parents.

## 📋 Prérequis

### Installation de Flutter (Windows)

1. **Télécharger Flutter** :
   - Allez sur https://flutter.dev/docs/get-started/install/windows
   - Téléchargez le SDK Flutter (fichier ZIP)
   - Extrayez-le dans un dossier (ex: `C:\src\flutter`)

2. **Ajouter Flutter au PATH** :
   - Appuyez sur `Windows + R`, tapez `sysdm.cpl` et appuyez sur Entrée
   - Allez dans l'onglet "Avancé" → "Variables d'environnement"
   - Dans "Variables système", trouvez "Path" et cliquez sur "Modifier"
   - Cliquez sur "Nouveau" et ajoutez : `C:\src\flutter\bin` (ou votre chemin)
   - Cliquez sur "OK" pour fermer toutes les fenêtres

3. **Redémarrer PowerShell** :
   - Fermez et rouvrez PowerShell (ou redémarrez votre ordinateur)

4. **Vérifier l'installation** :
   ```powershell
   flutter doctor
   ```
   Cette commande vérifie que tout est correctement installé.

5. **Installer les dépendances manquantes** :
   - Si `flutter doctor` indique des problèmes, suivez les instructions affichées
   - Vous devrez probablement installer :
     - Android Studio (pour Android)
     - Visual Studio (pour Windows desktop)
     - Chrome (pour le web)

## 🚀 Installation du projet

1. **Ouvrir PowerShell dans le dossier du projet** :
   ```powershell
   cd D:\MyProjet\IA\ParentResponsable
   ```

2. **Initialiser la structure Flutter** (si pas déjà fait) :
   ```powershell
   flutter create .
   ```

3. **Installer les dépendances** :
   ```powershell
   flutter pub get
   ```

## ▶️ Lancement de l'application

### Option 1 : Sur un émulateur Android

1. **Démarrer un émulateur** :
   - Ouvrez Android Studio
   - Allez dans "Device Manager"
   - Créez ou démarrez un émulateur Android

2. **Vérifier les appareils disponibles** :
   ```powershell
   flutter devices
   ```

3. **Lancer l'application** :
   ```powershell
   flutter run
   ```

### Option 2 : Sur Chrome (pour tester rapidement)

```powershell
flutter run -d chrome
```

### Option 3 : Sur un appareil physique Android

1. **Activer le mode développeur** sur votre téléphone
2. **Activer le débogage USB**
3. **Connecter le téléphone** via USB
4. **Vérifier la connexion** :
   ```powershell
   flutter devices
   ```
5. **Lancer l'application** :
   ```powershell
   flutter run
   ```

### Option 4 : Sur Windows Desktop

```powershell
flutter run -d windows
```

## Connexion

Pour vous connecter, utilisez :
- **Email** : `parent@test.com` (ou n'importe quel email)
- **Mot de passe** : `123456` (ou n'importe quel mot de passe de 4+ caractères)

## Mode Mock

L'application est actuellement en mode MOCK (données statiques). Pour passer en mode production, modifiez `lib/config/app_config.dart` :

```dart
static const bool MOCK_MODE = false;
```

Et implémentez `RemoteApiService` dans `lib/services/remote_api_service.dart`.

## Structure

- `lib/models/` : Modèles de données
- `lib/services/` : Services (API, Auth)
- `lib/screens/` : Écrans de l'application
- `lib/widgets/` : Widgets réutilisables
- `lib/config/` : Configuration

