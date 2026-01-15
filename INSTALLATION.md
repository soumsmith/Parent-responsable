# Guide d'installation détaillé - Pouls École Parent

## 🎯 Étape 1 : Installer Flutter

### Méthode 1 : Installation manuelle (Recommandée)

1. **Télécharger Flutter SDK** :
   - Visitez : https://docs.flutter.dev/get-started/install/windows
   - Cliquez sur "Download Flutter SDK"
   - Téléchargez le fichier ZIP (environ 1.5 GB)

2. **Extraire Flutter** :
   - Créez un dossier `C:\src` (ou un autre emplacement de votre choix)
   - Extrayez le contenu du ZIP dans `C:\src\flutter`
   - Le chemin final devrait être : `C:\src\flutter\bin\flutter.exe`

3. **Ajouter au PATH Windows** :
   
   **Méthode A : Via l'interface graphique**
   - Appuyez sur `Windows + X` et sélectionnez "Système"
   - Cliquez sur "Paramètres système avancés"
   - Cliquez sur "Variables d'environnement"
   - Dans "Variables système", sélectionnez "Path" et cliquez sur "Modifier"
   - Cliquez sur "Nouveau" et ajoutez : `C:\src\flutter\bin`
   - Cliquez sur "OK" pour fermer toutes les fenêtres
   
   **Méthode B : Via PowerShell (en tant qu'administrateur)**
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\src\flutter\bin", [EnvironmentVariableTarget]::Machine)
   ```

4. **Redémarrer PowerShell** :
   - Fermez complètement PowerShell
   - Rouvrez PowerShell en tant qu'administrateur

5. **Vérifier l'installation** :
   ```powershell
   flutter --version
   ```
   Vous devriez voir la version de Flutter affichée.

### Méthode 2 : Via Git (Alternative)

```powershell
# Installer Git si pas déjà installé
# Puis :
cd C:\src
git clone https://github.com/flutter/flutter.git -b stable
```

Puis ajoutez `C:\src\flutter\bin` au PATH comme indiqué ci-dessus.

## 🔧 Étape 2 : Installer les dépendances

1. **Vérifier l'état de Flutter** :
   ```powershell
   flutter doctor
   ```

2. **Installer Android Studio** (pour développer sur Android) :
   - Téléchargez depuis : https://developer.android.com/studio
   - Installez Android Studio
   - Ouvrez Android Studio et installez le SDK Android
   - Acceptez les licences :
     ```powershell
     flutter doctor --android-licenses
     ```

3. **Installer Visual Studio** (pour Windows desktop) :
   - Téléchargez Visual Studio Community depuis : https://visualstudio.microsoft.com/
   - Lors de l'installation, cochez "Développement Desktop en C++"

4. **Vérifier à nouveau** :
   ```powershell
   flutter doctor -v
   ```
   Tous les éléments devraient être marqués avec ✓

## 📦 Étape 3 : Préparer le projet

1. **Ouvrir PowerShell dans le dossier du projet** :
   ```powershell
   cd D:\MyProjet\IA\ParentResponsable
   ```

2. **Initialiser la structure Flutter** (si nécessaire) :
   ```powershell
   flutter create .
   ```
   ⚠️ Si vous avez déjà des fichiers, Flutter vous demandera confirmation. Répondez `y`.

3. **Installer les dépendances du projet** :
   ```powershell
   flutter pub get
   ```

## ▶️ Étape 4 : Lancer l'application

### Vérifier les appareils disponibles :
```powershell
flutter devices
```

### Options de lancement :

**1. Sur Chrome (le plus simple pour tester)** :
```powershell
flutter run -d chrome
```

**2. Sur un émulateur Android** :
- Démarrez un émulateur depuis Android Studio
- Puis :
```powershell
flutter run
```

**3. Sur un appareil Android physique** :
- Activez le mode développeur et le débogage USB
- Connectez votre téléphone
- Puis :
```powershell
flutter run
```

**4. Sur Windows Desktop** :
```powershell
flutter run -d windows
```

## 🔑 Connexion à l'application

Une fois l'application lancée, utilisez :
- **Email** : `parent@test.com` (ou n'importe quel email)
- **Mot de passe** : `123456` (ou n'importe quel mot de passe de 4+ caractères)

## ❓ Résolution de problèmes

### Flutter n'est toujours pas reconnu après l'ajout au PATH

1. **Vérifiez le chemin** :
   ```powershell
   Test-Path C:\src\flutter\bin\flutter.exe
   ```
   Doit retourner `True`

2. **Redémarrez complètement PowerShell** (fermez toutes les fenêtres)

3. **Vérifiez le PATH dans PowerShell** :
   ```powershell
   $env:Path -split ';' | Select-String flutter
   ```

4. **Si toujours pas trouvé, utilisez le chemin complet** :
   ```powershell
   C:\src\flutter\bin\flutter.exe --version
   ```

### Erreur "No devices found"

- Pour Chrome : Installez Chrome
- Pour Android : Démarrez un émulateur ou connectez un appareil
- Pour Windows : Installez Visual Studio avec "Développement Desktop en C++"

### Erreur lors de `flutter pub get`

```powershell
flutter clean
flutter pub get
```

## 📚 Ressources utiles

- Documentation Flutter : https://flutter.dev/docs
- Guide d'installation Windows : https://docs.flutter.dev/get-started/install/windows
- Communauté Flutter : https://flutter.dev/community

