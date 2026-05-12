package com.immobilier.model;

import java.sql.Timestamp;

public class PropertyReaction {
    private int id;
    private int propertyId;
    private String visitorIdentifier;
    private String reactionType;
    private Timestamp createdAt;

    // Constructeur vide
    public PropertyReaction() {
    }

    // Constructeur avec tous les champs
    public PropertyReaction(int id, int propertyId, String visitorIdentifier, 
                            String reactionType, Timestamp createdAt) {
        this.id = id;
        this.propertyId = propertyId;
        this.visitorIdentifier = visitorIdentifier;
        this.reactionType = reactionType;
        this.createdAt = createdAt;
    }

    // Getters et Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getPropertyId() {
        return propertyId;
    }

    public void setPropertyId(int propertyId) {
        this.propertyId = propertyId;
    }

    public String getVisitorIdentifier() {
        return visitorIdentifier;
    }

    public void setVisitorIdentifier(String visitorIdentifier) {
        this.visitorIdentifier = visitorIdentifier;
    }

    public String getReactionType() {
        return reactionType;
    }

    public void setReactionType(String reactionType) {
        this.reactionType = reactionType;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "PropertyReaction{" +
                "id=" + id +
                ", propertyId=" + propertyId +
                ", visitorIdentifier='" + visitorIdentifier + '\'' +
                ", reactionType='" + reactionType + '\'' +
                '}';
    }
}