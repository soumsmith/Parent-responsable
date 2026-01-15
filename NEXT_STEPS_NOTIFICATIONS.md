# Prochaines Étapes - Configuration des Notifications

Vous avez déjà placé les fichiers Google Services. Voici les étapes suivantes pour finaliser la configuration.

## ✅ Vérification préalable

Assurez-vous que les fichiers suivants sont bien placés :

- ✅ `android/app/google-services.json` - Fichier Android
- ✅ `ios/Runner/GoogleService-Info.plist` - Fichier iOS (si vous développez pour iOS)

## 📋 Étapes de configuration

### Étape 1 : Installer les dépendances Flutter

```bash
flutter pub get
```

Cette commande installe toutes les dépendances Firebase et de notifications.

### Étape 2 : Configuration iOS (si vous développez pour iOS)

Si vous développez pour iOS, installez les pods CocoaPods :

```bash
cd ios
pod install
cd ..
```

⚠️ **Important** : Si vous rencontrez des erreurs, essayez :
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Étape 3 : Nettoyer et reconstruire le projet

```bash
flutter clean
flutter pub get
```

### Étape 4 : Vérifier la configuration Android

Vérifiez que le plugin Google Services est bien configuré dans `android/app/build.gradle.kts` :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ← Doit être présent
}
```

### Étape 5 : Lancer l'application et vérifier les logs

Lancez l'application :

```bash
flutter run
```

**Vérifiez dans les logs** que vous voyez :

```
✅ Firebase initialisé
✅ Service de notifications initialisé
🔔 Permission de notification: AuthorizationStatus.authorized
✅ Notifications autorisées
🔑 Token FCM obtenu: [votre_token_ici]
📤 Enregistrement du token pour l'utilisateur: [user_id]
```

### Étape 6 : Vérifier l'obtention du token FCM

Le token FCM est automatiquement :
1. ✅ Récupéré au démarrage de l'application
2. ✅ Sauvegardé localement dans SharedPreferences
3. ✅ Enregistré auprès du backend (si l'utilisateur est connecté)

**Pour voir le token dans les logs**, cherchez :
```
🔑 Token FCM obtenu: [token_long_ici]
```

### Étape 7 : Tester l'envoi de notification depuis Firebase Console

#### 7.1. Accéder à Firebase Console

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Allez dans **Cloud Messaging** (dans le menu de gauche)

#### 7.2. Envoyer une notification de test

1. Cliquez sur **"Envoyer votre premier message"** ou **"Nouvelle campagne"**
2. Remplissez le formulaire :
   - **Titre** : `Test de notification`
   - **Texte** : `Ceci est un test de notification`
3. Cliquez sur **"Suivant"**
4. Sélectionnez **"Cible unique"** (Single device)
5. **Collez le token FCM** que vous avez vu dans les logs
6. Cliquez sur **"Tester"** ou **"Envoyer"**

#### 7.3. Vérifier la réception

- Si l'application est **en foreground** : Vous devriez voir un Snackbar
- Si l'application est **en background** : Vous devriez voir une notification système
- Si l'application est **fermée** : Vous devriez voir une notification système

### Étape 8 : Configurer le backend Quarkus

Maintenant que l'application mobile est configurée, vous devez configurer votre backend Quarkus pour envoyer des notifications.

#### 8.1. Implémenter les endpoints dans Quarkus

Consultez le fichier `QUARKUS_NOTIFICATIONS.md` pour :
- Ajouter les dépendances Firebase Admin SDK
- Créer le service Firebase
- Créer les endpoints REST pour enregistrer/supprimer les tokens
- Créer les endpoints pour envoyer des notifications

#### 8.2. Endpoints à implémenter

1. **Enregistrer un token** :
   ```
   POST /api/notifications/register-token
   Body: {
     "token": "fcm_token_here",
     "userId": "user_id",
     "deviceType": "android"
   }
   ```

2. **Supprimer un token** :
   ```
   DELETE /api/notifications/unregister-token
   Body: {
     "token": "fcm_token_here",
     "userId": "user_id"
   }
   ```

3. **Envoyer une notification** :
   ```
   POST /api/notifications/send
   Body: {
     "token": "fcm_token_here",
     "title": "Titre",
     "body": "Corps du message",
     "data": {
       "type": "note_added",
       "childId": "child_id"
     }
   }
   ```

### Étape 9 : Tester l'intégration complète

#### 9.1. Tester l'enregistrement du token

1. Lancez l'application mobile
2. Connectez-vous avec un utilisateur
3. Vérifiez dans les logs du backend que le token est bien enregistré :
   ```
   ✅ Token de notification enregistré avec succès
   ```

#### 9.2. Tester l'envoi depuis le backend

1. Utilisez votre API Quarkus pour envoyer une notification
2. Vérifiez que la notification arrive sur l'appareil mobile

#### 9.3. Tester les différents types de notifications

Testez les différents types de notifications :
- `note_added` - Nouvelle note
- `message_received` - Nouveau message
- `fee_added` - Nouvelle facture
- `timetable_updated` - Emploi du temps mis à jour

### Étape 10 : Gérer les notifications dans l'application

L'application gère automatiquement :
- ✅ Affichage des notifications en foreground (Snackbar)
- ✅ Affichage des notifications en background (Notification système)
- ✅ Navigation automatique selon le type de notification
- ✅ Gestion du rafraîchissement du token

## 🔍 Vérification et débogage

### Vérifier que Firebase est bien initialisé

Dans les logs de l'application, vous devriez voir :
```
✅ Firebase initialisé
✅ Service de notifications initialisé
```

Si vous ne voyez pas ces messages, vérifiez :
1. Les fichiers Google Services sont bien placés
2. Les dépendances sont installées (`flutter pub get`)
3. Le projet est nettoyé et reconstruit (`flutter clean`)

### Vérifier que le token est obtenu

Cherchez dans les logs :
```
🔑 Token FCM obtenu: [token]
```

Si le token n'apparaît pas :
1. Vérifiez que les permissions sont accordées
2. Vérifiez la connexion Internet
3. Vérifiez que Firebase est bien initialisé

### Vérifier que le token est enregistré dans le backend

Vérifiez dans les logs du backend Quarkus :
```
📤 Enregistrement du token pour l'utilisateur: [user_id]
✅ Token de notification enregistré avec succès
```

Si le token n'est pas enregistré :
1. Vérifiez que l'utilisateur est connecté
2. Vérifiez que l'endpoint `/api/notifications/register-token` existe
3. Vérifiez les logs d'erreur dans l'application mobile

### Erreurs courantes

#### Erreur : "Firebase not initialized"

**Solution :**
- Vérifiez que `google-services.json` est dans `android/app/`
- Vérifiez que le plugin Google Services est dans `build.gradle.kts`
- Exécutez `flutter clean` et `flutter pub get`

#### Erreur : "Package name mismatch"

**Solution :**
- Vérifiez que le `package_name` dans `google-services.json` correspond à `com.pouls.scolaire.parentresponsable`
- Vérifiez que `applicationId` dans `build.gradle.kts` correspond aussi

#### Erreur : "Token not obtained"

**Solution :**
- Vérifiez que les permissions sont accordées
- Vérifiez la connexion Internet
- Vérifiez que Firebase est bien initialisé

#### Erreur : "Notification not received"

**Solution :**
- Vérifiez que le token est correct
- Vérifiez que l'application a les permissions de notification
- Vérifiez que le backend envoie bien la notification

## 📚 Ressources

- `QUARKUS_NOTIFICATIONS.md` - Guide complet pour configurer le backend Quarkus
- `NOTIFICATIONS_SETUP.md` - Guide de configuration initiale
- `FIREBASE_SETUP_GUIDE.md` - Guide de configuration Firebase
- `IOS_FIREBASE_SETUP.md` - Guide spécifique pour iOS

## ✅ Checklist finale

Avant de considérer la configuration comme terminée, vérifiez :

- [ ] Les fichiers Google Services sont placés
- [ ] Les dépendances sont installées (`flutter pub get`)
- [ ] Le projet est nettoyé et reconstruit (`flutter clean`)
- [ ] Firebase est initialisé (logs : "✅ Firebase initialisé")
- [ ] Le token FCM est obtenu (logs : "🔑 Token FCM obtenu")
- [ ] Les permissions sont accordées (logs : "✅ Notifications autorisées")
- [ ] Le token est enregistré dans le backend
- [ ] Une notification de test depuis Firebase Console fonctionne
- [ ] Le backend Quarkus est configuré (voir `QUARKUS_NOTIFICATIONS.md`)
- [ ] L'envoi depuis le backend fonctionne

Une fois toutes ces étapes complétées, votre système de notifications est opérationnel ! 🎉

