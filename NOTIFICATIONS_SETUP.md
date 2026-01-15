# Configuration des Notifications Push

Ce document explique comment configurer le système de notifications push pour l'application Pouls École Parent.

## 📋 Prérequis

1. Un projet Firebase configuré
2. Les fichiers de configuration Firebase :
   - `google-services.json` pour Android
   - `GoogleService-Info.plist` pour iOS

## 🔧 Configuration Firebase

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Ajoutez une application Android :
   - Package name: `com.pouls.scolaire.parentresponsable`
   - Téléchargez le fichier `google-services.json`
4. Ajoutez une application iOS (si nécessaire) :
   - Bundle ID: votre bundle ID iOS
   - Téléchargez le fichier `GoogleService-Info.plist`

### 2. Configuration Android

#### Étape 1 : Ajouter le fichier google-services.json

1. Placez le fichier `google-services.json` dans `android/app/`
2. Le fichier doit être à cet emplacement : `android/app/google-services.json`

#### Étape 2 : Mettre à jour build.gradle

Ajoutez le plugin Google Services dans `android/build.gradle.kts` :

```kotlin
buildscript {
    dependencies {
        // ... autres dépendances
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

Ajoutez le plugin dans `android/app/build.gradle.kts` :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Ajoutez cette ligne
}
```

### 3. Configuration iOS (si nécessaire)

1. Placez le fichier `GoogleService-Info.plist` dans `ios/Runner/`
2. Ouvrez `ios/Runner.xcworkspace` dans Xcode
3. Ajoutez le fichier `GoogleService-Info.plist` au projet

## 🚀 Utilisation

### Enregistrement automatique

Le service de notifications s'initialise automatiquement au démarrage de l'application dans `main.dart`. Le token FCM est automatiquement :
- Récupéré
- Sauvegardé localement
- Enregistré auprès du backend via l'API

### API Backend

Le backend doit implémenter les endpoints suivants :

#### Enregistrer un token

```
POST /api/notifications/register-token
Content-Type: application/json

{
  "token": "fcm_token_here",
  "userId": "user_id_here",
  "deviceType": "android" | "ios"
}
```

#### Supprimer un token

```
DELETE /api/notifications/unregister-token
Content-Type: application/json

{
  "token": "fcm_token_here",
  "userId": "user_id_here"
}
```

### Envoyer une notification depuis le backend

Pour envoyer une notification depuis votre application web, utilisez l'API Firebase Cloud Messaging :

```javascript
// Exemple avec Node.js et firebase-admin
const admin = require('firebase-admin');
const message = {
  notification: {
    title: 'Nouvelle note',
    body: 'Une nouvelle note a été ajoutée pour votre enfant',
  },
  data: {
    type: 'note_added',
    childId: 'child_id_here',
    noteId: 'note_id_here',
  },
  token: 'fcm_token_here', // Token enregistré dans votre base de données
};

admin.messaging().send(message)
  .then((response) => {
    console.log('Notification envoyée:', response);
  })
  .catch((error) => {
    console.error('Erreur:', error);
  });
```

### Types de notifications

Les types de notifications supportés sont définis dans `lib/models/notification.dart` :

- `note_added` : Nouvelle note ajoutée
- `note_updated` : Note mise à jour
- `message_received` : Nouveau message reçu
- `fee_added` : Nouvelle facture ajoutée
- `timetable_updated` : Emploi du temps mis à jour
- `general` : Notification générale

## 📱 Gestion des notifications dans l'application

### Écouter les notifications

L'application écoute automatiquement les notifications via le `NotificationService`. Les notifications sont affichées :
- En foreground : Snackbar avec action "Voir"
- En background : Notification système
- Au démarrage : Si l'app a été ouverte depuis une notification

### Navigation automatique

L'application navigue automatiquement vers l'écran approprié selon le type de notification :
- `note_added` / `note_updated` → Écran des notes
- `message_received` → Écran des messages
- `fee_added` → Écran des frais

## 🔍 Débogage

### Vérifier le token FCM

Le token FCM est loggé dans la console lors de l'initialisation :
```
🔑 Token FCM obtenu: [token]
```

### Vérifier l'enregistrement

L'enregistrement du token est loggé :
```
📤 Enregistrement du token pour l'utilisateur: [user_id]
✅ Token de notification enregistré avec succès
```

### Tester les notifications

Vous pouvez tester les notifications en utilisant l'outil Firebase Console :
1. Allez dans Firebase Console → Cloud Messaging
2. Créez une nouvelle notification
3. Sélectionnez "Single device" et entrez le token FCM
4. Envoyez la notification

## ⚠️ Notes importantes

1. **Permissions** : Les permissions pour les notifications sont demandées automatiquement au premier lancement
2. **Token refresh** : Le token FCM peut changer. L'application gère automatiquement le rafraîchissement
3. **Background** : Les notifications en background nécessitent le handler `firebaseMessagingBackgroundHandler` (déjà configuré)
4. **iOS** : Pour iOS, vous devez également configurer les capacités Push Notifications dans Xcode

## 🐛 Résolution de problèmes

### Le token n'est pas enregistré

- Vérifiez que l'utilisateur est connecté
- Vérifiez les logs pour les erreurs API
- Vérifiez que l'endpoint `/api/notifications/register-token` existe et fonctionne

### Les notifications ne s'affichent pas

- Vérifiez que les permissions sont accordées
- Vérifiez que Firebase est correctement configuré
- Vérifiez les logs pour les erreurs

### Erreur "Firebase not initialized"

- Vérifiez que `google-services.json` est présent dans `android/app/`
- Vérifiez que le plugin Google Services est ajouté dans `build.gradle.kts`
- Exécutez `flutter clean` et `flutter pub get`

