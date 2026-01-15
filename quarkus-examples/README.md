# Exemples de code Quarkus pour les notifications

Ce dossier contient des exemples de code pour intégrer Firebase Cloud Messaging dans votre API Quarkus.

## 📁 Fichiers

- `TokenRegistrationRequest.java` - DTO pour l'enregistrement d'un token
- `TokenUnregistrationRequest.java` - DTO pour la suppression d'un token
- `NotificationHelper.java` - Classe utilitaire pour faciliter l'envoi de notifications
- `application.properties.example` - Exemple de configuration
- `pom.xml.example` - Exemple de configuration Maven

## 🚀 Utilisation rapide

### 1. Copier les fichiers dans votre projet

Copiez les fichiers Java dans les packages appropriés de votre projet Quarkus :
- DTOs → `src/main/java/com/pouls/ecole/dto/`
- Helpers → `src/main/java/com/pouls/ecole/util/`

### 2. Configurer Firebase

1. Téléchargez le fichier `firebase-service-account.json` depuis Firebase Console
2. Placez-le dans `src/main/resources/`
3. Configurez `application.properties` selon `application.properties.example`

### 3. Utiliser NotificationHelper

```java
@Inject
NotificationHelper notificationHelper;

// Lors de l'ajout d'une note
public void addNote(Note note) {
    noteRepository.persist(note);
    
    // Envoyer la notification
    notificationHelper.notifyNewNote(
        note.getParentId(),
        note.getChildId(),
        note.getChildName(),
        note.getSubject(),
        note.getGrade()
    );
}
```

## 📚 Documentation complète

Consultez `QUARKUS_NOTIFICATIONS.md` pour la documentation complète avec tous les détails d'implémentation.

