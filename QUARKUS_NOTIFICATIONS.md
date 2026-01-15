# Envoi de Notifications depuis Quarkus

Ce guide explique comment intégrer Firebase Cloud Messaging (FCM) dans votre API Quarkus pour envoyer des notifications push aux applications mobiles.

## 📋 Prérequis

1. Un projet Firebase configuré
2. Le fichier de clé de service Firebase (JSON)
3. Quarkus 3.x ou supérieur

## 🔧 Configuration

### 1. Ajouter les dépendances

Ajoutez les dépendances suivantes dans votre `pom.xml` (Maven) ou `build.gradle` (Gradle) :

#### Maven (`pom.xml`)

```xml
<dependencies>
    <!-- Firebase Admin SDK -->
    <dependency>
        <groupId>com.google.firebase</groupId>
        <artifactId>firebase-admin</artifactId>
        <version>9.2.0</version>
    </dependency>
    
    <!-- JSON Processing (si pas déjà présent) -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-jsonb</artifactId>
    </dependency>
    
    <!-- RESTEasy Reactive (déjà présent normalement) -->
    <dependency>
        <groupId>io.quarkus</groupId>
        <artifactId>quarkus-resteasy-reactive</artifactId>
    </dependency>
</dependencies>
```

#### Gradle (`build.gradle`)

```gradle
dependencies {
    implementation 'com.google.firebase:firebase-admin:9.2.0'
    implementation 'io.quarkus:quarkus-jsonb'
    implementation 'io.quarkus:quarkus-resteasy-reactive'
}
```

### 2. Configuration Firebase

#### Étape 1 : Télécharger la clé de service

