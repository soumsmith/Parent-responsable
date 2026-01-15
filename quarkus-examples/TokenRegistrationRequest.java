package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO pour l'enregistrement d'un token FCM
 */
public class TokenRegistrationRequest {
    
    @NotBlank(message = "L'ID utilisateur est requis")
    public String userId;
    
    @NotBlank(message = "Le token FCM est requis")
    public String token;
    
    @NotBlank(message = "Le type d'appareil est requis")
    public String deviceType; // "android" ou "ios"
    
    public TokenRegistrationRequest() {}
    
    public TokenRegistrationRequest(String userId, String token, String deviceType) {
        this.userId = userId;
        this.token = token;
        this.deviceType = deviceType;
    }
}

