# Guide de Configuration Firebase

## 📍 Emplacement du fichier google-services.json

### ✅ Emplacement correct

Le fichier `google-services.json` doit être placé dans :

```
android/app/google-services.json
```

**Chemin complet depuis la racine du projet :**
```
D:\MyProjet\IA\ParentResponsable\android\app\google-services.json
```

### 📋 Étapes pour obtenir le fichier

#### 1. Accéder à Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Connectez-vous avec votre compte Google
3. Sélectionnez votre projet (ou créez-en un nouveau)

#### 2. Ajouter une application Android

1. Dans le tableau de bord Firebase, cliquez sur l'icône **Android** (ou sur "Ajouter une application")
2. Remplissez le formulaire :
   - **Nom du package Android** : `com.pouls.scolaire.parentresponsable`
   - **Surnom de l'application** (optionnel) : `Pouls École Parent`
   - **Certificat de signature SHA-1** (optionnel pour le développement)
3. Cliquez sur **Enregistrer l'application**

#### 3. Télécharger le fichier google-services.json

1. Après l'enregistrement, Firebase vous proposera de télécharger le fichier `google-services.json`
2. **Téléchargez le fichier**
3. **Placez-le dans** : `android/app/google-services.json`

### 🔄 Remplacer le fichier d'exemple

Vous avez actuellement un fichier d'exemple :
- `android/app/google-services.json.example`

**Action à faire :**
1. Téléchargez le fichier réel depuis Firebase Console
2. **Renommez-le** en `google-services.json` (sans `.example`)
3. **Placez-le** dans `android/app/`
4. Le fichier d'exemple peut être supprimé ou conservé comme référence

### 📁 Structure des fichiers

```
android/
└── app/
    ├── build.gradle.kts          ← Plugin Google Services déjà configuré
    ├── google-services.json      ← ⭐ FICHIER À PLACER ICI
    ├── google-services.json.example  ← Fichier d'exemple (peut être supprimé)
    └── src/
        └── main/
            └── AndroidManifest.xml
```

### ✅ Vérification

Pour vérifier que le fichier est au bon endroit :

1. **Vérifiez l'emplacement :**
   ```
   android/app/google-services.json
   ```

2. **Vérifiez le contenu :**
   Le fichier doit contenir :
   ```json
   {
     "project_info": {
       "project_number": "...",
       "project_id": "...",
       "storage_bucket": "..."
     },
     "client": [
       {
         "client_info": {
           "mobilesdk_app_id": "...",
           "android_client_info": {
             "package_name": "com.pouls.scolaire.parentresponsable"
           }
         },
         ...
       }
     ],
     ...
   }
   ```

3. **Vérifiez le package name :**
   Dans le fichier `google-services.json`, le champ `package_name` doit être :
   ```json
   "package_name": "com.pouls.scolaire.parentresponsable"
   ```

### ⚠️ Important

1. **Ne commitez PAS le fichier `google-services.json`** dans Git si vous travaillez en équipe
   - Ajoutez-le au `.gitignore` :
     ```
     android/app/google-services.json
     ```
   - Chaque développeur doit télécharger son propre fichier depuis Firebase

2. **Le fichier est spécifique au projet Firebase**
   - Chaque projet Firebase a son propre `google-services.json`
   - Ne partagez pas le fichier entre différents projets

3. **Vérifiez que le plugin est activé**
   Le plugin Google Services est déjà configuré dans `android/app/build.gradle.kts` :
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

### 🧪 Test après installation

Après avoir placé le fichier :

1. **Nettoyez le projet :**
   ```bash
   flutter clean
   ```

2. **Récupérez les dépendances :**
   ```bash
   flutter pub get
   ```

3. **Compilez le projet :**
   ```bash
   flutter build apk
   ```

4. **Vérifiez les logs :**
   Si tout est correct, vous devriez voir dans les logs :
   ```
   ✅ Firebase initialisé avec succès
   ✅ Service de notifications initialisé
   ```

### 🔍 Résolution de problèmes

#### Erreur : "File google-services.json is missing"

**Solution :**
- Vérifiez que le fichier est bien dans `android/app/google-services.json`
- Vérifiez que le nom du fichier est exactement `google-services.json` (sans `.example`)

#### Erreur : "Package name mismatch"

**Solution :**
- Vérifiez que le `package_name` dans `google-services.json` correspond à `com.pouls.scolaire.parentresponsable`
- Vérifiez que `applicationId` dans `build.gradle.kts` correspond aussi

#### Erreur : "Plugin with id 'com.google.gms.google-services' not found"

**Solution :**
- Vérifiez que le plugin est bien déclaré dans `android/settings.gradle.kts`
- Vérifiez que la version est correcte (4.4.0)

### 📚 Ressources

- [Documentation Firebase Android](https://firebase.google.com/docs/android/setup)
- [Firebase Console](https://console.firebase.google.com/)
- [Guide de configuration Flutter Firebase](https://firebase.flutter.dev/docs/overview)