1. Allez dans [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Allez dans **Paramètres du projet** → **Comptes de service**
4. Cliquez sur **Générer une nouvelle clé privée**
5. Téléchargez le fichier JSON (ex: `firebase-service-account.json`)

#### Étape 2 : Placer le fichier dans le projet

Placez le fichier JSON dans `src/main/resources/firebase-service-account.json`

⚠️ **Important** : Ajoutez ce fichier à `.gitignore` pour ne pas le commiter !

```gitignore
# Firebase
src/main/resources/firebase-service-account.json
```

#### Étape 3 : Obtenir l'ID du projet Firebase

L'ID du projet Firebase (`project-id`) peut être obtenu de plusieurs façons :

**Méthode 1 : Depuis la Console Firebase**
1. Allez dans [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet
3. Allez dans **Paramètres du projet** (icône ⚙️ en haut à gauche)
4. L'**ID du projet** est affiché dans la section "Informations générales"

**Méthode 2 : Depuis le fichier JSON de clé de service**
1. Ouvrez le fichier `firebase-service-account.json` que vous avez téléchargé
2. Cherchez le champ `"project_id"` dans le JSON
3. La valeur de ce champ est votre `project-id`

Exemple de contenu du fichier JSON :
```json
{
  "type": "service_account",
  "project_id": "mon-projet-firebase-12345",
  "private_key_id": "...",
  "private_key": "...",
  ...
}
```

Dans cet exemple, `mon-projet-firebase-12345` est votre `project-id`.

**Méthode 3 : Depuis l'URL de la console**
L'ID du projet apparaît également dans l'URL de la console Firebase :
```
https://console.firebase.google.com/project/VOTRE-PROJECT-ID/...
```

### 3. Configuration Quarkus

Ajoutez la configuration dans `application.properties` :

```properties
# Firebase Configuration
firebase.service-account.path=firebase-service-account.json
firebase.project-id=your-project-id

# Configuration Hibernate/JPA pour le naming strategy
# Assurez-vous que les noms de colonnes sont correctement mappés
quarkus.hibernate-orm.physical-naming-strategy=org.hibernate.boot.model.naming.PhysicalNamingStrategyStandardImpl
quarkus.hibernate-orm.implicit-naming-strategy=org.hibernate.boot.model.naming.ImplicitNamingStrategyLegacyJpaImpl
```

⚠️ **Remplacez `your-project-id`** par l'ID réel de votre projet Firebase obtenu via l'une des méthodes ci-dessus.

**Note importante** : Si vous rencontrez l'erreur `Unknown column 'createdAt' in 'field list'`, cela signifie que les noms de colonnes ne sont pas correctement mappés. Les entités Java utilisent explicitement `@Column(name = "created_at")` pour mapper vers les colonnes SQL en snake_case. Assurez-vous que :
1. Les scripts SQL ont été exécutés avec les noms de colonnes en snake_case (`created_at`, `updated_at`, etc.)
2. Les entités Java utilisent les annotations `@Column(name = "...")` avec les bons noms

### 4. Dépannage - Erreur 404 sur `/batch`

Si vous rencontrez une erreur 404 avec le message `"The requested URL /batch was not found on this server"`, cela indique un problème avec la configuration Firebase ou les tokens. Voici les étapes de dépannage :

**Vérifications à effectuer :**

1. **Vérifier le Project ID Firebase** :
   - Assurez-vous que `firebase.project-id` dans `application.properties` correspond exactement au `project_id` dans votre fichier `firebase-service-account.json`
   - Vérifiez les logs au démarrage de l'application pour confirmer que le Project ID est correctement chargé

2. **Vérifier le fichier de service account** :
   - Le fichier doit être dans `src/main/resources/firebase-service-account.json`
   - Vérifiez que le fichier n'est pas corrompu et contient bien les clés `project_id`, `private_key`, et `client_email`
   - Assurez-vous que le fichier JSON est valide (pas de caractères spéciaux mal échappés)

3. **Vérifier que des tokens sont associés au matricule** :
   - Utilisez l'endpoint `GET /api/notifications/tokens-by-matricule/{matricule}` pour vérifier
   - Si aucun token n'est retourné, assurez-vous que des tokens ont été enregistrés avec ce matricule via `POST /api/notifications/register-token`

4. **Vérifier la validité des tokens** :
   - Les tokens FCM peuvent expirer ou devenir invalides
   - Si un token est invalide, Firebase retournera une erreur 404
   - Les tokens invalides seront automatiquement filtrés dans les logs

5. **Vérifier les logs de l'application** :
   - Recherchez les messages d'erreur détaillés dans les logs
   - Les logs indiqueront si Firebase est correctement initialisé
   - Les logs montreront combien de tokens sont valides avant l'envoi

### 4.1. Dépannage - Erreur `FIREBASE_NOT_INITIALIZED`

Si vous rencontrez l'erreur `FIREBASE_NOT_INITIALIZED`, cela signifie que Firebase n'a pas pu être initialisé au démarrage de l'application. Voici les étapes de dépannage :

**Vérifications à effectuer :**

1. **Vérifier que le fichier service account existe** :
   - Le fichier `firebase-service-account.json` doit être dans `src/main/resources/`
   - Vérifiez que le nom du fichier correspond à `firebase.service-account.path` dans `application.properties`
   - Le fichier doit être un JSON valide contenant `project_id`, `private_key`, et `client_email`

2. **Vérifier les logs au démarrage de l'application** :
   - Recherchez les messages `🔧 Début de l'initialisation Firebase...`
   - Recherchez les messages `✅ Firebase initialisé avec succès - Project ID: ...`
   - Si vous voyez `❌ Erreur lors de l'initialisation de Firebase`, lisez le message d'erreur détaillé
   - Les logs indiqueront le chemin du fichier recherché et la cause de l'échec

3. **Vérifier la configuration dans `application.properties`** :
   ```properties
   # Vérifiez que ces lignes existent et sont correctes
   firebase.service-account.path=firebase-service-account.json
   firebase.project-id=votre-project-id
   ```

4. **Vérifier que le fichier n'est pas dans `.gitignore`** :
   - Si le fichier est ignoré par Git, assurez-vous qu'il est présent sur le serveur de production
   - Vérifiez que le fichier n'est pas vide ou corrompu

5. **Tester l'initialisation manuellement** :
   - Redémarrez l'application Quarkus
   - Consultez les logs au démarrage pour voir si Firebase s'initialise correctement
   - Si l'initialisation échoue, le service tentera automatiquement de réinitialiser Firebase lors de la première utilisation d'un endpoint de notification

**Solution rapide :**
```bash
# 1. Vérifier que des tokens existent pour le matricule
curl -X GET "http://localhost:8080/api/notifications/tokens-by-matricule/20440504X"

# 2. Si aucun token, enregistrer un nouveau token avec le matricule
curl -X POST http://localhost:8080/api/notifications/register-token \
  -H "Content-Type: application/json" \
  -d '{
    "token": "VOTRE_TOKEN_FCM",
    "userId": "USER_ID",
    "deviceType": "android",
    "matricules": ["20440504X"]
  }'
```

## 💻 Implémentation

### 1. Service Firebase

Créez un service pour gérer Firebase :

```java
package com.pouls.ecole.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

import java.io.InputStream;

@ApplicationScoped
public class FirebaseService {
    
    private static final Logger LOG = Logger.getLogger(FirebaseService.class);
    
    @ConfigProperty(name = "firebase.service-account.path")
    String serviceAccountPath;
    
    @PostConstruct
    void init() {
        try {
            LOG.infof("🔧 Début de l'initialisation Firebase...");
            LOG.infof("   Chemin du fichier service account: %s", serviceAccountPath);
            
            // Vérifier si Firebase est déjà initialisé
            if (FirebaseApp.getApps().isEmpty()) {
                LOG.infof("Initialisation de Firebase avec le fichier: %s", serviceAccountPath);
                
                InputStream serviceAccount = getClass()
                    .getClassLoader()
                    .getResourceAsStream(serviceAccountPath);
                
                if (serviceAccount == null) {
                    String errorMsg = String.format(
                        "Fichier de service Firebase non trouvé: %s. " +
                        "Assurez-vous que le fichier est dans src/main/resources/",
                        serviceAccountPath
                    );
                    LOG.errorf("❌ %s", errorMsg);
                    throw new RuntimeException(errorMsg);
                }
                
                LOG.infof("✅ Fichier service account trouvé, lecture des credentials...");
                
                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
                
                LOG.infof("✅ Credentials chargés, initialisation de FirebaseApp...");
                
                FirebaseApp.initializeApp(options);
                
                String projectId = options.getProjectId();
                if (projectId == null || projectId.isEmpty()) {
                    LOG.warn("⚠️ Project ID Firebase non trouvé dans les options. Vérifiez votre fichier de service account.");
                } else {
                    LOG.infof("✅ Firebase initialisé avec succès - Project ID: %s", projectId);
                }
                
                // Vérifier que l'initialisation a bien fonctionné
                if (FirebaseApp.getApps().isEmpty()) {
                    throw new RuntimeException("FirebaseApp.initializeApp() a été appelé mais aucune app n'est disponible");
                }
                
                LOG.infof("✅ Vérification: %d instance(s) Firebase disponible(s)", FirebaseApp.getApps().size());
            } else {
                FirebaseApp app = FirebaseApp.getInstance();
                String projectId = app.getOptions().getProjectId();
                LOG.infof("ℹ️ Firebase déjà initialisé - Project ID: %s", projectId);
                LOG.infof("ℹ️ Nombre d'instances Firebase: %d", FirebaseApp.getApps().size());
            }
        } catch (Exception e) {
            LOG.errorf(e, "❌ Erreur lors de l'initialisation de Firebase: %s", e.getMessage());
            LOG.errorf("   Type d'erreur: %s", e.getClass().getName());
            if (e.getCause() != null) {
                LOG.errorf("   Cause: %s", e.getCause().getMessage());
            }
            throw new RuntimeException("Impossible d'initialiser Firebase: " + e.getMessage(), e);
        }
    }
    
    /**
     * Vérifie si Firebase est initialisé et tente de l'initialiser si nécessaire
     * @return true si Firebase est initialisé, false sinon
     */
    public boolean ensureInitialized() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                LOG.warn("⚠️ Firebase n'est pas initialisé, tentative de réinitialisation...");
                init();
            }
            return !FirebaseApp.getApps().isEmpty();
        } catch (Exception e) {
            LOG.errorf(e, "❌ Impossible d'initialiser Firebase: %s", e.getMessage());
            return false;
        }
    }
    
    /**
     * Envoie une notification à un token FCM spécifique
     */
    public String sendNotificationToToken(
            String token,
            String title,
            String body,
            java.util.Map<String, String> data) throws FirebaseMessagingException {
        
        Notification notification = Notification.builder()
            .setTitle(title)
            .setBody(body)
            .build();
        
        Message.Builder messageBuilder = Message.builder()
            .setToken(token)
            .setNotification(notification);
        
        // Ajouter les données personnalisées
        if (data != null && !data.isEmpty()) {
            messageBuilder.putAllData(data);
        }
        
        Message message = messageBuilder.build();
        
        try {
            String response = FirebaseMessaging.getInstance().send(message);
            LOG.infof("✅ Notification envoyée avec succès: %s", response);
            return response;
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "❌ Erreur lors de l'envoi de la notification");
            throw e;
        }
    }
    
    /**
     * Envoie une notification à un topic
     */
    public String sendNotificationToTopic(
            String topic,
            String title,
            String body,
            java.util.Map<String, String> data) throws FirebaseMessagingException {
        
        Notification notification = Notification.builder()
            .setTitle(title)
            .setBody(body)
            .build();
        
        Message.Builder messageBuilder = Message.builder()
            .setTopic(topic)
            .setNotification(notification);
        
        if (data != null && !data.isEmpty()) {
            messageBuilder.putAllData(data);
        }
        
        Message message = messageBuilder.build();
        
        try {
            String response = FirebaseMessaging.getInstance().send(message);
            LOG.infof("✅ Notification envoyée au topic %s: %s", topic, response);
            return response;
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "❌ Erreur lors de l'envoi de la notification au topic %s", topic);
            throw e;
        }
    }
    
    /**
     * Envoie une notification à plusieurs tokens (multicast)
     */
    public BatchResponse sendNotificationToMultipleTokens(
            java.util.List<String> tokens,
            String title,
            String body,
            java.util.Map<String, String> data) throws FirebaseMessagingException {
        
        // Vérifier que Firebase est initialisé
        if (FirebaseApp.getApps().isEmpty()) {
            throw new IllegalStateException("Firebase n'est pas initialisé. Vérifiez la configuration Firebase.");
        }
        
        // Vérifier que la liste de tokens n'est pas vide
        if (tokens == null || tokens.isEmpty()) {
            throw new IllegalArgumentException("La liste de tokens ne peut pas être vide");
        }
        
        // Filtrer les tokens invalides
        List<String> validTokens = tokens.stream()
            .filter(token -> token != null && !token.trim().isEmpty())
            .toList();
        
        if (validTokens.isEmpty()) {
            throw new IllegalArgumentException("Aucun token valide fourni");
        }
        
        if (validTokens.size() != tokens.size()) {
            LOG.warnf("⚠️ %d token(s) invalide(s) filtré(s) sur %d", 
                tokens.size() - validTokens.size(), tokens.size());
        }
        
        LOG.infof("📤 Envoi de notification à %d token(s): titre='%s', body='%s'", 
            validTokens.size(), title, body);
        
        Notification notification = Notification.builder()
            .setTitle(title)
            .setBody(body)
            .build();
        
        MulticastMessage.Builder messageBuilder = MulticastMessage.builder()
            .addAllTokens(validTokens)
            .setNotification(notification);
        
        if (data != null && !data.isEmpty()) {
            messageBuilder.putAllData(data);
            LOG.infof("   Données supplémentaires: %s", data);
        }
        
        MulticastMessage message = messageBuilder.build();
        
        try {
            FirebaseMessaging messaging = FirebaseMessaging.getInstance();
            BatchResponse response = messaging.sendMulticast(message);
            
            LOG.infof("✅ Notifications envoyées: %d succès, %d échecs", 
                response.getSuccessCount(), response.getFailureCount());
            
            // Logger les détails des échecs
            if (response.getFailureCount() > 0) {
                LOG.warnf("⚠️ %d notification(s) ont échoué:", response.getFailureCount());
                response.getResponses().forEach((sendResponse) -> {
                    if (!sendResponse.isSuccessful()) {
                        FirebaseMessagingException exception = sendResponse.getException();
                        LOG.errorf("   Échec: %s - %s", 
                            exception.getErrorCode(), 
                            exception.getMessage());
                    }
                });
            }
            
            return response;
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "❌ Erreur Firebase lors de l'envoi des notifications: %s (code: %s)", 
                e.getMessage(), e.getErrorCode());
            
            // Vérifier si c'est une erreur de configuration
            if (e.getMessage() != null && 
                (e.getMessage().contains("404") || 
                 e.getMessage().contains("/batch") ||
                 e.getMessage().contains("NOT_FOUND"))) {
                LOG.error("⚠️ Erreur 404 détectée. Causes possibles:");
                LOG.error("   1. Project ID Firebase incorrect dans application.properties");
                LOG.error("   2. Fichier de service account invalide ou expiré");
                LOG.error("   3. Tokens FCM invalides ou expirés");
                LOG.error("   4. Problème de connexion avec les serveurs Firebase");
            }
            
            throw e;
        } catch (Exception e) {
            LOG.errorf(e, "❌ Erreur inattendue lors de l'envoi des notifications: %s", e.getMessage());
            throw new RuntimeException("Erreur lors de l'envoi des notifications: " + e.getMessage(), e);
        }
    }
}
```

✅ **Note** : Tous les imports nécessaires sont déjà inclus dans le code ci-dessus.

### 2. DTOs pour les requêtes

Créez des DTOs pour les requêtes :

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.Map;

public class NotificationRequest {
    
    @NotBlank(message = "Le token FCM est requis")
    public String token;
    
    @NotBlank(message = "Le titre est requis")
    public String title;
    
    @NotBlank(message = "Le corps est requis")
    public String body;
    
    public Map<String, String> data;
    
    // Constructeurs, getters, setters
    public NotificationRequest() {}
    
    public NotificationRequest(String token, String title, String body, Map<String, String> data) {
        this.token = token;
        this.title = title;
        this.body = body;
        this.data = data;
    }
}
```

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.List;
import java.util.Map;

public class MulticastNotificationRequest {
    
    @NotNull(message = "La liste des tokens est requise")
    public List<String> tokens;
    
    @NotBlank(message = "Le titre est requis")
    public String title;
    
    @NotBlank(message = "Le corps est requis")
    public String body;
    
    public Map<String, String> data;
}
```

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;

public class TopicNotificationRequest {
    
    @NotBlank(message = "Le topic est requis")
    public String topic;
    
    @NotBlank(message = "Le titre est requis")
    public String title;
    
    @NotBlank(message = "Le corps est requis")
    public String body;
    
    public Map<String, String> data;
}
```

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;

public class TokenRegistrationRequest {
    
    @NotBlank(message = "L'ID utilisateur est requis")
    public String userId;
    
    @NotBlank(message = "Le token FCM est requis")
    public String token;
    
    @NotBlank(message = "Le type d'appareil est requis")
    public String deviceType; // "android" ou "ios"
    
    @NotEmpty(message = "Au moins un matricule est requis")
    public List<String> matricules; // Liste des matricules associés au token
    
    // Constructeurs
    public TokenRegistrationRequest() {}
    
    public TokenRegistrationRequest(String userId, String token, String deviceType, List<String> matricules) {
        this.userId = userId;
        this.token = token;
        this.deviceType = deviceType;
        this.matricules = matricules;
    }
}
```

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;

public class TokenUnregistrationRequest {
    
    @NotBlank(message = "L'ID utilisateur est requis")
    public String userId;
    
    @NotBlank(message = "Le token FCM est requis")
    public String token;
    
    // Constructeurs
    public TokenUnregistrationRequest() {}
    
    public TokenUnregistrationRequest(String userId, String token) {
        this.userId = userId;
        this.token = token;
    }
}
```

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.Map;

public class MatriculeNotificationRequest {
    
    @NotBlank(message = "Le matricule est requis")
    public String matricule;
    
    @NotBlank(message = "Le titre est requis")
    public String title;
    
    @NotBlank(message = "Le corps est requis")
    public String body;
    
    public Map<String, String> data;
    
    // Constructeurs
    public MatriculeNotificationRequest() {}
    
    public MatriculeNotificationRequest(String matricule, String title, String body, Map<String, String> data) {
        this.matricule = matricule;
        this.title = title;
        this.body = body;
        this.data = data;
    }
}
```

```java
package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.List;
import java.util.Map;

public class MultipleMatriculesNotificationRequest {
    
    @NotEmpty(message = "Au moins un matricule est requis")
    public List<String> matricules;
    
    @NotBlank(message = "Le titre est requis")
    public String title;
    
    @NotBlank(message = "Le corps est requis")
    public String body;
    
    public Map<String, String> data;
    
    // Constructeurs
    public MultipleMatriculesNotificationRequest() {}
    
    public MultipleMatriculesNotificationRequest(List<String> matricules, String title, String body, Map<String, String> data) {
        this.matricules = matricules;
        this.title = title;
        this.body = body;
        this.data = data;
    }
}
```

### 3. Ressource REST

Créez la ressource REST pour gérer les notifications :

```java
package com.pouls.ecole.resource;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.pouls.ecole.dto.MatriculeNotificationRequest;
import com.pouls.ecole.dto.MultipleMatriculesNotificationRequest;
import com.pouls.ecole.dto.MulticastNotificationRequest;
import com.pouls.ecole.dto.NotificationRequest;
import com.pouls.ecole.dto.TopicNotificationRequest;
import com.pouls.ecole.service.FirebaseService;
import com.pouls.ecole.service.NotificationTokenService;
import jakarta.inject.Inject;
import jakarta.validation.Valid;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;

import java.util.List;
import java.util.Map;

@Path("/api/notifications")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class NotificationResource {
    
    private static final Logger LOG = Logger.getLogger(NotificationResource.class);
    
    @Inject
    FirebaseService firebaseService;
    
    @Inject
    NotificationTokenService tokenService;
    
    /**
     * Envoie une notification à un token spécifique
     * POST /api/notifications/send
     */
    @POST
    @Path("/send")
    public Response sendNotification(@Valid NotificationRequest request) {
        try {
            String messageId = firebaseService.sendNotificationToToken(
                request.token,
                request.title,
                request.body,
                request.data
            );
            
            return Response.ok()
                .entity(Map.of("success", true, "messageId", messageId))
                .build();
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification");
            return Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "errorCode", e.getErrorCode()
                ))
                .build();
        }
    }
    
    /**
     * Envoie une notification à un topic
     * POST /api/notifications/send-to-topic
     */
    @POST
    @Path("/send-to-topic")
    public Response sendNotificationToTopic(@Valid TopicNotificationRequest request) {
        try {
            String messageId = firebaseService.sendNotificationToTopic(
                request.topic,
                request.title,
                request.body,
                request.data
            );
            
            return Response.ok()
                .entity(Map.of("success", true, "messageId", messageId))
                .build();
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification au topic");
            return Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "errorCode", e.getErrorCode()
                ))
                .build();
        }
    }
    
    /**
     * Envoie une notification à plusieurs tokens
     * POST /api/notifications/send-multicast
     */
    @POST
    @Path("/send-multicast")
    public Response sendMulticastNotification(@Valid MulticastNotificationRequest request) {
        try {
            BatchResponse response = firebaseService.sendNotificationToMultipleTokens(
                request.tokens,
                request.title,
                request.body,
                request.data
            );
            
            return Response.ok()
                .entity(Map.of(
                    "success", true,
                    "successCount", response.getSuccessCount(),
                    "failureCount", response.getFailureCount()
                ))
                .build();
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi des notifications multicast");
            return Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "errorCode", e.getErrorCode()
                ))
                .build();
        }
    }
    
    /**
     * Envoie une notification à tous les tokens associés à un matricule
     * POST /api/notifications/send-by-matricule
     */
    @POST
    @Path("/send-by-matricule")
    public Response sendNotificationByMatricule(@Valid MatriculeNotificationRequest request) {
        try {
            LOG.infof("Tentative d'envoi de notification pour le matricule: %s", request.matricule);
            
            // Vérifier que Firebase est initialisé et tenter de l'initialiser si nécessaire
            if (FirebaseApp.getApps().isEmpty()) {
                LOG.warn("⚠️ Firebase n'est pas initialisé, tentative de réinitialisation...");
                boolean initialized = firebaseService.ensureInitialized();
                
                if (!initialized) {
                    LOG.error("❌ Impossible d'initialiser Firebase");
                    return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                        .entity(Map.of(
                            "success", false,
                            "error", "Firebase n'est pas initialisé. Vérifiez la configuration Firebase.",
                            "errorCode", "FIREBASE_NOT_INITIALIZED",
                            "matricule", request.matricule,
                            "suggestion", "Vérifiez que le fichier firebase-service-account.json existe dans src/main/resources/ et que firebase.service-account.path est correctement configuré dans application.properties"
                        ))
                        .build();
                }
                LOG.info("✅ Firebase réinitialisé avec succès");
            }
            
            // Récupérer tous les tokens associés au matricule
            List<String> tokens = tokenService.getTokenStringsByMatricule(request.matricule);
            
            LOG.infof("Tokens trouvés pour le matricule %s: %d", request.matricule, tokens.size());
            
            if (tokens.isEmpty()) {
                LOG.warnf("Aucun token trouvé pour le matricule: %s", request.matricule);
                return Response.status(Response.Status.NOT_FOUND)
                    .entity(Map.of(
                        "success", false,
                        "message", "Aucun token trouvé pour le matricule: " + request.matricule,
                        "errorCode", "NO_TOKENS_FOUND",
                        "matricule", request.matricule,
                        "suggestion", "Assurez-vous que des tokens ont été enregistrés avec ce matricule via POST /api/notifications/register-token"
                    ))
                    .build();
            }
            
            // Vérifier que les tokens ne sont pas vides ou invalides
            List<String> validTokens = tokens.stream()
                .filter(token -> token != null && !token.trim().isEmpty())
                .toList();
            
            if (validTokens.isEmpty()) {
                LOG.warnf("Aucun token valide trouvé pour le matricule: %s", request.matricule);
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of(
                        "success", false,
                        "error", "Tous les tokens associés à ce matricule sont invalides",
                        "errorCode", "INVALID_TOKENS",
                        "matricule", request.matricule
                    ))
                    .build();
            }
            
            LOG.infof("Envoi de la notification à %d token(s) valide(s) pour le matricule: %s", 
                validTokens.size(), request.matricule);
            
            // Envoyer la notification à tous les tokens
            BatchResponse response = firebaseService.sendNotificationToMultipleTokens(
                validTokens,
                request.title,
                request.body,
                request.data
            );
            
            LOG.infof("Notification envoyée pour le matricule %s: %d succès, %d échecs", 
                request.matricule, response.getSuccessCount(), response.getFailureCount());
            
            // Vérifier s'il y a des échecs et logger les détails
            if (response.getFailureCount() > 0) {
                LOG.warnf("Certaines notifications ont échoué pour le matricule %s", request.matricule);
                response.getResponses().forEach((sendResponse) -> {
                    if (!sendResponse.isSuccessful()) {
                        LOG.errorf("Échec d'envoi: %s - %s", 
                            sendResponse.getException().getErrorCode(),
                            sendResponse.getException().getMessage());
                    }
                });
            }
            
            return Response.ok()
                .entity(Map.of(
                    "success", true,
                    "matricule", request.matricule,
                    "tokensCount", validTokens.size(),
                    "successCount", response.getSuccessCount(),
                    "failureCount", response.getFailureCount()
                ))
                .build();
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur Firebase lors de l'envoi de la notification pour le matricule: %s", request.matricule);
            
            // Gérer spécifiquement les erreurs 404 de Firebase
            if (e.getMessage() != null && e.getMessage().contains("404") || 
                e.getMessage() != null && e.getMessage().contains("/batch")) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of(
                        "success", false,
                        "error", "Erreur de configuration Firebase ou tokens invalides. Vérifiez la configuration Firebase et que les tokens sont valides.",
                        "errorCode", "FIREBASE_CONFIG_ERROR",
                        "matricule", request.matricule,
                        "details", e.getMessage()
                    ))
                    .build();
            }
            
            return Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "errorCode", e.getErrorCode() != null ? e.getErrorCode() : "UNKNOWN",
                    "matricule", request.matricule
                ))
                .build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur inattendue lors de l'envoi de la notification pour le matricule: %s", request.matricule);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "matricule", request.matricule
                ))
                .build();
        }
    }
    
    /**
     * Envoie une notification à tous les tokens associés à plusieurs matricules
     * POST /api/notifications/send-by-multiple-matricules
     */
    @POST
    @Path("/send-by-multiple-matricules")
    public Response sendNotificationToMultipleMatricules(@Valid MultipleMatriculesNotificationRequest request) {
        try {
            LOG.infof("Tentative d'envoi de notification pour %d matricule(s): %s", 
                request.matricules.size(), request.matricules);
            
            // Vérifier que Firebase est initialisé et tenter de l'initialiser si nécessaire
            if (FirebaseApp.getApps().isEmpty()) {
                LOG.warn("⚠️ Firebase n'est pas initialisé, tentative de réinitialisation...");
                boolean initialized = firebaseService.ensureInitialized();
                
                if (!initialized) {
                    LOG.error("❌ Impossible d'initialiser Firebase");
                    return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                        .entity(Map.of(
                            "success", false,
                            "error", "Firebase n'est pas initialisé. Vérifiez la configuration Firebase.",
                            "errorCode", "FIREBASE_NOT_INITIALIZED",
                            "matricules", request.matricules,
                            "suggestion", "Vérifiez que le fichier firebase-service-account.json existe dans src/main/resources/ et que firebase.service-account.path est correctement configuré dans application.properties"
                        ))
                        .build();
                }
                LOG.info("✅ Firebase réinitialisé avec succès");
            }
            
            // Récupérer tous les tokens associés à ces matricules (sans doublons)
            List<String> tokens = tokenService.getTokenStringsByMatricules(request.matricules);
            
            LOG.infof("Tokens trouvés pour %d matricule(s): %d token(s)", 
                request.matricules.size(), tokens.size());
            
            if (tokens.isEmpty()) {
                LOG.warnf("Aucun token trouvé pour les matricules: %s", request.matricules);
                return Response.status(Response.Status.NOT_FOUND)
                    .entity(Map.of(
                        "success", false,
                        "message", "Aucun token trouvé pour les matricules fournis",
                        "errorCode", "NO_TOKENS_FOUND",
                        "matricules", request.matricules,
                        "suggestion", "Assurez-vous que des tokens ont été enregistrés avec ces matricules via POST /api/notifications/register-token"
                    ))
                    .build();
            }
            
            // Vérifier que les tokens ne sont pas vides ou invalides
            List<String> validTokens = tokens.stream()
                .filter(token -> token != null && !token.trim().isEmpty())
                .distinct() // Éliminer les doublons
                .toList();
            
            if (validTokens.isEmpty()) {
                LOG.warnf("Aucun token valide trouvé pour les matricules: %s", request.matricules);
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of(
                        "success", false,
                        "error", "Tous les tokens associés à ces matricules sont invalides",
                        "errorCode", "INVALID_TOKENS",
                        "matricules", request.matricules
                    ))
                    .build();
            }
            
            LOG.infof("Envoi de la notification à %d token(s) unique(s) pour %d matricule(s)", 
                validTokens.size(), request.matricules.size());
            
            // Envoyer la notification à tous les tokens
            BatchResponse response = firebaseService.sendNotificationToMultipleTokens(
                validTokens,
                request.title,
                request.body,
                request.data
            );
            
            LOG.infof("Notification envoyée pour %d matricule(s): %d succès, %d échecs", 
                request.matricules.size(), response.getSuccessCount(), response.getFailureCount());
            
            // Vérifier s'il y a des échecs et logger les détails
            if (response.getFailureCount() > 0) {
                LOG.warnf("Certaines notifications ont échoué pour les matricules: %s", request.matricules);
                response.getResponses().forEach((sendResponse) -> {
                    if (!sendResponse.isSuccessful()) {
                        LOG.errorf("Échec d'envoi: %s - %s", 
                            sendResponse.getException().getErrorCode(),
                            sendResponse.getException().getMessage());
                    }
                });
            }
            
            return Response.ok()
                .entity(Map.of(
                    "success", true,
                    "matricules", request.matricules,
                    "matriculesCount", request.matricules.size(),
                    "tokensCount", validTokens.size(),
                    "successCount", response.getSuccessCount(),
                    "failureCount", response.getFailureCount()
                ))
                .build();
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur Firebase lors de l'envoi de la notification pour les matricules: %s", request.matricules);
            
            // Gérer spécifiquement les erreurs 404 de Firebase
            if (e.getMessage() != null && e.getMessage().contains("404") || 
                e.getMessage() != null && e.getMessage().contains("/batch")) {
                return Response.status(Response.Status.BAD_REQUEST)
                    .entity(Map.of(
                        "success", false,
                        "error", "Erreur de configuration Firebase ou tokens invalides. Vérifiez la configuration Firebase et que les tokens sont valides.",
                        "errorCode", "FIREBASE_CONFIG_ERROR",
                        "matricules", request.matricules,
                        "details", e.getMessage()
                    ))
                    .build();
            }
            
            return Response.status(Response.Status.BAD_REQUEST)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "errorCode", e.getErrorCode() != null ? e.getErrorCode() : "UNKNOWN",
                    "matricules", request.matricules
                ))
                .build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur inattendue lors de l'envoi de la notification pour les matricules: %s", request.matricules);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of(
                    "success", false,
                    "error", e.getMessage(),
                    "matricules", request.matricules
                ))
                .build();
        }
    }
}
```

### 4. Endpoints pour gérer les tokens

Créez une ressource pour enregistrer/supprimer les tokens :

```java
package com.pouls.ecole.resource;

import com.pouls.ecole.dto.TokenRegistrationRequest;
import com.pouls.ecole.entity.NotificationToken;
import com.pouls.ecole.service.NotificationTokenService;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;

import java.util.List;
import java.util.Map;

@Path("/api/notifications")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class NotificationTokenResource {
    
    private static final Logger LOG = Logger.getLogger(NotificationTokenResource.class);
    
    @Inject
    NotificationTokenService tokenService;
    
    /**
     * Enregistre un token FCM pour un utilisateur
     * POST /api/notifications/register-token
     */
    @POST
    @Path("/register-token")
    @Transactional
    public Response registerToken(@Valid TokenRegistrationRequest request) {
        try {
            tokenService.registerToken(
                request.userId,
                request.token,
                request.deviceType,
                request.matricules
            );
            
            return Response.ok()
                .entity(Map.of(
                    "success", true, 
                    "message", "Token enregistré avec succès",
                    "matriculesCount", request.matricules.size()
                ))
                .build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de l'enregistrement du token");
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of("success", false, "error", e.getMessage()))
                .build();
        }
    }
    
    /**
     * Supprime un token FCM
     * DELETE /api/notifications/unregister-token?userId={userId}&token={token}
     */
    @DELETE
    @Path("/unregister-token")
    @Transactional
    public Response unregisterToken(
            @QueryParam("userId") @NotBlank(message = "L'ID utilisateur est requis") String userId,
            @QueryParam("token") @NotBlank(message = "Le token FCM est requis") String token) {
        try {
            tokenService.unregisterToken(userId, token);
            
            return Response.ok()
                .entity(Map.of("success", true, "message", "Token supprimé avec succès"))
                .build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de la suppression du token");
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of("success", false, "error", e.getMessage()))
                .build();
        }
    }
    
    /**
     * Récupère tous les tokens d'un utilisateur
     * GET /api/notifications/tokens/{userId}
     */
    @GET
    @Path("/tokens/{userId}")
    public Response getUserTokens(@PathParam("userId") String userId) {
        try {
            List<NotificationToken> tokens = tokenService.getUserTokens(userId);
            return Response.ok(tokens).build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de la récupération des tokens");
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of("success", false, "error", e.getMessage()))
                .build();
        }
    }
    
    /**
     * Récupère tous les tokens associés à un matricule
     * GET /api/notifications/tokens-by-matricule/{matricule}
     */
    @GET
    @Path("/tokens-by-matricule/{matricule}")
    public Response getTokensByMatricule(@PathParam("matricule") String matricule) {
        try {
            List<String> tokens = tokenService.getTokenStringsByMatricule(matricule);
            return Response.ok(Map.of(
                "matricule", matricule,
                "tokens", tokens,
                "count", tokens.size()
            )).build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de la récupération des tokens par matricule");
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of("success", false, "error", e.getMessage()))
                .build();
        }
    }
    
    /**
     * Récupère tous les matricules associés à un token
     * GET /api/notifications/matricules-by-token?token={token}
     */
    @GET
    @Path("/matricules-by-token")
    public Response getMatriculesByToken(@QueryParam("token") @NotBlank String token) {
        try {
            List<String> matricules = tokenService.getMatriculesByToken(token);
            return Response.ok(Map.of(
                "token", token,
                "matricules", matricules,
                "count", matricules.size()
            )).build();
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de la récupération des matricules par token");
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                .entity(Map.of("success", false, "error", e.getMessage()))
                .build();
        }
    }
}
```

### 5. Service pour gérer les tokens en base de données

```java
package com.pouls.ecole.service;

import com.pouls.ecole.entity.NotificationToken;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.transaction.Transactional;
import org.jboss.logging.Logger;

import java.util.List;

@ApplicationScoped
public class NotificationTokenService {
    
    private static final Logger LOG = Logger.getLogger(NotificationTokenService.class);
    
    @Inject
    EntityManager entityManager;
    
    @Transactional
    public void registerToken(String userId, String token, String deviceType, List<String> matricules) {
        // Vérifier si le token existe déjà
        NotificationToken existingToken = entityManager
            .createQuery("SELECT t FROM NotificationToken t WHERE t.token = :token", NotificationToken.class)
            .setParameter("token", token)
            .getResultStream()
            .findFirst()
            .orElse(null);
        
        if (existingToken != null) {
            // Mettre à jour le token existant
            existingToken.setUserId(userId);
            existingToken.setDeviceType(deviceType);
            existingToken.setUpdatedAt(java.time.LocalDateTime.now());
            
            // Supprimer les anciens matricules
            existingToken.getMatricules().clear();
            
            // Ajouter les nouveaux matricules
            for (String matricule : matricules) {
                existingToken.addMatricule(matricule);
            }
            
            entityManager.merge(existingToken);
            LOG.infof("Token mis à jour pour l'utilisateur: %s avec %d matricules", userId, matricules.size());
        } else {
            // Créer un nouveau token
            NotificationToken newToken = new NotificationToken();
            newToken.setUserId(userId);
            newToken.setToken(token);
            newToken.setDeviceType(deviceType);
            newToken.setCreatedAt(java.time.LocalDateTime.now());
            newToken.setUpdatedAt(java.time.LocalDateTime.now());
            
            // Ajouter les matricules
            for (String matricule : matricules) {
                newToken.addMatricule(matricule);
            }
            
            entityManager.persist(newToken);
            LOG.infof("Nouveau token enregistré pour l'utilisateur: %s avec %d matricules", userId, matricules.size());
        }
    }
    
    /**
     * Ajoute des matricules à un token existant
     */
    @Transactional
    public void addMatriculesToToken(String token, List<String> matricules) {
        NotificationToken tokenEntity = entityManager
            .createQuery("SELECT t FROM NotificationToken t WHERE t.token = :token", NotificationToken.class)
            .setParameter("token", token)
            .getResultStream()
            .findFirst()
            .orElse(null);
        
        if (tokenEntity != null) {
            for (String matricule : matricules) {
                // Vérifier si le matricule n'existe pas déjà
                boolean exists = tokenEntity.getMatricules().stream()
                    .anyMatch(tm -> tm.getMatricule().equals(matricule));
                
                if (!exists) {
                    tokenEntity.addMatricule(matricule);
                }
            }
            tokenEntity.setUpdatedAt(java.time.LocalDateTime.now());
            entityManager.merge(tokenEntity);
            LOG.infof("Matricules ajoutés au token: %d", matricules.size());
        }
    }
    
    /**
     * Supprime des matricules d'un token
     */
    @Transactional
    public void removeMatriculesFromToken(String token, List<String> matricules) {
        NotificationToken tokenEntity = entityManager
            .createQuery("SELECT t FROM NotificationToken t WHERE t.token = :token", NotificationToken.class)
            .setParameter("token", token)
            .getResultStream()
            .findFirst()
            .orElse(null);
        
        if (tokenEntity != null) {
            for (String matricule : matricules) {
                tokenEntity.removeMatricule(matricule);
            }
            tokenEntity.setUpdatedAt(java.time.LocalDateTime.now());
            entityManager.merge(tokenEntity);
            LOG.infof("Matricules supprimés du token: %d", matricules.size());
        }
    }
    
    @Transactional
    public void unregisterToken(String userId, String token) {
        NotificationToken tokenEntity = entityManager
            .createQuery("SELECT t FROM NotificationToken t WHERE t.userId = :userId AND t.token = :token", NotificationToken.class)
            .setParameter("userId", userId)
            .setParameter("token", token)
            .getResultStream()
            .findFirst()
            .orElse(null);
        
        if (tokenEntity != null) {
            entityManager.remove(tokenEntity);
            LOG.infof("Token supprimé pour l'utilisateur: %s", userId);
        }
    }
    
    public List<NotificationToken> getUserTokens(String userId) {
        return entityManager
            .createQuery("SELECT t FROM NotificationToken t WHERE t.userId = :userId", NotificationToken.class)
            .setParameter("userId", userId)
            .getResultList();
    }
    
    public List<String> getUserTokenStrings(String userId) {
        return getUserTokens(userId).stream()
            .map(NotificationToken::getToken)
            .toList();
    }
    
    /**
     * Récupère tous les tokens associés à un matricule
     */
    public List<NotificationToken> getTokensByMatricule(String matricule) {
        return entityManager
            .createQuery(
                "SELECT DISTINCT t FROM NotificationToken t " +
                "JOIN t.matricules tm " +
                "WHERE tm.matricule = :matricule",
                NotificationToken.class
            )
            .setParameter("matricule", matricule)
            .getResultList();
    }
    
    /**
     * Récupère tous les tokens (chaînes) associés à un matricule
     */
    public List<String> getTokenStringsByMatricule(String matricule) {
        return getTokensByMatricule(matricule).stream()
            .map(NotificationToken::getToken)
            .toList();
    }
    
    /**
     * Récupère tous les tokens associés à plusieurs matricules
     */
    public List<NotificationToken> getTokensByMatricules(List<String> matricules) {
        return entityManager
            .createQuery(
                "SELECT DISTINCT t FROM NotificationToken t " +
                "JOIN t.matricules tm " +
                "WHERE tm.matricule IN :matricules",
                NotificationToken.class
            )
            .setParameter("matricules", matricules)
            .getResultList();
    }
    
    /**
     * Récupère tous les tokens (chaînes) associés à plusieurs matricules
     */
    public List<String> getTokenStringsByMatricules(List<String> matricules) {
        return getTokensByMatricules(matricules).stream()
            .map(NotificationToken::getToken)
            .distinct()
            .toList();
    }
    
    /**
     * Récupère tous les matricules associés à un token
     */
    public List<String> getMatriculesByToken(String token) {
        NotificationToken tokenEntity = entityManager
            .createQuery("SELECT t FROM NotificationToken t WHERE t.token = :token", NotificationToken.class)
            .setParameter("token", token)
            .getResultStream()
            .findFirst()
            .orElse(null);
        
        if (tokenEntity != null) {
            return tokenEntity.getMatricules().stream()
                .map(com.pouls.ecole.entity.TokenMatricule::getMatricule)
                .toList();
        }
        return java.util.Collections.emptyList();
    }
}
```

### 6. Entity pour les tokens

```java
package com.pouls.ecole.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "notification_tokens")
public class NotificationToken {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "user_id", nullable = false)
    private String userId;
    
    @Column(name = "token", nullable = false, unique = true, length = 500)
    private String token;
    
    @Column(name = "device_type", nullable = false)
    private String deviceType; // "android" ou "ios"
    
    @OneToMany(mappedBy = "token", cascade = CascadeType.ALL, orphanRemoval = true)
    private Set<TokenMatricule> matricules = new HashSet<>();
    
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    // Getters et setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public String getToken() {
        return token;
    }
    
    public void setToken(String token) {
        this.token = token;
    }
    
    public String getDeviceType() {
        return deviceType;
    }
    
    public void setDeviceType(String deviceType) {
        this.deviceType = deviceType;
    }
    
    public Set<TokenMatricule> getMatricules() {
        return matricules;
    }
    
    public void setMatricules(Set<TokenMatricule> matricules) {
        this.matricules = matricules;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    // Méthode utilitaire pour ajouter un matricule
    public void addMatricule(String matricule) {
        TokenMatricule tokenMatricule = new TokenMatricule();
        tokenMatricule.setToken(this);
        tokenMatricule.setMatricule(matricule);
        this.matricules.add(tokenMatricule);
    }
    
    // Méthode utilitaire pour supprimer un matricule
    public void removeMatricule(String matricule) {
        this.matricules.removeIf(tm -> tm.getMatricule().equals(matricule));
    }
}
```

### 6.1. Entity pour la relation Token-Matricule

```java
package com.pouls.ecole.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "token_matricules", 
       uniqueConstraints = @UniqueConstraint(columnNames = {"token_id", "matricule"}))
public class TokenMatricule {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "token_id", nullable = false)
    private NotificationToken token;
    
    @Column(name = "matricule", nullable = false, length = 50)
    private String matricule;
    
    @Column(name = "created_at", nullable = false)
    private java.time.LocalDateTime createdAt;
    
    // Constructeurs
    public TokenMatricule() {
        this.createdAt = java.time.LocalDateTime.now();
    }
    
    // Getters et setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public NotificationToken getToken() {
        return token;
    }
    
    public void setToken(NotificationToken token) {
        this.token = token;
    }
    
    public String getMatricule() {
        return matricule;
    }
    
    public void setMatricule(String matricule) {
        this.matricule = matricule;
    }
    
    public java.time.LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(java.time.LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
```

## 🗄️ Scripts SQL pour créer les tables

### PostgreSQL

```sql
-- Table pour stocker les tokens de notification
CREATE TABLE notification_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    device_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_notification_tokens_user_id ON notification_tokens(user_id);
CREATE INDEX idx_notification_tokens_token ON notification_tokens(token);

-- Table de jointure pour associer les tokens aux matricules
CREATE TABLE token_matricules (
    id BIGSERIAL PRIMARY KEY,
    token_id BIGINT NOT NULL,
    matricule VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_token_matricule_token 
        FOREIGN KEY (token_id) 
        REFERENCES notification_tokens(id) 
        ON DELETE CASCADE,
    CONSTRAINT uk_token_matricule UNIQUE (token_id, matricule)
);

-- Index pour améliorer les performances
CREATE INDEX idx_token_matricules_token_id ON token_matricules(token_id);
CREATE INDEX idx_token_matricules_matricule ON token_matricules(matricule);

-- Trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_notification_tokens_updated_at 
    BEFORE UPDATE ON notification_tokens 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
```

### MySQL / MariaDB

```sql
-- Table pour stocker les tokens de notification
CREATE TABLE notification_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    device_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table de jointure pour associer les tokens aux matricules
CREATE TABLE token_matricules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token_id BIGINT NOT NULL,
    matricule VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_token_matricule_token 
        FOREIGN KEY (token_id) 
        REFERENCES notification_tokens(id) 
        ON DELETE CASCADE,
    CONSTRAINT uk_token_matricule UNIQUE (token_id, matricule),
    INDEX idx_token_id (token_id),
    INDEX idx_matricule (matricule)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### SQL Server

```sql
-- Table pour stocker les tokens de notification
CREATE TABLE notification_tokens (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id NVARCHAR(255) NOT NULL,
    token NVARCHAR(500) NOT NULL UNIQUE,
    device_type NVARCHAR(50) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    updated_at DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- Index pour améliorer les performances
CREATE INDEX idx_notification_tokens_user_id ON notification_tokens(user_id);
CREATE INDEX idx_notification_tokens_token ON notification_tokens(token);

-- Table de jointure pour associer les tokens aux matricules
CREATE TABLE token_matricules (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    token_id BIGINT NOT NULL,
    matricule NVARCHAR(50) NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT GETDATE(),
    CONSTRAINT fk_token_matricule_token 
        FOREIGN KEY (token_id) 
        REFERENCES notification_tokens(id) 
        ON DELETE CASCADE,
    CONSTRAINT uk_token_matricule UNIQUE (token_id, matricule)
);

-- Index pour améliorer les performances
CREATE INDEX idx_token_matricules_token_id ON token_matricules(token_id);
CREATE INDEX idx_token_matricules_matricule ON token_matricules(matricule);

-- Trigger pour mettre à jour automatiquement updated_at
CREATE TRIGGER trg_notification_tokens_updated_at
ON notification_tokens
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE notification_tokens
    SET updated_at = GETDATE()
    FROM notification_tokens t
    INNER JOIN inserted i ON t.id = i.id;
END;
```

### H2 (pour les tests)

```sql
-- Table pour stocker les tokens de notification
CREATE TABLE notification_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    token VARCHAR(500) NOT NULL UNIQUE,
    device_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Index pour améliorer les performances
CREATE INDEX idx_notification_tokens_user_id ON notification_tokens(user_id);
CREATE INDEX idx_notification_tokens_token ON notification_tokens(token);

-- Table de jointure pour associer les tokens aux matricules
CREATE TABLE token_matricules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token_id BIGINT NOT NULL,
    matricule VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_token_matricule_token 
        FOREIGN KEY (token_id) 
        REFERENCES notification_tokens(id) 
        ON DELETE CASCADE,
    CONSTRAINT uk_token_matricule UNIQUE (token_id, matricule)
);

-- Index pour améliorer les performances
CREATE INDEX idx_token_matricules_token_id ON token_matricules(token_id);
CREATE INDEX idx_token_matricules_matricule ON token_matricules(matricule);
```

### Notes importantes

1. **Contraintes d'unicité** :
   - `token` est unique dans `notification_tokens`
   - La combinaison `(token_id, matricule)` est unique dans `token_matricules`

2. **Clés étrangères** :
   - `token_matricules.token_id` référence `notification_tokens.id` avec `ON DELETE CASCADE`
   - La suppression d'un token supprime automatiquement ses associations de matricules

3. **Index** :
   - Index sur `user_id` pour les requêtes par utilisateur
   - Index sur `token` pour les recherches rapides
   - Index sur `matricule` pour les requêtes par matricule
   - Index sur `token_id` pour les jointures

4. **Timestamps** :
   - `created_at` : date de création (auto-rempli)
   - `updated_at` : date de mise à jour (auto-mis à jour avec triggers)

## 📤 Exemples d'utilisation

### Envoyer une notification lors de l'ajout d'une note

```java
@Inject
FirebaseService firebaseService;

@Inject
NotificationTokenService tokenService;

@Transactional
public void addNote(Note note) {
    // Sauvegarder la note
    noteRepository.persist(note);
    
    // Récupérer les tokens des parents de l'élève
    List<String> parentTokens = tokenService.getUserTokenStrings(note.getParentId());
    
    if (!parentTokens.isEmpty()) {
        // Préparer les données
        Map<String, String> data = new HashMap<>();
        data.put("type", "note_added");
        data.put("childId", note.getChildId());
        data.put("noteId", note.getId().toString());
        data.put("subject", note.getSubject());
        data.put("grade", note.getGrade().toString());
        
        // Envoyer la notification
        try {
            firebaseService.sendNotificationToMultipleTokens(
                parentTokens,
                "Nouvelle note",
                String.format("Une nouvelle note a été ajoutée en %s: %.2f/20", 
                    note.getSubject(), note.getGrade()),
                data
            );
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification de note");
        }
    }
}
```

### Envoyer une notification lors de l'ajout d'un message

```java
@Transactional
public void sendMessage(Message message) {
    messageRepository.persist(message);
    
    List<String> recipientTokens = tokenService.getUserTokenStrings(message.getRecipientId());
    
    if (!recipientTokens.isEmpty()) {
        Map<String, String> data = new HashMap<>();
        data.put("type", "message_received");
        data.put("messageId", message.getId().toString());
        data.put("senderId", message.getSenderId());
        
        try {
            firebaseService.sendNotificationToMultipleTokens(
                recipientTokens,
                "Nouveau message",
                message.getContent(),
                data
            );
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification de message");
        }
    }
}
```

### Envoyer une notification basée sur un matricule

```java
@Inject
FirebaseService firebaseService;

@Inject
NotificationTokenService tokenService;

/**
 * Envoie une notification à tous les tokens associés à un matricule
 */
@Transactional
public void sendNotificationByMatricule(String matricule, String title, String body, Map<String, String> data) {
    // Récupérer tous les tokens associés au matricule
    List<String> tokens = tokenService.getTokenStringsByMatricule(matricule);
    
    if (!tokens.isEmpty()) {
        try {
            firebaseService.sendNotificationToMultipleTokens(tokens, title, body, data);
            LOG.infof("Notification envoyée à %d tokens pour le matricule: %s", tokens.size(), matricule);
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification pour le matricule: %s", matricule);
        }
    } else {
        LOG.warnf("Aucun token trouvé pour le matricule: %s", matricule);
    }
}

/**
 * Exemple : Envoyer une notification lors de l'ajout d'une note basée sur le matricule de l'élève
 */
@Transactional
public void addNoteByMatricule(Note note) {
    // Sauvegarder la note
    noteRepository.persist(note);
    
    // Récupérer le matricule de l'élève depuis la note
    String matricule = note.getStudentMatricule(); // Supposons que la note a un champ matricule
    
    // Récupérer tous les tokens associés à ce matricule
    List<String> tokens = tokenService.getTokenStringsByMatricule(matricule);
    
    if (!tokens.isEmpty()) {
        // Préparer les données
        Map<String, String> data = new HashMap<>();
        data.put("type", "note_added");
        data.put("matricule", matricule);
        data.put("noteId", note.getId().toString());
        data.put("subject", note.getSubject());
        data.put("grade", note.getGrade().toString());
        
        // Envoyer la notification
        try {
            firebaseService.sendNotificationToMultipleTokens(
                tokens,
                "Nouvelle note",
                String.format("Une nouvelle note a été ajoutée en %s: %.2f/20", 
                    note.getSubject(), note.getGrade()),
                data
            );
            LOG.infof("Notification de note envoyée pour le matricule: %s", matricule);
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification de note pour le matricule: %s", matricule);
        }
    }
}

/**
 * Exemple : Envoyer une notification à plusieurs matricules en même temps
 */
@Transactional
public void sendNotificationToMultipleMatricules(
        List<String> matricules, 
        String title, 
        String body, 
        Map<String, String> data) {
    
    // Récupérer tous les tokens associés à ces matricules (sans doublons)
    List<String> tokens = tokenService.getTokenStringsByMatricules(matricules);
    
    if (!tokens.isEmpty()) {
        try {
            firebaseService.sendNotificationToMultipleTokens(tokens, title, body, data);
            LOG.infof("Notification envoyée à %d tokens pour %d matricules", tokens.size(), matricules.size());
        } catch (FirebaseMessagingException e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification pour plusieurs matricules");
        }
    }
}
```

## 📞 Comment les fonctions sont appelées dans les ressources

### 1. `sendNotificationByMatricule()` - Endpoint REST

Cette fonction est un **endpoint REST** dans la classe `NotificationResource` :

**Endpoint** : `POST /api/notifications/send-by-matricule`

**Comment elle est appelée** :
- Via une requête HTTP POST depuis un client (application mobile, Postman, etc.)
- Le client envoie un objet `MatriculeNotificationRequest` dans le corps de la requête
- La méthode `sendNotificationByMatricule()` dans `NotificationResource` reçoit la requête, récupère les tokens associés au matricule, et envoie la notification

**Exemple d'appel** :
```java
// Dans NotificationResource.java (ligne 722)
@POST
@Path("/send-by-matricule")
public Response sendNotificationByMatricule(@Valid MatriculeNotificationRequest request) {
    // 1. Récupère les tokens associés au matricule
    List<String> tokens = tokenService.getTokenStringsByMatricule(request.matricule);
    
    // 2. Envoie la notification via Firebase
    BatchResponse response = firebaseService.sendNotificationToMultipleTokens(
        validTokens, request.title, request.body, request.data
    );
    
    // 3. Retourne la réponse
    return Response.ok(...).build();
}
```

**Appel depuis un client HTTP** :
```bash
curl -X POST http://localhost:8080/api/notifications/send-by-matricule \
  -H "Content-Type: application/json" \
  -d '{
    "matricule": "20440504X",
    "title": "Nouvelle note",
    "body": "Une nouvelle note a été ajoutée",
    "data": {"type": "note_added"}
  }'
```

### 2. `sendNotificationToMultipleMatricules()` - Endpoint REST

Cette fonction est également un **endpoint REST** dans la classe `NotificationResource` :

**Endpoint** : `POST /api/notifications/send-by-multiple-matricules`

**Comment elle est appelée** :
- Via une requête HTTP POST depuis un client
- Le client envoie un objet `MultipleMatriculesNotificationRequest` contenant une liste de matricules
- La méthode `sendNotificationToMultipleMatricules()` dans `NotificationResource` récupère tous les tokens associés à ces matricules (sans doublons) et envoie la notification

**Exemple d'appel** :
```java
// Dans NotificationResource.java (ligne ~845)
@POST
@Path("/send-by-multiple-matricules")
public Response sendNotificationToMultipleMatricules(@Valid MultipleMatriculesNotificationRequest request) {
    // 1. Récupère tous les tokens associés aux matricules (sans doublons)
    List<String> tokens = tokenService.getTokenStringsByMatricules(request.matricules);
    
    // 2. Envoie la notification via Firebase
    BatchResponse response = firebaseService.sendNotificationToMultipleTokens(
        validTokens, request.title, request.body, request.data
    );
    
    // 3. Retourne la réponse
    return Response.ok(...).build();
}
```

**Appel depuis un client HTTP** :
```bash
curl -X POST http://localhost:8080/api/notifications/send-by-multiple-matricules \
  -H "Content-Type: application/json" \
  -d '{
    "matricules": ["20440504X", "20440505Y"],
    "title": "Annonce importante",
    "body": "Une annonce pour plusieurs élèves",
    "data": {"type": "announcement"}
  }'
