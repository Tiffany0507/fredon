package com.immobilier.model;

import java.sql.Timestamp;

public class Comment {
    private int id;
    private int propertyId;
    private String visitorName;
    private String visitorEmail;
    private String content;
    private boolean isApproved;
    private Timestamp createdAt;

    // Constructeur vide
    public Comment() {
    }

    // Constructeur avec tous les champs
    public Comment(int id, int propertyId, String visitorName, String visitorEmail, 
                   String content, boolean isApproved, Timestamp createdAt) {
        this.id = id;
        this.propertyId = propertyId;
        this.visitorName = visitorName;
        this.visitorEmail = visitorEmail;
        this.content = content;
        this.isApproved = isApproved;
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

    public String getVisitorName() {
        return visitorName;
    }

    public void setVisitorName(String visitorName) {
        this.visitorName = visitorName;
    }

    public String getVisitorEmail() {
        return visitorEmail;
    }

    public void setVisitorEmail(String visitorEmail) {
        this.visitorEmail = visitorEmail;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public boolean isApproved() {
        return isApproved;
    }

    public void setApproved(boolean approved) {
        isApproved = approved;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Comment{" +
                "id=" + id +
                ", propertyId=" + propertyId +
                ", visitorName='" + visitorName + '\'' +
                ", content='" + content + '\'' +
                ", isApproved=" + isApproved +
                '}';
    }
}