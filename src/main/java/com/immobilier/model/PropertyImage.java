package com.immobilier.model;

public class PropertyImage {
    private int id;
    private int propertyId;
    private String imageUrl;
    private boolean isPrimary;
    private int displayOrder;
    
    // Constructeur par défaut
    public PropertyImage() {}
    
    // Constructeur avec paramètres
    public PropertyImage(int propertyId, String imageUrl, boolean isPrimary, int displayOrder) {
        this.propertyId = propertyId;
        this.imageUrl = imageUrl;
        this.isPrimary = isPrimary;
        this.displayOrder = displayOrder;
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
    
    public String getImageUrl() {
        return imageUrl;
    }
    
    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }
    
    public boolean isPrimary() {
        return isPrimary;
    }
    
    public void setPrimary(boolean isPrimary) {
        this.isPrimary = isPrimary;
    }
    
    public int getDisplayOrder() {
        return displayOrder;
    }
    
    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }
    
    @Override
    public String toString() {
        return "PropertyImage{" +
                "id=" + id +
                ", propertyId=" + propertyId +
                ", imageUrl='" + imageUrl + '\'' +
                ", isPrimary=" + isPrimary +
                ", displayOrder=" + displayOrder +
                '}';
    }
}