```

### 3. Méthodes de service (exemples dans le code)

Il existe également des **méthodes de service** (exemples) qui peuvent être appelées depuis d'autres services Java :

```java
// Exemple d'utilisation dans un service métier
@Inject
NotificationTokenService tokenService;

@Inject
FirebaseService firebaseService;

// Appel depuis un service Java (pas un endpoint REST)
public void addNote(Note note) {
    // ... sauvegarder la note ...
    
    // Envoyer une notification pour un matricule
    String matricule = note.getStudentMatricule();
    List<String> tokens = tokenService.getTokenStringsByMatricule(matricule);
    if (!tokens.isEmpty()) {
        firebaseService.sendNotificationToMultipleTokens(
            tokens, "Nouvelle note", "Une note a été ajoutée", data
        );
    }
}
```

### Résumé

| Fonction | Type | Endpoint REST | Appelé depuis |
|----------|------|---------------|---------------|
| `sendNotificationByMatricule()` | Endpoint REST | `POST /api/notifications/send-by-matricule` | Client HTTP (mobile, Postman, etc.) |
| `sendNotificationToMultipleMatricules()` | Endpoint REST | `POST /api/notifications/send-by-multiple-matricules` | Client HTTP (mobile, Postman, etc.) |

## 🧪 Tests

### Exemple de requête cURL

```bash
# Envoyer une notification
curl -X POST http://localhost:8080/api/notifications/send \
  -H "Content-Type: application/json" \
  -d '{
    "token": "fcm_token_here",
    "title": "Nouvelle note",
    "body": "Une nouvelle note a été ajoutée",
    "data": {
      "type": "note_added",
      "childId": "child_id",
      "noteId": "note_id"
    }
  }'

