package com.pouls.ecole.util;

import com.pouls.ecole.service.FirebaseService;
import com.pouls.ecole.service.NotificationTokenService;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.jboss.logging.Logger;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Classe utilitaire pour faciliter l'envoi de notifications
 */
@ApplicationScoped
public class NotificationHelper {
    
    private static final Logger LOG = Logger.getLogger(NotificationHelper.class);
    
    @Inject
    NotificationTokenService tokenService;
    
    @Inject
    FirebaseService firebaseService;
    
    /**
     * Envoie une notification de nouvelle note
     */
    public void notifyNewNote(String parentId, String childId, String childName, 
                             String subject, Double grade) {
        List<String> tokens = tokenService.getUserTokenStrings(parentId);
        
        if (tokens.isEmpty()) {
            LOG.warnf("Aucun token trouvé pour le parent: %s", parentId);
            return;
        }
        
        Map<String, String> data = new HashMap<>();
        data.put("type", "note_added");
        data.put("childId", childId);
        data.put("childName", childName);
        data.put("subject", subject);
        data.put("grade", grade.toString());
        
        String title = "Nouvelle note";
        String body = String.format("Une nouvelle note a été ajoutée pour %s en %s: %.2f/20", 
            childName, subject, grade);
        
        try {
            firebaseService.sendNotificationToMultipleTokens(tokens, title, body, data);
            LOG.infof("Notification de nouvelle note envoyée au parent: %s", parentId);
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification de note");
        }
    }
    
    /**
     * Envoie une notification de message reçu
     */
    public void notifyNewMessage(String recipientId, String senderName, String messageContent) {
        List<String> tokens = tokenService.getUserTokenStrings(recipientId);
        
        if (tokens.isEmpty()) {
            LOG.warnf("Aucun token trouvé pour l'utilisateur: %s", recipientId);
            return;
        }
        
        Map<String, String> data = new HashMap<>();
        data.put("type", "message_received");
        data.put("senderName", senderName);
        
        String title = "Nouveau message";
        String body = String.format("Message de %s: %s", senderName, 
            messageContent.length() > 50 ? messageContent.substring(0, 50) + "..." : messageContent);
        
        try {
            firebaseService.sendNotificationToMultipleTokens(tokens, title, body, data);
            LOG.infof("Notification de message envoyée à l'utilisateur: %s", recipientId);
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification de message");
        }
    }
    
    /**
     * Envoie une notification de nouvelle facture
     */
    public void notifyNewFee(String parentId, String childId, String childName, 
                            Double amount, String description) {
        List<String> tokens = tokenService.getUserTokenStrings(parentId);
        
        if (tokens.isEmpty()) {
            LOG.warnf("Aucun token trouvé pour le parent: %s", parentId);
            return;
        }
        
        Map<String, String> data = new HashMap<>();
        data.put("type", "fee_added");
        data.put("childId", childId);
        data.put("childName", childName);
        data.put("amount", amount.toString());
        data.put("description", description);
        
        String title = "Nouvelle facture";
        String body = String.format("Une nouvelle facture a été ajoutée pour %s: %.2f FCFA - %s", 
            childName, amount, description);
        
        try {
            firebaseService.sendNotificationToMultipleTokens(tokens, title, body, data);
            LOG.infof("Notification de facture envoyée au parent: %s", parentId);
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification de facture");
        }
    }
    
    /**
     * Envoie une notification de mise à jour d'emploi du temps
     */
    public void notifyTimetableUpdate(String parentId, String childId, String childName) {
        List<String> tokens = tokenService.getUserTokenStrings(parentId);
        
        if (tokens.isEmpty()) {
            LOG.warnf("Aucun token trouvé pour le parent: %s", parentId);
            return;
        }
        
        Map<String, String> data = new HashMap<>();
        data.put("type", "timetable_updated");
        data.put("childId", childId);
        data.put("childName", childName);
        
        String title = "Emploi du temps mis à jour";
        String body = String.format("L'emploi du temps de %s a été mis à jour", childName);
        
        try {
            firebaseService.sendNotificationToMultipleTokens(tokens, title, body, data);
            LOG.infof("Notification d'emploi du temps envoyée au parent: %s", parentId);
        } catch (Exception e) {
            LOG.errorf(e, "Erreur lors de l'envoi de la notification d'emploi du temps");
        }
    }
}

