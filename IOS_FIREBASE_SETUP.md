# Configuration Firebase pour iOS

## 📍 Emplacement du fichier GoogleService-Info.plist

### ✅ Emplacement correct

Le fichier `GoogleService-Info.plist` doit être placé dans :

```
ios/Runner/GoogleService-Info.plist
```

**Chemin complet depuis la racine du projet :**
```
D:\MyProjet\IA\ParentResponsable\ios\Runner\GoogleService-Info.plist
```

### 📋 Étapes détaillées

#### 1. Obtenir le fichier depuis Firebase Console

1. **Accéder à Firebase Console**
   - Allez sur [Firebase Console](https://console.firebase.google.com/)
   - Connectez-vous avec votre compte Google
   - Sélectionnez votre projet (ou créez-en un nouveau)

2. **Ajouter une application iOS**
   - Dans le tableau de bord Firebase, cliquez sur l'icône **iOS** (ou sur "Ajouter une application")
   - Remplissez le formulaire :
     - **Bundle ID** : `com.pouls.scolaire.parentresponsable` (ou votre Bundle ID iOS)
     - **Surnom de l'application** (optionnel) : `Pouls École Parent`
     - **App Store ID** (optionnel) : Laissez vide si l'app n'est pas encore publiée
   - Cliquez sur **Enregistrer l'application**

3. **Télécharger le fichier**
   - Après l'enregistrement, Firebase vous proposera de télécharger le fichier `GoogleService-Info.plist`
   - **Téléchargez le fichier**
   - **Placez-le dans** : `ios/Runner/GoogleService-Info.plist`

#### 2. Ajouter le fichier au projet Xcode

⚠️ **Important** : Utilisez toujours le fichier `.xcworkspace`, pas `.xcodeproj`

1. **Ouvrir le projet dans Xcode**
   ```bash
   # Depuis la racine du projet
   open ios/Runner.xcworkspace
   ```
   Ou double-cliquez sur `ios/Runner.xcworkspace` dans Finder

2. **Ajouter le fichier au projet**
   - Dans Xcode, faites un clic droit sur le dossier `Runner` dans le navigateur de projet
   - Sélectionnez **"Add Files to Runner..."**
   - Naviguez vers `ios/Runner/GoogleService-Info.plist`
   - **Cochez** "Copy items if needed" (si le fichier n'est pas déjà dans le dossier)
   - **Sélectionnez** le target "Runner"
   - Cliquez sur **"Add"**

   **OU** simplement faites glisser le fichier depuis Finder vers le dossier `Runner` dans Xcode

3. **Vérifier l'ajout**
   - Le fichier `GoogleService-Info.plist` doit apparaître dans le navigateur de projet Xcode
   - Il doit être dans le dossier `Runner` (au même niveau que `Info.plist`)

### 📁 Structure des fichiers

```
ios/
├── Runner/
│   ├── AppDelegate.swift
│   ├── Info.plist
│   ├── GoogleService-Info.plist      ← ⭐ FICHIER À PLACER ICI
│   ├── Assets.xcassets/
│   └── Base.lproj/
├── Runner.xcodeproj/
└── Runner.xcworkspace/                ← ⚠️ Ouvrir ce fichier dans Xcode
```

### ✅ Vérification

Pour vérifier que le fichier est correctement configuré :

1. **Vérifiez l'emplacement :**
   ```
   ios/Runner/GoogleService-Info.plist
   ```

2. **Vérifiez le contenu :**
   Le fichier doit être un fichier XML (plist) contenant :
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>CLIENT_ID</key>
       <string>...</string>
       <key>BUNDLE_ID</key>
       <string>com.pouls.scolaire.parentresponsable</string>
       ...
   </dict>
   </plist>
   ```

3. **Vérifiez le Bundle ID :**
   Dans le fichier, le champ `BUNDLE_ID` doit correspondre à votre Bundle ID iOS

4. **Vérifiez dans Xcode :**
   - Le fichier doit apparaître dans le navigateur de projet
   - Il doit être inclus dans le target "Runner"

### ⚠️ Important

1. **Ne commitez PAS le fichier `GoogleService-Info.plist`** dans Git si vous travaillez en équipe
   - Le fichier est déjà ajouté au `.gitignore` :
     ```
     /ios/Runner/GoogleService-Info.plist
     ```
   - Chaque développeur doit télécharger son propre fichier depuis Firebase

2. **Le fichier est spécifique au projet Firebase**
   - Chaque projet Firebase a son propre `GoogleService-Info.plist`
   - Ne partagez pas le fichier entre différents projets

3. **Utilisez toujours `.xcworkspace`**
   - ⚠️ **Important** : Ouvrez toujours `Runner.xcworkspace`, pas `Runner.xcodeproj`
   - Le fichier `.xcworkspace` inclut les dépendances CocoaPods nécessaires

### 🧪 Test après installation

Après avoir ajouté le fichier :

1. **Nettoyez le projet :**
   ```bash
   flutter clean
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

2. **Récupérez les dépendances :**
   ```bash
   flutter pub get
   ```

3. **Compilez le projet :**
   ```bash
   flutter build ios
   ```

4. **Vérifiez les logs :**
   Si tout est correct, vous devriez voir dans les logs :
   ```
   ✅ Firebase initialisé avec succès
   ✅ Service de notifications initialisé
   ```

### 🔍 Résolution de problèmes

#### Erreur : "GoogleService-Info.plist not found"

**Solution :**
- Vérifiez que le fichier est bien dans `ios/Runner/GoogleService-Info.plist`
- Vérifiez que le fichier est ajouté au projet Xcode
- Vérifiez que le fichier est inclus dans le target "Runner"

#### Erreur : "Bundle ID mismatch"

**Solution :**
- Vérifiez que le `BUNDLE_ID` dans `GoogleService-Info.plist` correspond à votre Bundle ID
- Vérifiez le Bundle ID dans Xcode : Target Runner → General → Bundle Identifier

#### Erreur : "CocoaPods not installed"

**Solution :**
- Installez CocoaPods :
  ```bash
  sudo gem install cocoapods
  ```
- Installez les pods :
  ```bash
  cd ios
  pod install
  cd ..
  ```

#### Erreur lors de l'ouverture du projet

**Solution :**
- Assurez-vous d'ouvrir `Runner.xcworkspace`, pas `Runner.xcodeproj`
- Si vous avez ouvert `.xcodeproj`, fermez Xcode et rouvrez `.xcworkspace`

### 📚 Ressources

- [Documentation Firebase iOS](https://firebase.google.com/docs/ios/setup)
- [Firebase Console](https://console.firebase.google.com/)
- [Guide de configuration Flutter Firebase](https://firebase.flutter.dev/docs/overview)

### 🔗 Voir aussi

- `FIREBASE_SETUP_GUIDE.md` - Guide complet pour Android et iOS
- `NOTIFICATIONS_SETUP.md` - Configuration des notifications