# Envoyer une notification basée sur un matricule
# Envoyer une notification basée sur un matricule
curl -X POST http://localhost:8080/api/notifications/send-by-matricule \
  -H "Content-Type: application/json" \
  -d '{
    "matricule": "20440504X",
    "title": "Nouvelle note",
    "body": "Une nouvelle note a été ajoutée",
    "data": {
      "type": "note_added",
      "matricule": "20440504X",
      "noteId": "note_id",
      "subject": "Mathématiques",
      "grade": "15.5"
    }
  }'

# Envoyer une notification à plusieurs matricules en même temps
curl -X POST http://localhost:8080/api/notifications/send-by-multiple-matricules \
  -H "Content-Type: application/json" \
  -d '{
    "matricules": ["20440504X", "20440505Y", "20440506Z"],
    "title": "Annonce importante",
    "body": "Une annonce importante pour plusieurs élèves",
    "data": {
      "type": "announcement",
      "priority": "high"
    }
  }'

# Enregistrer un token avec des matricules
curl -X POST http://localhost:8080/api/notifications/register-token \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user_id",
    "token": "fcm_token_here",
    "deviceType": "android",
    "matricules": ["MAT001", "MAT002", "MAT003"]
  }'

# Récupérer les tokens associés à un matricule
curl -X GET http://localhost:8080/api/notifications/tokens-by-matricule/MAT001

