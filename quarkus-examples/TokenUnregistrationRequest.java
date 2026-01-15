package com.pouls.ecole.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO pour la suppression d'un token FCM
 */
public class TokenUnregistrationRequest {
    
    @NotBlank(message = "L'ID utilisateur est requis")
    public String userId;
    
    @NotBlank(message = "Le token FCM est requis")
    public String token;
    
    public TokenUnregistrationRequest() {}
    
    public TokenUnregistrationRequest(String userId, String token) {
        this.userId = userId;
        this.token = token;
    }
}