# Récupérer les matricules associés à un token
curl -X GET "http://localhost:8080/api/notifications/matricules-by-token?token=fcm_token_here"

# Supprimer un token
curl -X DELETE "http://localhost:8080/api/notifications/unregister-token?userId=user_id&token=fcm_token_here"
```

## ⚠️ Notes importantes

1. **Sécurité** : Ne commitez jamais le fichier `firebase-service-account.json`
2. **Gestion des erreurs** : Gérez les cas où le token est invalide ou expiré
3. **Performance** : Pour envoyer à de nombreux utilisateurs, utilisez les topics ou le multicast
4. **Logs** : Loggez toutes les opérations pour le débogage
5. **Validation** : Validez toujours les tokens avant l'envoi
6. **Association Token-Matricule** : 
   - Chaque token peut être associé à plusieurs matricules
   - Lors de l'enregistrement d'un token, vous devez fournir au moins un matricule
   - Utilisez `getTokenStringsByMatricule()` pour envoyer des notifications basées sur un matricule
   - Un même token peut recevoir des notifications pour plusieurs matricules différents

## 🔍 Débogage

Activez les logs détaillés dans `application.properties` :

```properties
quarkus.log.level=INFO
quarkus.log.category."com.pouls.ecole".level=DEBUG
```

Les logs afficheront :
- L'initialisation de Firebase
- Les envois de notifications
- Les erreurs éventuelles

## 🔧 Résolution des problèmes Firebase

### Erreur : "Firebase Installations Service is unavailable"

Cette erreur peut survenir pour plusieurs raisons :

#### 1. **Sur un émulateur Android**
   - **Problème** : Les émulateurs Android peuvent ne pas avoir Google Play Services installés
   - **Solution** : Utilisez un émulateur avec Google Play Services ou testez sur un appareil physique

#### 2. **Problème de connexion internet**
   - **Vérification** : Testez la connexion dans le navigateur de l'émulateur/appareil
   - **Solution** : Vérifiez que l'appareil/émulateur a bien accès à internet

#### 3. **Configuration Firebase incomplète**
   - **Vérification** : Assurez-vous que le fichier `google-services.json` (Android) ou `GoogleService-Info.plist` (iOS) est présent et correct
   - **Emplacement Android** : `android/app/google-services.json`
   - **Emplacement iOS** : `ios/Runner/GoogleService-Info.plist`

#### 4. **Google Play Services non à jour**
   - **Solution** : Mettez à jour Google Play Services sur l'appareil/émulateur

#### 5. **Service Firebase temporairement indisponible**
   - **Solution** : Attendez quelques minutes et réessayez

### Comportement de l'application

L'application est conçue pour continuer à fonctionner même si Firebase n'est pas disponible :
- Si le token FCM n'est pas disponible, l'application continue de fonctionner
- Le token sera enregistré automatiquement dès qu'il sera disponible
- Les matricules seront associés au token lors de la prochaine initialisation réussie

